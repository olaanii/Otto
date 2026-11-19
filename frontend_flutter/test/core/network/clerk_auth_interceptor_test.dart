import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/core/network/clerk_auth_interceptor.dart';
import 'package:otto_frontend/core/storage/secure_storage_service.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> data = {};
  bool sessionCleared = false;

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return data[key];
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }

  @override
  Future<void> clearSession() async {
    sessionCleared = true;
    data.remove(SecureStorageService.keyClerkToken);
    data.remove(SecureStorageService.keyClerkJwt);
    data.remove(SecureStorageService.keyUserId);
  }
}

class FakeErrorInterceptorHandler extends ErrorInterceptorHandler {
  DioException? errorPassed;
  Response<dynamic>? resolvedResponse;

  @override
  void next(DioException err) {
    errorPassed = err;
  }

  @override
  void resolve(Response<dynamic> response) {
    resolvedResponse = response;
  }

  @override
  void reject(DioException err, [bool silent = false]) {
    errorPassed = err;
  }
}

class FakeRequestInterceptorHandler extends RequestInterceptorHandler {
  RequestOptions? optionsPassed;

  @override
  void next(RequestOptions options) {
    optionsPassed = options;
  }
}

void main() {
  group('ClerkAuthInterceptor Resilience & Refresh Lock', () {
    late FakeSecureStorageService storage;
    late Dio dio;
    late ClerkAuthInterceptor interceptor;

    setUp(() {
      storage = FakeSecureStorageService();
      dio = Dio();
      interceptor = ClerkAuthInterceptor(secureStorage: storage, dio: dio);
    });

    test('does not destroy session on 404 response from /auth/session', () async {
      storage.data[SecureStorageService.keyClerkToken] = 'valid_refresh_token';
      storage.data[SecureStorageService.keyClerkJwt] = 'expired_jwt';

      // Configure dio adapter to return 404 on /auth/session
      dio.httpClientAdapter = HttpClientAdapter();
      // Use an interceptor to simulate 404 from /auth/session
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/auth/session')) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  statusMessage: 'Not Found',
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          } else {
            handler.next(options);
          }
        },
      ));

      final handler = FakeErrorInterceptorHandler();
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/git/push-stack'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/git/push-stack'),
          statusCode: 401,
        ),
      );

      await interceptor.onError(err, handler);

      expect(storage.sessionCleared, false);
      expect(storage.data[SecureStorageService.keyClerkToken], 'valid_refresh_token');
      expect(handler.errorPassed, isNotNull);
    });

    test('does not destroy session on connection timeout / offline error', () async {
      storage.data[SecureStorageService.keyClerkToken] = 'valid_refresh_token';

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/auth/session')) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
                message: 'Connection timed out',
              ),
            );
          } else {
            handler.next(options);
          }
        },
      ));

      final handler = FakeErrorInterceptorHandler();
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/git/status'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/git/status'),
          statusCode: 401,
        ),
      );

      await interceptor.onError(err, handler);

      expect(storage.sessionCleared, false);
      expect(storage.data[SecureStorageService.keyClerkToken], 'valid_refresh_token');
    });

    test('clears session when refresh endpoint explicitly rejects with 401 Unauthorized', () async {
      storage.data[SecureStorageService.keyClerkToken] = 'revoked_token';

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/auth/session')) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  statusMessage: 'Session Expired',
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          } else {
            handler.next(options);
          }
        },
      ));

      final handler = FakeErrorInterceptorHandler();
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/git/status'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/git/status'),
          statusCode: 401,
        ),
      );

      await interceptor.onError(err, handler);

      expect(storage.sessionCleared, true);
    });

    test('onRequest attaches Bearer JWT when available', () async {
      storage.data[SecureStorageService.keyClerkJwt] = 'valid_jwt_token';

      final options = RequestOptions(path: '/api/git/analyze');
      final handler = FakeRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer valid_jwt_token');
    });

    test('onRequest skips attaching token when X-Skip-Auth header is present', () async {
      storage.data[SecureStorageService.keyClerkJwt] = 'valid_jwt_token';

      final options = RequestOptions(
        path: '/auth/session',
        headers: {'X-Skip-Auth': 'true'},
      );
      final handler = FakeRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], isNull);
    });

    test('clears session on 403 Forbidden credential rejection', () async {
      storage.data[SecureStorageService.keyClerkToken] = 'forbidden_token';

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/auth/session')) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 403,
                  statusMessage: 'Forbidden',
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          } else {
            handler.next(options);
          }
        },
      ));

      final handler = FakeErrorInterceptorHandler();
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/git/analyze'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/git/analyze'),
          statusCode: 401,
        ),
      );

      await interceptor.onError(err, handler);

      expect(storage.sessionCleared, true);
    });
  });
}
