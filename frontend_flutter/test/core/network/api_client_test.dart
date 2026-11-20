import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/core/errors/exceptions.dart';
import 'package:otto_frontend/core/network/api_client.dart';
import 'package:otto_frontend/core/storage/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  test('ApiClient extracts server error field from badResponse', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {'ok': false, 'error': 'Directory does not exist: /fake/path'},
            ),
          ),
        );
      },
    ));

    final client = ApiClient(
      secureStorage: SecureStorageService(storage: const FlutterSecureStorage()),
      customDio: dio,
    );

    try {
      await client.post<dynamic>('/test');
      fail('Expected ServerException');
    } on ServerException catch (e) {
      expect(e.message, 'Directory does not exist: /fake/path');
      expect(e.statusCode, 400);
    }
  });

  test('ApiClient formats clean fallback for verbose Dio validateStatus errors', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            message: 'This exception was thrown because the response has a status code of 400 and RequestOptions.validateStatus was configured to throw...',
            response: Response(
              requestOptions: options,
              statusCode: 400,
              statusMessage: 'Bad Request',
              data: null,
            ),
          ),
        );
      },
    ));

    final client = ApiClient(
      secureStorage: SecureStorageService(storage: const FlutterSecureStorage()),
      customDio: dio,
    );

    try {
      await client.post<dynamic>('/test-verbose');
      fail('Expected ServerException');
    } on ServerException catch (e) {
      expect(e.message, contains('HTTP 400'));
      expect(e.message, isNot(contains('RequestOptions.validateStatus')));
    }
  });
}
