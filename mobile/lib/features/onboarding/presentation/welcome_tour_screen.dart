import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:dt13_pos/core/theme/app_colors.dart';
import 'package:dt13_pos/core/theme/app_spacing.dart';
import 'package:dt13_pos/core/theme/app_typography.dart';
import 'package:dt13_pos/core/widgets/app_card.dart';
import 'package:dt13_pos/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeTourScreen extends StatefulWidget {
  const WelcomeTourScreen({super.key});

  @override
  State<WelcomeTourScreen> createState() => _WelcomeTourScreenState();
}

class _WelcomeTourScreenState extends State<WelcomeTourScreen> {
  static const List<_TourSlide> _slides = [
    _TourSlide(
      icon: '📖',
      title: 'Sổ thu chi đơn giản',
      description:
          'Quản lý bán hàng POS và ghi nhật ký thu chi nhanh chóng, rõ ràng.',
    ),
    _TourSlide(
      icon: '🤖',
      title: 'Trợ lý AI & OCR',
      description:
          'Chụp ảnh hóa đơn chi phí để AI tự động quét và đối soát giúp bạn.',
    ),
    _TourSlide(
      icon: '🧮',
      title: 'Tự động tính thuế HKDN 2026',
      description: 'Ước tính nghĩa vụ thuế GTGT và TNCN theo quy định mới.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.padding),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.onboarding),
                  child: const Text('Bỏ qua', style: AppTypography.labelLarge),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() {
                    _currentPage = page;
                  }),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Center(
                      child: AppCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slide.icon,
                              style: const TextStyle(fontSize: 64),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: AppTypography.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (isLastPage)
                PrimaryButton(
                  label: 'Khai báo thông tin HKDN',
                  onPressed: () => context.go(AppRoutes.onboarding),
                )
              else
                PrimaryButton(
                  label: 'Tiếp tục',
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourSlide {
  const _TourSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon;
  final String title;
  final String description;
}
