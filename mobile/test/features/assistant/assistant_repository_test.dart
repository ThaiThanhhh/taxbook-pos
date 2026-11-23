import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dt13_pos/core/constants/app_env.dart';
import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/core/network/token_storage.dart';
import 'package:dt13_pos/features/assistant/data/assistant_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('POST /ai/ask trims question and parses answer sources', () async {
    final adapter = _FakeHttpClientAdapter(
      (request) => _jsonResponse({
        'answer': 'Doanh thu năm không quá 1 tỷ được miễn thuế.',
        'sources': [
          {
            'type': 'LAW',
            'id': 'HKDN-2026-BR06',
            'fields': {'rule': 'BR-06'},
          },
        ],
      }),
    );
    final repository = _createRepository(adapter);

    final response = await repository.askQuestion('  Doanh thu dưới 1 tỷ?  ');

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.uri.path, endsWith('/ai/ask'));
    final payload = _decodePayload(adapter.lastRequest?.data);
    expect(payload, {'question': 'Doanh thu dưới 1 tỷ?'});
    expect(response.answer, 'Doanh thu năm không quá 1 tỷ được miễn thuế.');
    expect(response.sources, hasLength(1));
    expect(response.sources.single.type, 'LAW');
    expect(response.sources.single.id, 'HKDN-2026-BR06');
    expect(response.sources.single.fields, {'rule': 'BR-06'});
    expect(response.isFallback, isFalse);
  });

  test('parses refused response and refusal reason', () async {
    final adapter = _FakeHttpClientAdapter(
      (request) => _jsonResponse({
        'answer': 'Tôi không thể hỗ trợ yêu cầu này.',
        'sources': <Object?>[],
        'refused': true,
        'refusal_reason': 'Ngoài phạm vi hỗ trợ.',
      }),
    );
    final repository = _createRepository(adapter);

    final response = await repository.askQuestion('Hãy kể chuyện.');

    expect(response.refused, isTrue);
    expect(response.refusalReason, 'Ngoài phạm vi hỗ trợ.');
    expect(response.sources, isEmpty);
  });

  test('uses local tax fallback when endpoint returns 404', () async {
    final adapter = _FakeHttpClientAdapter(
      (request) => _jsonResponse({
        'message': 'Not found',
      }, statusCode: HttpStatus.notFound),
    );
    final repository = _createRepository(adapter);

    final response = await repository.askQuestion(
      'Doanh thu dưới 1 tỷ đóng thuế gì?',
    );

    expect(response.isFallback, isTrue);
    expect(response.answer, contains('1 tỷ VND'));
    expect(response.sources.single.id, 'HKDN-2026-BR06');
  });

  test('uses local fallback when the server is unreachable', () async {
    final adapter = _FakeHttpClientAdapter((request) {
      throw DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
        error: const SocketException('No connection'),
      );
    });
    final repository = _createRepository(adapter);

    final response = await repository.askQuestion('Cách ghi sổ hóa đơn OCR?');

    expect(response.isFallback, isTrue);
    expect(response.answer, contains('chụp hóa đơn'));
    expect(response.sources.single.id, 'FR-OCR-CONFIRM');
  });

  test(
    'uses rate fallback and refuses unsupported questions locally',
    () async {
      final adapter = _FakeHttpClientAdapter((request) {
        throw DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
        );
      });
      final repository = _createRepository(adapter);

      final rates = await repository.askQuestion(
        'Thuế suất từng ngành nghề 2026',
      );
      expect(rates.isFallback, isTrue);
      expect(rates.sources.single.id, 'HKDN-2026-RATES');
      expect(rates.answer, contains('GOODS_DISTRIBUTION'));
      expect(rates.answer, contains('PRODUCTION_TRANSPORT'));

      final unsupported = await repository.askQuestion(
        'Thời tiết hôm nay thế nào?',
      );
      expect(unsupported.isFallback, isTrue);
      expect(unsupported.refused, isTrue);
      expect(
        unsupported.refusalReason,
        'Trợ lý chỉ hỗ trợ giải đáp nghiệp vụ bán hàng, sổ sách và thuế '
        'Hộ kinh doanh 2026.',
      );
    },
  );

  test('rejects a blank question without sending a request', () async {
    final adapter = _FakeHttpClientAdapter((request) => _jsonResponse({}));
    final repository = _createRepository(adapter);

    await expectLater(
      repository.askQuestion('  \n '),
      throwsA(isA<ArgumentError>()),
    );
    expect(adapter.lastRequest, isNull);
  });
}

AssistantRepository _createRepository(_FakeHttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
  dio.httpClientAdapter = adapter;
  final api = ApiClient(
    env: const AppEnv(
      flavor: Flavor.dev,
      apiBaseUrl: 'https://example.test/api/v1',
      enableHttpLog: false,
    ),
    tokenStorage: InMemoryTokenStorage(),
    dio: dio,
  );
  return AssistantRepository(api);
}

Map<String, dynamic> _decodePayload(Object? data) {
  if (data is String) {
    final Object? decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) return decoded;
  }
  if (data is Map<String, dynamic>) return data;
  fail('Expected JSON request payload, got $data');
}

ResponseBody _jsonResponse(Object body, {int statusCode = HttpStatus.ok}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.respond);

  final ResponseBody Function(RequestOptions request) respond;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
