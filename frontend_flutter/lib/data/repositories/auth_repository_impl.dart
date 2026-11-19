import '../../core/errors/exceptions.dart';
import '../../core/errors/failure.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/models/clerk_user_session.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/clerk_auth_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IClerkAuthDataSource authDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.authDataSource,
    required this.secureStorage,
  });

  @override
  Future<ClerkUserSession> signInWithTicket(String ticket) async {
    try {
      final session = await authDataSource.verifyTicket(ticket);
      try {
        await secureStorage.write(SecureStorageService.keyClerkToken, session.sessionToken);
        await secureStorage.write(SecureStorageService.keyClerkJwt, session.jwt);
        await secureStorage.write(SecureStorageService.keyUserId, session.userId);
      } catch (_) {}
      return session;
    } on ClerkAuthException catch (e) {
      throw AuthFailure(e.message, statusCode: e.statusCode, cause: e);
    } catch (e) {
      throw AuthFailure('Clerk sign-in failed: $e', cause: e);
    }
  }

  @override
  Future<ClerkUserSession?> getCurrentSession() async {
    try {
      String? token;
      try {
        token = await secureStorage.read(SecureStorageService.keyClerkToken);
      } catch (_) {
        token = null;
      }
      final session = await authDataSource.validateSession(token ?? '');
      if (session == null) {
        if (token != null) {
          try {
            await secureStorage.clearSession();
          } catch (_) {}
        }
        return null;
      }
      if (token == null || token.isEmpty) {
        try {
          await secureStorage.write(SecureStorageService.keyClerkToken, session.sessionToken);
          await secureStorage.write(SecureStorageService.keyClerkJwt, session.jwt);
          await secureStorage.write(SecureStorageService.keyUserId, session.userId);
        } catch (_) {}
      }
      return session;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final token = await secureStorage.read(SecureStorageService.keyClerkToken);
      if (token != null && token.isNotEmpty) {
        await authDataSource.signOut(token);
      }
    } finally {
      await secureStorage.clearSession();
    }
  }

  @override
  Future<String> refreshJwt() async {
    final token = await secureStorage.read(SecureStorageService.keyClerkToken);
    if (token == null) throw const AuthFailure('No active session token found');

    final session = await authDataSource.validateSession(token);
    if (session == null) throw const AuthFailure('Session validation failed during refresh');

    await secureStorage.write(SecureStorageService.keyClerkJwt, session.jwt);
    return session.jwt;
  }
}
