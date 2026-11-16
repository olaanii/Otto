import '../models/clerk_user_session.dart';
import '../repositories/i_auth_repository.dart';

class SignInWithClerkUseCase {
  final IAuthRepository authRepository;

  SignInWithClerkUseCase(this.authRepository);

  Future<ClerkUserSession> call(String ticket) async {
    if (ticket.trim().isEmpty) {
      throw ArgumentError('Clerk authentication ticket cannot be empty');
    }
    return authRepository.signInWithTicket(ticket);
  }
}
