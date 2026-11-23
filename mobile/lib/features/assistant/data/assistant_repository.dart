import 'package:dio/dio.dart';
import 'package:dt13_pos/core/network/api_client.dart';
import 'package:dt13_pos/features/assistant/domain/chat_message.dart';

class AssistantRepository {
  AssistantRepository(this._api);

  final ApiClient _api;

  Future<AskResponse> askQuestion(String question) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      throw ArgumentError.value(
        question,
        'question',
        'Câu hỏi không được để trống.',
      );
    }

    try {
      final response = await _api.post<Object?>(
        '/ai/ask',
        data: {'question': trimmedQuestion},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Phản hồi trợ lý AI không hợp lệ.');
      }
      return AskResponse.fromJson(data);
    } on DioException catch (error) {
      if (!_shouldUseFallback(error)) rethrow;
      return _fallbackFor(trimmedQuestion);
    }
  }

  bool _shouldUseFallback(DioException error) {
    if (error.response?.statusCode == 404 ||
        error.response?.statusCode == 501) {
      return true;
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }

  AskResponse _fallbackFor(String question) {
    final normalizedQuestion = question.toLowerCase();

    if (_containsAny(normalizedQuestion, [
      'hóa đơn',
      'hoá đơn',
      'ocr',
      'ghi sổ',
      'chi phí',
    ])) {
      return const AskResponse(
        answer:
            'Quy trình gồm chụp hóa đơn, để AI bóc tách thông tin, sau đó '
            'chủ hộ đối soát. Hóa đơn chỉ được ghi vào sổ chi phí sau khi '
            'chủ hộ bấm “Xác nhận & Ghi sổ chi phí”.',
        sources: [AnswerSource(type: 'SRS', id: 'FR-OCR-CONFIRM')],
        isFallback: true,
      );
    }

    if (_containsAny(normalizedQuestion, [
      'doanh thu',
      'ngưỡng',
      'miễn thuế',
      '1 tỷ',
      '1.000.000.000',
    ])) {
      return const AskResponse(
        answer:
            'Theo quy tắc BR-06, hộ kinh doanh có doanh thu năm không quá '
            '1 tỷ VND được miễn thuế GTGT và thuế TNCN.',
        sources: [AnswerSource(type: 'LAW', id: 'HKDN-2026-BR06')],
        isFallback: true,
      );
    }

    if (_containsAny(normalizedQuestion, [
      'thuế suất',
      'ngành nghề',
      'gtgt',
      'tncn',
      'goods_distribution',
      'service',
      'production_transport',
    ])) {
      return const AskResponse(
        answer:
            'Thuế suất theo nhóm ngành nghề: phân phối hàng hóa '
            '(GOODS_DISTRIBUTION) GTGT 1%, TNCN 0,5%; dịch vụ (SERVICE) '
            'GTGT 5%, TNCN 2%; sản xuất, vận tải (PRODUCTION_TRANSPORT) '
            'GTGT 3%, TNCN 1,5%; ngành nghề khác (OTHER) GTGT 2%, TNCN 1%.',
        sources: [AnswerSource(type: 'LAW', id: 'HKDN-2026-RATES')],
        isFallback: true,
      );
    }

    const refusalReason =
        'Trợ lý chỉ hỗ trợ giải đáp nghiệp vụ bán hàng, sổ sách và thuế '
        'Hộ kinh doanh 2026.';
    return const AskResponse(
      answer: refusalReason,
      refused: true,
      refusalReason: refusalReason,
      isFallback: true,
    );
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}
