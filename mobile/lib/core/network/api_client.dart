import 'package:dio/dio.dart';
import 'package:dt13_pos/core/constants/app_constants.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/auth_interceptor.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:flutter/foundation.dart';

/// Lớp mỏng bọc [Dio]. Repository của từng feature chỉ phụ thuộc vào
/// [ApiClient], không tự tạo Dio — để baseUrl, timeout, auth, log thống nhất.
class ApiClient {
  ApiClient({required AppEnv env, required TokenStorage tokenStorage, Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: env.apiBaseUrl,
              connectTimeout: AppConstants.connectTimeout,
              receiveTimeout: AppConstants.receiveTimeout,
              sendTimeout: AppConstants.sendTimeout,
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          ) {
    this.dio.interceptors.add(AuthInterceptor(tokenStorage));

    // Log chỉ bật ở debug build VÀ khi env cho phép. Không log header
    // để tránh in Bearer token ra console.
    if (kDebugMode && env.enableHttpLog) {
      this.dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  final Dio dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => dio.post<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response<T>> put<T>(String path, {Object? data, Options? options}) =>
      dio.put<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Options? options,
  }) => dio.delete<T>(path, data: data, options: options);
}
