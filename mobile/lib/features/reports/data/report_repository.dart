import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/features/reports/domain/report_models.dart';
import 'package:intl/intl.dart';

abstract interface class ReportRepository {
  Future<DailyProfit> fetchDailyProfit(DateTime date);

  Future<List<TopProduct>> fetchTopProducts({
    required DateTime from,
    required DateTime to,
  });
}

class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._apiClient);

  final ApiClient _apiClient;
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  @override
  Future<DailyProfit> fetchDailyProfit(DateTime date) async {
    final response = await _apiClient.get<Object?>(
      '/reports/daily-profit',
      queryParameters: {'date': _apiDate.format(date)},
    );
    return DailyProfit.fromJson(_asJsonObject(response.data));
  }

  @override
  Future<List<TopProduct>> fetchTopProducts({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _apiClient.get<Object?>(
      '/reports/top-products',
      queryParameters: {
        'from': _apiDate.format(from),
        'to': _apiDate.format(to),
      },
    );
    final data = _asJsonObject(response.data);
    final items = data['items'];
    if (items is! List<Object?>) {
      throw const FormatException('Danh sách sản phẩm báo cáo không hợp lệ.');
    }
    return items
        .map((item) => TopProduct.fromJson(_asJsonObject(item)))
        .toList(growable: false);
  }

  Map<String, Object?> _asJsonObject(Object? value) {
    if (value is Map<String, Object?>) return value;
    throw const FormatException('Dữ liệu báo cáo không hợp lệ.');
  }
}
