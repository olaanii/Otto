import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage_service.dart';
import 'clerk_auth_interceptor.dart';

/// Primary HTTP client communicating with the Otto Go daemon.
class ApiClient {
  late final Dio dio;
  final SecureStorageService secureStorage;

  ApiClient({
    required this.secureStorage,
    Dio? customDio,
    String? baseUrl,
  }) {
    dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    dio.interceptors.add(
      ClerkAuthInterceptor(
        secureStorage: secureStorage,
        dio: dio,
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = error.response?.data?['message']?.toString() ??
        error.message ??
        'Unknown network error';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException('Daemon connection timeout or unreachable: $message');
      case DioExceptionType.badResponse:
        if (statusCode == 401 || statusCode == 403) {
          return ClerkAuthException(message, statusCode: statusCode);
        }
        if (statusCode == 409) {
          final conflicts = (error.response?.data?['conflicting_files'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
          return GitOperationException(message, conflictingFiles: conflicts);
        }
        return ServerException(message, statusCode: statusCode, responseData: error.response?.data);
      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled');
      case DioExceptionType.badCertificate:
        return const NetworkException('SSL Certificate validation failure');
      case DioExceptionType.unknown:
        return ServerException('Unexpected communication failure: $message');
    }
  }
}
