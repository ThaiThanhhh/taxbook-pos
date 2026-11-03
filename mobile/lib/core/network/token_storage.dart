/// Nơi lưu access token.
///
/// TODO(gia-bao): thay [InMemoryTokenStorage] bằng flutter_secure_storage
/// (Keychain/Keystore) khi làm luồng đăng nhập thật.
abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> clear();
}

class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> saveAccessToken(String token) async => _accessToken = token;

  @override
  Future<void> clear() async => _accessToken = null;
}
