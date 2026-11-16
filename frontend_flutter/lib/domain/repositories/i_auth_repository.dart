import '../models/clerk_user_session.dart';

/// Contract for Clerk authentication and session lifecycle management.
abstract class IAuthRepository {
  /// Sign in with Clerk ticket or session token.
  Future<ClerkUserSession> signInWithTicket(String ticket);

  /// Verify and retrieve active session.
  Future<ClerkUserSession?> getCurrentSession();

  /// Sign out and purge local credentials.
  Future<void> signOut();

  /// Refresh Clerk JWT token.
  Future<String> refreshJwt();
}
