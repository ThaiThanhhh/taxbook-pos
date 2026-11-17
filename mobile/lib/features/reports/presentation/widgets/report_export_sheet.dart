import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _ReportContentMode { summary, csv }

class ReportExportSheet extends StatefulWidget {
  const ReportExportSheet({
    required this.title,
    required this.textContent,
    required this.csvContent,
    required this.messenger,
    super.key,
  });

  final String title;
  final String textContent;
  final String csvContent;
  final ScaffoldMessengerState messenger;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String textContent,
    required String csvContent,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ReportExportSheet(
        title: title,
        textContent: textContent,
        csvContent: csvContent,
        messenger: messenger,
      ),
    );
  }

  @override
  State<ReportExportSheet> createState() => _ReportExportSheetState();
}

class _ReportExportSheetState extends State<ReportExportSheet> {
  _ReportContentMode _mode = _ReportContentMode.summary;

  String get _selectedContent => switch (_mode) {
    _ReportContentMode.summary => widget.textContent,
    _ReportContentMode.csv => widget.csvContent,
  };

  @override
  Widget build(BuildContext context) {
    final isCsv = _mode == _ReportContentMode.csv;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.padding,
        right: AppSpacing.padding,
        top: AppSpacing.padding,
        bottom: AppSpacing.padding + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.padding),
            SegmentedButton<_ReportContentMode>(
              segments: const [
                ButtonSegment(
                  value: _ReportContentMode.summary,
                  label: Text('Bản tóm tắt'),
                ),
                ButtonSegment(
                  value: _ReportContentMode.csv,
                  label: Text('Dữ liệu CSV'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.first);
              },
            ),
            const SizedBox(height: AppSpacing.padding),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.padding),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _selectedContent,
                    style: isCsv
                        ? const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.5,
                          )
                        : AppTypography.bodyMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.padding),
            PrimaryButton(
              label: 'Sao chép nội dung báo cáo',
              onPressed: _copyContent,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyContent() async {
    try {
      await Clipboard.setData(ClipboardData(text: _selectedContent));
    } on PlatformException {
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Không thể sao chép báo cáo.')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.messenger.showSnackBar(
      const SnackBar(content: Text('Đã sao chép báo cáo vào bộ nhớ tạm')),
    );
  }
}
