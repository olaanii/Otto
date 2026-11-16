import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/clerk_user_session.dart';

abstract class IClerkAuthDataSource {
  Future<ClerkUserSession> verifyTicket(String ticket);
  Future<ClerkUserSession?> validateSession(String sessionToken);
  Future<void> signOut(String sessionToken);
}

class ClerkAuthDataSource implements IClerkAuthDataSource {
  final ApiClient apiClient;

  ClerkAuthDataSource(this.apiClient);

  @override
  Future<ClerkUserSession> verifyTicket(String ticket) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.clerkVerify,
      data: {'ticket': ticket},
    );

    final data = response.data?['session'] as Map<String, dynamic>? ??
        response.data ??
        {};
    return ClerkUserSession.fromJson(data);
  }

  @override
  Future<ClerkUserSession?> validateSession(String sessionToken) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.clerkSession,
        data: {'session_token': sessionToken},
      );
      final data = response.data?['session'] as Map<String, dynamic>? ??
          response.data ??
          {};
      return ClerkUserSession.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut(String sessionToken) async {
    await apiClient.post<void>(
      ApiEndpoints.clerkSignOut,
      data: {'session_token': sessionToken},
    );
  }
}
