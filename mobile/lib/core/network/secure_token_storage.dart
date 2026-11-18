import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access token lưu qua plugin native, không cache RAM hay log giá trị.
final class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage({
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: false),
    ),
  });

  static const String accessTokenKey = 'dt13_pos.access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: accessTokenKey);

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: accessTokenKey, value: token);

  /// Chỉ xóa access token của app, không deleteAll hay đụng dữ liệu bán hàng.
  @override
  Future<void> clear() => _storage.delete(key: accessTokenKey);
}
