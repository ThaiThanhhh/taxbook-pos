import 'package:dt13_pos/core/ports/clock.dart';
import 'package:dt13_pos/core/ports/id_generator.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

/// UUID v7 (package `uuid` 4.6.0). Phần thời gian 48 bit lấy từ [Clock]
/// thay vì đồng hồ máy, phần ngẫu nhiên dùng CryptoRNG mặc định của
/// package (Random.secure).
final class UuidV7IdGenerator implements IdGenerator {
  const UuidV7IdGenerator(this._clock);

  static const Uuid _uuid = Uuid();

  final Clock _clock;

  @override
  String newId() =>
      _uuid.v7(config: V7Options(_clock.nowUtc().millisecondsSinceEpoch, null));
}
