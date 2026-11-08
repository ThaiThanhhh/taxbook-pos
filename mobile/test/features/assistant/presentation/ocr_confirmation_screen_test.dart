import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:dt13_pos/features/assistant/domain/ocr_invoice_result.dart';
import 'package:dt13_pos/features/assistant/presentation/ocr_confirmation_screen.dart';
import 'package:dt13_pos/features/ledger/data/ledger_providers.dart';
import 'package:dt13_pos/features/ledger/data/ledger_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExpenseApiAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = options.path == '/expenses'
        ? {'id': 'expense-ocr-1'}
        : {'id': 'expense-ocr-1', 'confirmed': true};
    return ResponseBody.fromString(
      jsonEncode(body),
      options.path == '/expenses' ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('hiển thị form OCR và xác nhận chi phí qua repository', (
    tester,
  ) async {
    const env = AppEnv(
      flavor: Flavor.dev,
      apiBaseUrl: 'http://localhost',
      enableHttpLog: false,
    );
    final adapter = _ExpenseApiAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final repository = LedgerRepository(
      ApiClient(env: env, tokenStorage: InMemoryTokenStorage(), dio: dio),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ledgerRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: OcrConfirmationScreen(
            initialData: const OcrInvoiceResult(
              filename: 'invoice.png',
              taxCode: '0123456789',
              invoiceDate: '05/11/2026',
              totalAmount: 150000,
              needUserConfirmation: true,
            ),
            imageBytes: Uint8List(0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đối soát hóa đơn'), findsOneWidget);
    expect(
      find.text('Vui lòng kiểm tra lại thông tin AI đã nhận diện.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).at(2), '250.000');
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<String>),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Văn phòng phẩm').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xác nhận & Ghi sổ chi phí'));
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests[0].path, '/expenses');
    expect(adapter.requests[0].data, {
      'date': '2026-11-05',
      'amount_vnd': 250000,
      'category': 'Văn phòng phẩm',
      'source': 'OCR',
    });
    expect(adapter.requests[1].path, '/expenses/expense-ocr-1/confirm');

    dio.close();
  });
}
