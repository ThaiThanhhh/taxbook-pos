import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/features/reports/domain/daily_profit.dart';
import 'package:intl/intl.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ApiClient _api;

  Future<DailyProfit> getDailyProfit(DateTime date) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/reports/daily-profit',
      queryParameters: {'date': DateFormat('yyyy-MM-dd').format(date)},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Máy chủ trả về dữ liệu rỗng');
    }
    return DailyProfit.fromJson(data);
  }
}
