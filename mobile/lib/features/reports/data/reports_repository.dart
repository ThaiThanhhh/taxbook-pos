import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/features/reports/domain/daily_profit.dart';
import 'package:dt13_pos/features/reports/domain/top_product.dart';
import 'package:intl/intl.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ApiClient _api;

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  Future<DailyProfit> getDailyProfit(DateTime date) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/reports/daily-profit',
      queryParameters: {'date': _apiDate.format(date)},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Máy chủ trả về dữ liệu rỗng');
    }
    return DailyProfit.fromJson(data);
  }

  /// Hợp đồng: from/to bắt buộc, limit 1..50 (mặc định 10),
  /// phản hồi dạng `{ "items": [...] }`.
  Future<List<TopProduct>> getTopProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/reports/top-products',
      queryParameters: {
        'from': _apiDate.format(from),
        'to': _apiDate.format(to),
        'limit': limit,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Máy chủ trả về dữ liệu rỗng');
    }
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
