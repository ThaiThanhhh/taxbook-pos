import 'package:dio/dio.dart';
import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';
import 'package:intl/intl.dart';

enum LedgerErrorKind { forbidden, unauthenticated, offline, other }

class LedgerException implements Exception {
  const LedgerException(this.message, {this.kind = LedgerErrorKind.other});

  final String message;
  final LedgerErrorKind kind;

  @override
  String toString() => message;
}

class LedgerPage {
  const LedgerPage({required this.items, required this.hasMore});

  final List<LedgerEntry> items;
  final bool hasMore;
}

class LedgerRepository {
  LedgerRepository(this._api);

  final ApiClient _api;
  static const int pageSize = 50;
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  Future<LedgerPage> getLedgerPage({
    String? book,
    DateTime? from,
    DateTime? to,
    int limit = pageSize,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (book != null && book.isNotEmpty) queryParams['book'] = book;
    if (from != null) queryParams['from'] = _apiDate.format(from);
    if (to != null) queryParams['to'] = _apiDate.format(to);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/ledger',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data == null || !data.containsKey('items')) {
        throw const LedgerException(
          'Phản hồi thiếu trường bắt buộc',
          kind: LedgerErrorKind.other,
        );
      }
      final rawItems = data['items'] as List<dynamic>;
      final items = rawItems
          .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final nextCursor = data['next_cursor'];

      return LedgerPage(items: items, hasMore: nextCursor != null);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const LedgerException(
          'Cần kết nối mạng để xem sổ thu chi.',
          kind: LedgerErrorKind.offline,
        );
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 403) {
        throw const LedgerException(
          'Chỉ chủ hộ hoặc kế toán xem được sổ.',
          kind: LedgerErrorKind.forbidden,
        );
      }
      if (statusCode == 401) {
        throw const LedgerException(
          'Phiên làm việc đã hết hạn.',
          kind: LedgerErrorKind.unauthenticated,
        );
      }
      throw LedgerException(
        'Lỗi máy chủ ($statusCode)',
        kind: LedgerErrorKind.other,
      );
    } catch (e) {
      if (e is LedgerException) rethrow;
      throw LedgerException(
        'Lỗi không xác định: $e',
        kind: LedgerErrorKind.other,
      );
    }
  }

  Future<String> createOcrExpense(LedgerEntry entry) async {
    final category = entry.category;
    if (category == null || category.isEmpty) {
      throw const LedgerException(
        'Danh mục chi phí là bắt buộc.',
        kind: LedgerErrorKind.other,
      );
    }

    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/expenses',
        data: {
          'date': entry.entryDate,
          'amount_vnd': entry.amountVnd,
          'category': category,
          'source': 'OCR',
        },
      );
      final expenseId = response.data?['id'];
      if (expenseId is! String || expenseId.isEmpty) {
        throw const LedgerException(
          'Phản hồi tạo chi phí thiếu mã chi phí.',
          kind: LedgerErrorKind.other,
        );
      }
      return expenseId;
    } on DioException catch (e) {
      throw _toLedgerException(e);
    }
  }

  Future<void> confirmExpense(String expenseId) async {
    try {
      await _api.post<void>('/expenses/$expenseId/confirm');
    } on DioException catch (e) {
      throw _toLedgerException(e);
    }
  }

  LedgerException _toLedgerException(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return const LedgerException(
        'Cần kết nối mạng để ghi sổ chi phí.',
        kind: LedgerErrorKind.offline,
      );
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 403) {
      return const LedgerException(
        'Chỉ chủ hộ hoặc kế toán mới được ghi sổ chi phí.',
        kind: LedgerErrorKind.forbidden,
      );
    }
    if (statusCode == 401) {
      return const LedgerException(
        'Phiên làm việc đã hết hạn.',
        kind: LedgerErrorKind.unauthenticated,
      );
    }
    return LedgerException(
      'Không thể ghi sổ chi phí (lỗi máy chủ $statusCode).',
      kind: LedgerErrorKind.other,
    );
  }
}
