import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  static const List<_GuideStep> _steps = [
    _GuideStep(
      icon: Icons.storefront_outlined,
      title: 'Thiết lập Hộ kinh doanh',
      description:
          'Khai báo Mã số thuế gồm 10 hoặc 13 chữ số, chọn nhóm ngành nghề '
          '(Phân phối hàng hóa, Dịch vụ, Sản xuất / Vận tải hoặc Khác) và '
          'phương pháp tính thuế phù hợp.',
    ),
    _GuideStep(
      icon: Icons.point_of_sale_outlined,
      title: 'Bán hàng & Ghi nhận doanh thu',
      description:
          'Tạo đơn hàng tại màn hình Bán hàng. Doanh thu được tự động đồng '
          'bộ vào Sổ thu chi, kể cả khi thiết bị tạm thời mất mạng.',
    ),
    _GuideStep(
      icon: Icons.document_scanner_outlined,
      title: 'Chụp hóa đơn chi phí bằng AI (OCR)',
      description:
          'Chụp hóa đơn mua vào tại mục Trợ lý AI, kiểm tra thông tin được '
          'bóc tách rồi bấm “Xác nhận & Ghi sổ”. Hóa đơn chưa xác nhận sẽ '
          'không được cộng vào sổ.',
    ),
    _GuideStep(
      icon: Icons.bar_chart_outlined,
      title: 'Xem báo cáo & Tự tính thuế 2026',
      description:
          'Theo dõi lãi/lỗ trong ngày, sản phẩm bán chạy và số thuế '
          'GTGT/TNCN tạm tính. Doanh thu năm không quá 1 tỷ đồng thuộc '
          'ngưỡng miễn thuế theo thông tin áp dụng trong ứng dụng.',
    ),
  ];

  static const List<_GuideQuestion> _questions = [
    _GuideQuestion(
      question: 'Mất kết nối Internet có bán hàng được không?',
      answer:
          'Có. Ứng dụng lưu đơn hàng cục bộ trên thiết bị (Offline-first) '
          'để bạn tiếp tục bán hàng. Khi có mạng trở lại, dữ liệu sẽ tự '
          'đồng bộ lên hệ thống.',
    ),
    _GuideQuestion(
      question: 'Tại sao chụp hóa đơn xong chưa thấy cộng vào chi phí?',
      answer:
          'Thông tin do AI bóc tách cần được bạn đối soát. Chỉ khi bấm '
          '“Xác nhận & Ghi sổ”, hóa đơn mới được ghi nhận vào chi phí.',
    ),
    _GuideQuestion(
      question: 'Doanh thu bao nhiêu thì phải nộp thuế GTGT và TNCN năm 2026?',
      answer:
          'Theo ngưỡng miễn thuế được nêu trong ứng dụng, hộ kinh doanh có '
          'doanh thu năm không quá 1 tỷ đồng được miễn thuế GTGT và TNCN. '
          'Khi vượt ngưỡng, ứng dụng ước tính thuế theo tỷ lệ của từng '
          'nhóm ngành nghề; hãy kiểm tra quy định hiện hành để xác định '
          'nghĩa vụ chính thức.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hướng dẫn sử dụng')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.padding),
        children: [
          const Text('Các bước bắt đầu', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.padding),
          for (var index = 0; index < _steps.length; index++) ...[
            _GuideStepCard(number: index + 1, step: _steps[index]),
            if (index < _steps.length - 1)
              const SizedBox(height: AppSpacing.padding),
          ],
          const SizedBox(height: 24),
          const Text('Câu hỏi thường gặp', style: AppTypography.headlineSmall),
          const SizedBox(height: 8),
          for (final question in _questions)
            AppCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                title: Text(question.question, style: AppTypography.labelLarge),
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.padding,
                  0,
                  AppSpacing.padding,
                  AppSpacing.padding,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      question.answer,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  const _GuideStepCard({required this.number, required this.step});

  final int number;
  final _GuideStep step;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            child: Text('$number', style: AppTypography.labelLarge),
          ),
          const SizedBox(width: AppSpacing.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(step.icon, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(step.title, style: AppTypography.titleSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  step.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  const _GuideStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _GuideQuestion {
  const _GuideQuestion({required this.question, required this.answer});

  final String question;
  final String answer;
}
