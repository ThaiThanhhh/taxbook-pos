/// Nguồn thời gian tiêm từ ngoài; domain không gọi DateTime.now().
///
/// Implementation phải trả thời điểm UTC. Không phụ thuộc Flutter.
abstract interface class Clock {
  DateTime nowUtc();
}
