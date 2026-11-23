import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:dt13_pos/core/theme/app_theme.dart';
import 'package:dt13_pos/features/assistant/data/assistant_providers.dart';
import 'package:dt13_pos/features/assistant/data/assistant_repository.dart';
import 'package:dt13_pos/features/assistant/presentation/assistant_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows title, welcome message, and suggested questions', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());

    expect(find.text('Trợ lý AI thuế HKDN'), findsOneWidget);
    expect(find.textContaining('Trợ lý AI thuế HKDN 2026'), findsOneWidget);
    expect(find.text('Doanh thu dưới 1 tỷ đóng thuế gì?'), findsOneWidget);
    expect(find.text('Thuế suất từng ngành nghề 2026'), findsOneWidget);
    expect(find.text('Cách ghi sổ hóa đơn OCR'), findsOneWidget);
  });

  testWidgets('suggestion sends question and displays answer source', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.tap(find.text('Doanh thu dưới 1 tỷ đóng thuế gì?'));
    await tester.pumpAndSettle();

    expect(find.text('Doanh thu dưới 1 tỷ đóng thuế gì?'), findsNWidgets(2));
    expect(find.text('Câu trả lời kiểm thử.'), findsOneWidget);
    expect(find.text('Nguồn: LAW • HKDN-2026-BR06'), findsOneWidget);
  });

  testWidgets('text field submits a question using the send button', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.enterText(
      find.byType(TextField),
      'Thuế suất từng ngành nghề 2026',
    );
    await tester.tap(find.byTooltip('Gửi câu hỏi'));
    await tester.pumpAndSettle();

    expect(find.text('Thuế suất từng ngành nghề 2026'), findsNWidgets(2));
    expect(find.text('Câu trả lời kiểm thử.'), findsOneWidget);
    expect(find.text('Nguồn: LAW • HKDN-2026-RATES'), findsOneWidget);
  });
}

Widget _buildApp() {
  final adapter = _FakeHttpClientAdapter((request) {
    final requestData = request.data;
    final Object? decoded = requestData is String
        ? jsonDecode(requestData)
        : requestData;
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Expected JSON request payload.');
    }
    final question = decoded['question'] as String;

    return ResponseBody.fromString(
      jsonEncode({
        'answer': 'Câu trả lời kiểm thử.',
        'sources': [
          {
            'type': 'LAW',
            'id': question.toLowerCase().contains('thuế suất')
                ? 'HKDN-2026-RATES'
                : 'HKDN-2026-BR06',
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  });
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
  dio.httpClientAdapter = adapter;
  final repository = AssistantRepository(
    ApiClient(
      env: const AppEnv(
        flavor: Flavor.dev,
        apiBaseUrl: 'https://example.test/api/v1',
        enableHttpLog: false,
      ),
      tokenStorage: InMemoryTokenStorage(),
      dio: dio,
    ),
  );

  return ProviderScope(
    overrides: [assistantRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const AssistantChatScreen(),
    ),
  );
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.respond);

  final ResponseBody Function(RequestOptions request) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
