import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/core/network/secure_token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('f04_provider_uses_secure_storage', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(tokenStorageProvider), isA<SecureTokenStorage>());
  });

  test('f04_storage_roundtrip_across_instances', () async {
    const first = SecureTokenStorage();
    expect(await first.readAccessToken(), isNull);
    await first.saveAccessToken('dev-token');

    const recreated = SecureTokenStorage();
    expect(await recreated.readAccessToken(), 'dev-token');
    await recreated.clear();
    expect(await first.readAccessToken(), isNull);
  });

  test('f04_storage_clear_only_access_token', () async {
    const native = FlutterSecureStorage();
    await native.write(key: 'unrelated-key', value: 'keep');
    const storage = SecureTokenStorage(storage: native);
    await storage.saveAccessToken('dev-token');
    expect(
      await native.read(key: SecureTokenStorage.accessTokenKey),
      'dev-token',
    );

    await storage.clear();
    expect(await storage.readAccessToken(), isNull);
    expect(await native.read(key: 'unrelated-key'), 'keep');
  });
}
