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
}
