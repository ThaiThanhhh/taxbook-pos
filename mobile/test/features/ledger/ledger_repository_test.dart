import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:dt13_pos/features/ledger/data/ledger_repository.dart';
import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Handler = ResponseBody Function(RequestOptions options);

/// Adapter giả: không gọi mạng, trả đúng thứ ta cấu hình.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final _Handler _handler;
  final List<RequestOptions> requests = [];
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

const _env = AppEnv(
  flavor: Flavor.dev,
  apiBaseUrl: 'http://localhost',
  enableHttpLog: false,
);

ResponseBody _json(Object body, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

(LedgerRepository, _FakeAdapter) _build(_Handler handler) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..httpClientAdapter = adapter;
  final api = ApiClient(
    env: _env,
    tokenStorage: InMemoryTokenStorage(),
    dio: dio,
  );
  return (LedgerRepository(api), adapter);
}

void main() {
  const entryJson = {
    'id': 'e1',
    'book': 'REVENUE',
    'entry_date': '2026-11-05',
    'type': 'REVENUE',
    'amount_vnd': 90000,
    'ref_type': 'SALE',
    'ref_id': 's1',
  };

  test('gửi đúng đường dẫn và tham số lọc', () async {
    final (repo, adapter) = _build(
      (_) => _json({
        'items': [entryJson],
        'next_cursor': null,
      }),
    );

    await repo.getLedgerPage(
      book: 'REVENUE',
      from: DateTime(2026, 11, 5),
      to: DateTime(2026, 11, 5),
    );

    final request = adapter.lastRequest!;
    expect(request.path, '/ledger');
    expect(request.queryParameters, containsPair('book', 'REVENUE'));
    expect(request.queryParameters, containsPair('from', '2026-11-05'));
    expect(request.queryParameters, containsPair('to', '2026-11-05'));
    expect(
      request.queryParameters,
      containsPair('limit', LedgerRepository.pageSize),
    );
  });

  test('đọc được danh sách và next_cursor', () async {
    final (repo, _) = _build(
      (_) => _json({
        'items': [entryJson],
        'next_cursor': 'abc',
      }),
    );

    final page = await repo.getLedgerPage();

    expect(page.items, hasLength(1));
    expect(page.items.first.amountVnd, 90000);
    expect(page.hasMore, isTrue);
  });

  test('next_cursor null nghĩa là hết dữ liệu', () async {
    final (repo, _) = _build(
      (_) => _json({'items': <Object>[], 'next_cursor': null}),
    );

    final page = await repo.getLedgerPage();

    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
  });

  test('403 đổi thành lỗi không có quyền', () async {
    final (repo, _) = _build(
      (_) => _json({
        'error': {'code': 'FORBIDDEN', 'message': 'x', 'trace_id': 't'},
      }, status: 403),
    );

    await expectLater(
      repo.getLedgerPage(),
      throwsA(
        isA<LedgerException>().having(
          (e) => e.kind,
          'kind',
          LedgerErrorKind.forbidden,
        ),
      ),
    );
  });

  test('401 đổi thành lỗi hết phiên', () async {
    final (repo, _) = _build(
      (_) => _json({
        'error': {'code': 'UNAUTHENTICATED', 'message': 'x', 'trace_id': 't'},
      }, status: 401),
    );

    await expectLater(
      repo.getLedgerPage(),
      throwsA(
        isA<LedgerException>().having(
          (e) => e.kind,
          'kind',
          LedgerErrorKind.unauthenticated,
        ),
      ),
    );
  });

  test('mất kết nối đổi thành lỗi offline', () async {
    final (repo, _) = _build(
      (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );

    await expectLater(
      repo.getLedgerPage(),
      throwsA(
        isA<LedgerException>().having(
          (e) => e.kind,
          'kind',
          LedgerErrorKind.offline,
        ),
      ),
    );
  });

  test('lỗi 500 không bị gọi nhầm là mất mạng', () async {
    final (repo, _) = _build((_) => _json({'error': 'boom'}, status: 500));

    await expectLater(
      repo.getLedgerPage(),
      throwsA(
        isA<LedgerException>().having(
          (e) => e.kind,
          'kind',
          LedgerErrorKind.other,
        ),
      ),
    );
  });

  test('phản hồi thiếu trường bắt buộc thành lỗi có nghĩa', () async {
    final (repo, _) = _build(
      (_) => _json({
        'items': [
          {'id': 'e1'},
        ],
      }),
    );

    await expectLater(
      repo.getLedgerPage(),
      throwsA(
        isA<LedgerException>().having(
          (e) => e.kind,
          'kind',
          LedgerErrorKind.other,
        ),
      ),
    );
  });

  test('tạo chi phí OCR rồi xác nhận để ghi sổ', () async {
    final (repo, adapter) = _build(
      (options) => options.path == '/expenses'
          ? _json({'id': 'expense-1'}, status: 201)
          : _json({'id': 'expense-1', 'confirmed': true}),
    );
    const entry = LedgerEntry(
      id: 'ocr-entry',
      book: 'EXPENSE',
      entryDate: '2026-11-05',
      type: 'EXPENSE',
      amountVnd: 150000,
      refType: 'EXPENSE',
      category: 'Văn phòng phẩm',
    );

    final expenseId = await repo.createOcrExpense(entry);
    await repo.confirmExpense(expenseId);

    expect(expenseId, 'expense-1');
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests[0].path, '/expenses');
    expect(adapter.requests[0].data, {
      'date': '2026-11-05',
      'amount_vnd': 150000,
      'category': 'Văn phòng phẩm',
      'source': 'OCR',
    });
    expect(adapter.requests[1].path, '/expenses/expense-1/confirm');
  });
}
