class AnswerSource {
  const AnswerSource({required this.type, required this.id, this.fields});

  factory AnswerSource.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'];
    if (fields != null && fields is! Map<String, dynamic>) {
      throw const FormatException('Các trường nguồn trích dẫn không hợp lệ.');
    }
    return AnswerSource(
      type: json['type'] as String,
      id: json['id'] as String,
      fields: fields as Map<String, dynamic>?,
    );
  }

  final String type;
  final String id;
  final Map<String, dynamic>? fields;
}

class AskResponse {
  const AskResponse({
    required this.answer,
    this.sources = const [],
    this.refused = false,
    this.refusalReason,
    this.isFallback = false,
  });

  factory AskResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] ?? const <Object?>[];
    if (rawSources is! List<Object?>) {
      throw const FormatException('Danh sách nguồn trích dẫn không hợp lệ.');
    }

    return AskResponse(
      answer: json['answer'] as String,
      sources: rawSources
          .map((source) {
            if (source is! Map<String, dynamic>) {
              throw const FormatException('Nguồn trích dẫn không hợp lệ.');
            }
            return AnswerSource.fromJson(source);
          })
          .toList(growable: false),
      refused: json['refused'] as bool? ?? false,
      refusalReason: json['refusal_reason'] as String?,
    );
  }

  final String answer;
  final List<AnswerSource> sources;
  final bool refused;
  final String? refusalReason;
  final bool isFallback;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.sources = const [],
    this.refused = false,
    this.refusalReason,
    this.isFallback = false,
  });

  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<AnswerSource> sources;
  final bool refused;
  final String? refusalReason;
  final bool isFallback;
}
