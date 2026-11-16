import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor that attaches the Clerk session JWT to outgoing HTTP requests
/// and handles token renewal on HTTP 401 Unauthorized responses.
class ClerkAuthInterceptor extends Interceptor {
  final SecureStorageService secureStorage;
  final Dio dio;

  ClerkAuthInterceptor({
    required this.secureStorage,
    required this.dio,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await secureStorage.read(SecureStorageService.keyClerkJwt);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Proceed without token if secure storage is unavailable
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Check if we have a refreshable Clerk session token
      final sessionToken = await secureStorage.read(SecureStorageService.keyClerkToken);
      if (sessionToken != null && sessionToken.isNotEmpty) {
        try {
          // Attempt token refresh with the local Go daemon /auth/session endpoint
          final refreshResponse = await dio.post<Map<String, dynamic>>(
            '/auth/session',
            data: {'session_token': sessionToken},
            options: Options(headers: {'X-Skip-Auth': 'true'}),
          );

          final newJwt = refreshResponse.data?['jwt'] as String?;
          if (newJwt != null && newJwt.isNotEmpty) {
            await secureStorage.write(SecureStorageService.keyClerkJwt, newJwt);

            // Retry original request with refreshed JWT
            final reqOptions = err.requestOptions;
            reqOptions.headers['Authorization'] = 'Bearer $newJwt';

            final retryResponse = await dio.fetch<dynamic>(reqOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Session expired or refresh failed; clear stale tokens
          await secureStorage.clearSession();
        }
      }
    }

    handler.next(err);
  }
}
