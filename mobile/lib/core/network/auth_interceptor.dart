import 'package:dio/dio.dart';

import 'package:dt13_pos/core/network/token_storage.dart';

/// Gắn `Authorization: Bearer <token>` cho mọi request (khớp `bearerAuth`
/// trong api/openapi.yaml). Request không cần token (vd. /auth/login) đặt
/// `Options(extra: {AuthInterceptor.skipAuthKey: true})`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  static const String skipAuthKey = 'skipAuth';

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
