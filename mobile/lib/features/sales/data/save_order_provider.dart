import 'package:dt13_pos/core/constants/device_prefix.dart';
import 'package:dt13_pos/core/db/app_database_provider.dart';
import 'package:dt13_pos/core/db/drift_order_write_dao.dart';
import 'package:dt13_pos/core/utils/system_clock.dart';
import 'package:dt13_pos/core/utils/uuid_v7_id_generator.dart';
import 'package:dt13_pos/features/sales/domain/save_order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'save_order_provider.g.dart';

/// Một [SaveOrder] cho cả app (keepAlive), để chốt chặn bấm đôi nằm trên
/// cùng một đối tượng dù màn bán dựng lại.
///
/// Test widget override provider này bằng một [SaveOrder] trên DB in-memory.
@Riverpod(keepAlive: true)
SaveOrder saveOrder(Ref ref) {
  final clock = ref.watch(clockProvider);
  return SaveOrder(
    dao: DriftOrderWriteDao(ref.watch(appDatabaseProvider)),
    clock: clock,
    ids: UuidV7IdGenerator(clock),
    devicePrefix: kDevicePrefix,
  );
}
