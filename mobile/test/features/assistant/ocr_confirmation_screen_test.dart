import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:dt13_pos/features/assistant/domain/ocr_invoice_result.dart';
import 'package:dt13_pos/features/assistant/presentation/ocr_confirmation_screen.dart';
import 'package:dt13_pos/features/ledger/data/ledger_providers.dart';
import 'package:dt13_pos/features/ledger/data/ledger_repository.dart';
import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingLedgerRepository extends LedgerRepository {
  _CapturingLedgerRepository(super._api);

  LedgerEntry? createdEntry;
  String? confirmedExpenseId;

  @override
  Future<String> createOcrExpense(LedgerEntry entry) async {
    createdEntry = entry;
    return 'expense-1';
  }

  @override
  Future<void> confirmExpense(String expenseId) async {
    confirmedExpenseId = expenseId;
  }
}

void main() {
  const initialData = OcrInvoiceResult(
    filename: 'invoice.png',
    taxCode: '0123456789',
    invoiceDate: '05/11/2026',
    totalAmount: 150000,
    needUserConfirmation: true,
  );

  late Dio dio;
  late _CapturingLedgerRepository repository;

  setUp(() {
    const env = AppEnv(
      flavor: Flavor.dev,
      apiBaseUrl: 'http://localhost',
      enableHttpLog: false,
    );
    dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    repository = _CapturingLedgerRepository(
      ApiClient(env: env, tokenStorage: InMemoryTokenStorage(), dio: dio),
    );
  });

  tearDown(() {
    dio.close(force: true);
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [ledgerRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: OcrConfirmationScreen(
          initialData: initialData,
          imageBytes: Uint8List(0),
        ),
      ),
    );
  }

  testWidgets('hiển thị thông tin nhận diện trong các trường của form', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields, hasLength(3));
    expect(fields[0].controller?.text, '0123456789');
    expect(fields[1].controller?.text, '05/11/2026');
    expect(fields[2].controller?.text, '150000');
    expect(
      find.text('Vui lòng kiểm tra lại thông tin AI đã nhận diện.'),
      findsOneWidget,
    );
  });

  testWidgets('ghi bút toán theo tổng tiền và danh mục đã chỉnh sửa', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

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

    final entry = repository.createdEntry;
    expect(entry, isNotNull);
    expect(entry!.book, 'EXPENSE');
    expect(entry.type, 'EXPENSE');
    expect(entry.refType, 'EXPENSE');
    expect(entry.entryDate, '2026-11-05');
    expect(entry.amountVnd, 250000);
    expect(entry.category, 'Văn phòng phẩm');
    expect(entry.note, '0123456789');
    expect(repository.confirmedExpenseId, 'expense-1');
  });
}
