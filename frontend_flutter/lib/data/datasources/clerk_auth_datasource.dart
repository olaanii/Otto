import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/clerk_user_session.dart';

abstract class IClerkAuthDataSource {
  Future<ClerkUserSession> verifyTicket(String ticket);
  Future<ClerkUserSession?> validateSession(String sessionToken);
  Future<void> signOut(String sessionToken);
}

/// Auth datasource wired to the Otto backend routes:
///   POST /api/antigravity/connect  → sign-in with Google/email+name
///   GET  /api/antigravity/status   → validate existing session
///   (sign-out is local-only; backend is stateless for auth)
class ClerkAuthDataSource implements IClerkAuthDataSource {
  final ApiClient apiClient;

  ClerkAuthDataSource(this.apiClient);

  @override
  Future<ClerkUserSession> verifyTicket(String ticket) async {
    // ticket format expected: "email|name|provider"
    final parts = ticket.split('|');
    final email = parts.isNotEmpty ? parts[0].trim() : '';
    final name = parts.length > 1 && parts[1].trim().isNotEmpty ? parts[1].trim() : null;
    final provider = parts.length > 2 && parts[2].trim().isNotEmpty ? parts[2].trim() : 'google';

    if (email.isEmpty) {
      throw const FormatException('A valid email address is required to connect.');
    }

    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.antigravityConnect,
      data: {
        'email': email,
        if (name != null) 'name': name,
        'authProvider': provider,
      },
    );

    final data = response.data ?? {};
    return ClerkUserSession.fromJson(_sessionFromConnectResponse(data));
  }

  @override
  Future<ClerkUserSession?> validateSession(String sessionToken) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.antigravityStatus,
      );
      final data = response.data ?? {};
      if (data['ok'] != true || data['connected'] != true || data['user'] == null) {
        return null;
      }
      return ClerkUserSession.fromJson(_sessionFromStatusResponse(data));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut(String sessionToken) async {
    try {
      await apiClient.post<void>(
        ApiEndpoints.antigravitySignout,
      );
    } catch (_) {}
  }

  Map<String, dynamic> _sessionFromConnectResponse(Map<String, dynamic> d) {
    final ag = d['antigravity'] as Map<String, dynamic>? ?? d;
    final user = ag['user'] as Map<String, dynamic>? ?? (d['user'] as Map<String, dynamic>? ?? {});
    final email = user['email'] as String? ?? '';
    final name = user['name'] as String? ?? (email.isNotEmpty ? email.split('@')[0] : 'Developer');
    final convId = ag['conversationId'] as String? ?? 'otto-session';
    return {
      'sessionToken': convId,
      'jwt': convId,
      'userId': email.isNotEmpty ? email : 'otto-user',
      'email': email,
      'fullName': name,
      'avatarUrl': user['avatarUrl'],
      'expiresAt': null, // stateless — never expires
    };
  }

  Map<String, dynamic> _sessionFromStatusResponse(Map<String, dynamic> d) {
    final user = d['user'] as Map<String, dynamic>? ?? {};
    final email = user['email'] as String? ?? '';
    final name = user['name'] as String? ?? (email.isNotEmpty ? email.split('@')[0] : 'Developer');
    return {
      'sessionToken': 'otto-session',
      'jwt': 'otto-session',
      'userId': email.isNotEmpty ? email : 'otto-user',
      'email': email,
      'fullName': name,
      'avatarUrl': user['avatarUrl'],
      'expiresAt': null,
    };
  }
}
