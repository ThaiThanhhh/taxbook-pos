import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_providers.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => InMemoryTokenStorage();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final client = ApiClient(
    env: ref.watch(appEnvProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
  ref.onDispose(client.dio.close);
  return client;
}
