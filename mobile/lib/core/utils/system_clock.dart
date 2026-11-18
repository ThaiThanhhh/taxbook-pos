import 'package:dt13_pos/core/ports/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_clock.g.dart';

/// Đồng hồ thật của máy. Là adapter nên được gọi `DateTime.now()`;
/// domain chỉ nhận [Clock] qua provider.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Override trong test bằng `clockProvider.overrideWithValue(...)`.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();
