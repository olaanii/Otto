import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/datasources/clerk_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/clerk_user_session.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/sign_in_with_clerk_usecase.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: storage);
});

final clerkAuthDataSourceProvider = Provider<IClerkAuthDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return ClerkAuthDataSource(client);
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final ds = ref.watch(clerkAuthDataSourceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(authDataSource: ds, secureStorage: storage);
});

final signInWithClerkUseCaseProvider = Provider<SignInWithClerkUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return SignInWithClerkUseCase(repo);
});

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final ClerkUserSession? session;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null && !session!.isExpired;

  AuthState copyWith({
    AuthStatus? status,
    ClerkUserSession? session,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;
  final SignInWithClerkUseCase _signInUseCase;

  AuthNotifier({
    required IAuthRepository authRepository,
    required SignInWithClerkUseCase signInUseCase,
  })  : _authRepository = authRepository,
        _signInUseCase = signInUseCase,
        super(const AuthState()) {
    checkActiveSession();
  }

  Future<void> checkActiveSession() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final session = await _authRepository.getCurrentSession();
      if (session != null && !session.isExpired) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> signInWithTicket(String ticket) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final session = await _signInUseCase(ticket);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final signIn = ref.watch(signInWithClerkUseCaseProvider);
  return AuthNotifier(authRepository: repo, signInUseCase: signIn);
});
