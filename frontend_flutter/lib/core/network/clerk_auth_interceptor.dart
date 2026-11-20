import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor that attaches the Clerk session JWT to outgoing HTTP requests
/// and handles token renewal on HTTP 401 Unauthorized responses with concurrency locking
/// and offline/404 resilience.
class ClerkAuthInterceptor extends Interceptor {
  final SecureStorageService secureStorage;
  final Dio dio;

  // Refresh lock to prevent concurrent 401 refresh storms
  Completer<String?>? _refreshCompleter;

  ClerkAuthInterceptor({
    required this.secureStorage,
    required this.dio,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers['X-Skip-Auth'] == 'true') {
      return handler.next(options);
    }
    try {
      if (!options.headers.containsKey('Authorization')) {
        final token = await secureStorage.read(SecureStorageService.keyClerkJwt);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {
      // Proceed without token if secure storage is unavailable
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Avoid re-authenticating auth endpoints or requests explicitly marked with X-Skip-Auth
    if (err.requestOptions.headers['X-Skip-Auth'] == 'true' ||
        err.requestOptions.path.contains(ApiEndpoints.antigravityConnect) ||
        err.requestOptions.path.contains(ApiEndpoints.antigravityStatus)) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      final sessionToken = await secureStorage.read(SecureStorageService.keyClerkToken);
      if (sessionToken != null && sessionToken.isNotEmpty) {
        final currentHeader = err.requestOptions.headers['Authorization'] as String?;
        final storedJwt = await secureStorage.read(SecureStorageService.keyClerkJwt);

        // If the token was already refreshed by a concurrent request, retry immediately
        if (storedJwt != null && storedJwt.isNotEmpty && currentHeader != 'Bearer $storedJwt') {
          final reqOptions = err.requestOptions;
          reqOptions.headers['Authorization'] = 'Bearer $storedJwt';
          try {
            final retryResponse = await dio.fetch<dynamic>(reqOptions);
            return handler.resolve(retryResponse);
          } catch (retryErr) {
            if (retryErr is DioException) {
              return handler.next(retryErr);
            }
            return handler.reject(
              DioException(requestOptions: reqOptions, error: retryErr),
            );
          }
        }

        String? newJwt;

        // If a refresh is already in-flight, await the lock rather than storming the endpoint
        if (_refreshCompleter != null) {
          try {
            newJwt = await _refreshCompleter!.future;
          } catch (_) {
            newJwt = null;
          }
        } else {
          // Acquire refresh lock
          final completer = Completer<String?>();
          _refreshCompleter = completer;

          try {
            final refreshResponse = await dio.get<Map<String, dynamic>>(
              ApiEndpoints.antigravityStatus,
              options: Options(headers: {'X-Skip-Auth': 'true'}),
            );

            final jwt = refreshResponse.data?['user'] != null ? sessionToken : null;
            if (jwt != null && jwt.isNotEmpty) {
              await secureStorage.write(SecureStorageService.keyClerkJwt, jwt);
              completer.complete(jwt);
              newJwt = jwt;
            } else {
              completer.complete(null);
            }
          } on DioException catch (refreshErr) {
            final status = refreshErr.response?.statusCode;
            final isOffline = refreshErr.type == DioExceptionType.connectionTimeout ||
                refreshErr.type == DioExceptionType.sendTimeout ||
                refreshErr.type == DioExceptionType.receiveTimeout ||
                refreshErr.type == DioExceptionType.connectionError;

            // Only clear the session if the refresh endpoint explicitly rejected credentials (401 or 403).
            // Do NOT clear if 404 (endpoint not found / unmounted daemon route) or offline.
            if (status != 404 && !isOffline && (status == 401 || status == 403)) {
              await secureStorage.clearSession();
            }
            completer.complete(null);
          } catch (_) {
            completer.complete(null);
          } finally {
            _refreshCompleter = null;
          }
        }

        if (newJwt != null && newJwt.isNotEmpty) {
          // Retry original request with refreshed JWT
          final reqOptions = err.requestOptions;
          reqOptions.headers['Authorization'] = 'Bearer $newJwt';

          try {
            final retryResponse = await dio.fetch<dynamic>(reqOptions);
            return handler.resolve(retryResponse);
          } catch (retryErr) {
            if (retryErr is DioException) {
              return handler.next(retryErr);
            }
            return handler.reject(
              DioException(requestOptions: reqOptions, error: retryErr),
            );
          }
        }
      }
    }

    return handler.next(err);
  }
}
