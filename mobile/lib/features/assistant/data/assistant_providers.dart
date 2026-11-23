import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/features/assistant/data/assistant_repository.dart';
import 'package:dt13_pos/features/assistant/domain/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(ref.watch(apiClientProvider));
});

class AssistantChatState {
  const AssistantChatState({required this.messages, this.isSending = false});

  final List<ChatMessage> messages;
  final bool isSending;

  AssistantChatState copyWith({List<ChatMessage>? messages, bool? isSending}) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

class AssistantChatNotifier extends Notifier<AssistantChatState> {
  int _conversationGeneration = 0;

  @override
  AssistantChatState build() => _welcomeState();

  Future<void> sendMessage(String text) async {
    final question = text.trim();
    if (question.isEmpty || state.isSending) return;

    final generation = _conversationGeneration;
    final timestamp = DateTime.now();
    final userMessage = ChatMessage(
      id: 'user-${timestamp.microsecondsSinceEpoch}',
      content: question,
      isUser: true,
      timestamp: timestamp,
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
    );

    try {
      final response = await ref
          .read(assistantRepositoryProvider)
          .askQuestion(question);
      if (generation != _conversationGeneration) return;

      final answerTimestamp = DateTime.now();
      final assistantMessage = ChatMessage(
        id: 'assistant-${answerTimestamp.microsecondsSinceEpoch}',
        content: response.answer,
        isUser: false,
        timestamp: answerTimestamp,
        sources: response.sources,
        refused: response.refused,
        refusalReason: response.refusalReason,
        isFallback: response.isFallback,
      );
      state = state.copyWith(messages: [...state.messages, assistantMessage]);
    } finally {
      if (generation == _conversationGeneration) {
        state = state.copyWith(isSending: false);
      }
    }
  }

  void clearHistory() {
    _conversationGeneration++;
    state = _welcomeState();
  }

  AssistantChatState _welcomeState() {
    return AssistantChatState(
      messages: [
        ChatMessage(
          id: 'welcome',
          content:
              'Xin chào! Tôi là Trợ lý AI thuế HKDN 2026. Tôi có thể hỗ trợ '
              'về bán hàng, sổ sách và thuế hộ kinh doanh.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }
}

final assistantChatProvider =
    NotifierProvider<AssistantChatNotifier, AssistantChatState>(
      AssistantChatNotifier.new,
    );
