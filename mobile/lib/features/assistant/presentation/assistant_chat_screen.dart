import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/features/assistant/data/assistant_providers.dart';
import 'package:dt13_pos/features/assistant/domain/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  ConsumerState<AssistantChatScreen> createState() =>
      _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  static const List<String> _suggestions = [
    'Doanh thu dưới 1 tỷ đóng thuế gì?',
    'Thuế suất từng ngành nghề 2026',
    'Cách ghi sổ hóa đơn OCR',
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(assistantChatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý AI thuế HKDN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Xóa hội thoại',
            onPressed: ref.read(assistantChatProvider.notifier).clearHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.padding,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    for (final suggestion in _suggestions)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(suggestion),
                          onPressed: chatState.isSending
                              ? null
                              : () => unawaited(_send(suggestion)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.padding,
                  vertical: 8,
                ),
                itemCount: chatState.messages.length,
                itemBuilder: (context, index) {
                  final messageIndex = chatState.messages.length - index - 1;
                  return _MessageBubble(
                    message: chatState.messages[messageIndex],
                  );
                },
              ),
            ),
            if (chatState.isSending)
              const LinearProgressIndicator(minHeight: 2),
            _buildComposer(chatState.isSending),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(bool isSending) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.padding),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (text) => unawaited(_send(text)),
              decoration: const InputDecoration(
                hintText: 'Nhập câu hỏi về thuế HKDN...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Gửi câu hỏi',
            icon: const Icon(Icons.send),
            onPressed: isSending
                ? null
                : () => unawaited(_send(_controller.text)),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty) return;
    _controller.clear();
    try {
      await ref.read(assistantChatProvider.notifier).sendMessage(question);
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể gửi câu hỏi: ${error.message ?? 'Lỗi kết nối.'}',
          ),
        ),
      );
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppSpacing.padding),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          child: Text(
            message.content,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.content, style: AppTypography.bodyMedium),
              if (message.refused) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                  child: Text(
                    message.refusalReason ?? message.content,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
              if (message.sources.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final source in message.sources)
                      _SourceChip(source: source),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final AnswerSource source;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(
        'Nguồn: ${source.type} • ${source.id}',
        style: AppTypography.labelSmall,
      ),
      backgroundColor: AppColors.primaryContainer,
      side: BorderSide.none,
    );
  }
}
