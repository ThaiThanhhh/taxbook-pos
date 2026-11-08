/// Nơi lưu access token. Implementation production dùng kho khóa hệ điều hành.
abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> clear();
}
