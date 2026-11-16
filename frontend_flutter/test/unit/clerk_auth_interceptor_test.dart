import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/core/network/clerk_auth_interceptor.dart';
import 'package:otto_frontend/core/storage/secure_storage_service.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> _data = {};

  FakeSecureStorageService() : super(storage: const FlutterSecureStorage());

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _data[key];
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clearSession() async {
    _data.remove(SecureStorageService.keyClerkToken);
    _data.remove(SecureStorageService.keyClerkJwt);
    _data.remove(SecureStorageService.keyUserId);
  }
}

void main() {
  group('ClerkAuthInterceptor Tests', () {
    late FakeSecureStorageService fakeStorage;
    late Dio dio;
    late ClerkAuthInterceptor interceptor;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
      dio = Dio();
      interceptor = ClerkAuthInterceptor(
        secureStorage: fakeStorage,
        dio: dio,
      );
    });

    test('onRequest injects Authorization Bearer header when JWT is present', () async {
      await fakeStorage.write(SecureStorageService.keyClerkJwt, 'test_jwt_token_123');

      final options = RequestOptions(path: '/git/workspace');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer test_jwt_token_123');
    });

    test('onRequest does not inject Authorization header when no JWT exists', () async {
      final options = RequestOptions(path: '/git/workspace');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });
}
