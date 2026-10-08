import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_router/app_router_names.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.primaryIcon,
    required this.secondaryIcon,
    required this.accentColor,
    required this.features,
  });

  final String badge;
  final String title;
  final String subtitle;
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final Color accentColor;
  final List<String> features;
}

/// First-launch 3-step onboarding screen styled after the Listodo UI Kit.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<_OnboardingSlideData> _slides = [
    _OnboardingSlideData(
      badge: 'УМНЫЕ ЗАДАЧИ',
      title: 'Управляйте всеми делами в одном месте',
      subtitle:
          'Создавайте задачи с приоритетами и категорией «Общее», чтобы срочные дела всегда оставались на виду.',
      primaryIcon: Icons.local_fire_department_rounded,
      secondaryIcon: Icons.public_rounded,
      accentColor: Color(0xFFFF4D4F),
      features: [
        '4 уровня приоритета: Срочно 🔥, Высокий ⚡, Средний 📌, Низкий 🌿',
        'Категория «Общее» светится во всех вкладках и не даёт забыть важное',
      ],
    ),
    _OnboardingSlideData(
      badge: 'РАСПИСАНИЕ И КАЛЕНДАРЬ',
      title: 'Планируйте свой день с точностью до минуты',
      subtitle:
          'Выбирайте дату в кастомном календаре и настраивайте часы и минуты удобными барабанами как на iPhone.',
      primaryIcon: Icons.calendar_month_rounded,
      secondaryIcon: Icons.schedule_rounded,
      accentColor: AppColors.accentYellow,
      features: [
        'Быстрые кнопки: Сегодня, Завтра, Через неделю',
        'Двойной скролл времени (Часы / Минуты) и лента дней в Календаре',
      ],
    ),
    _OnboardingSlideData(
      badge: 'ФОКУС И АРХИВ',
      title: 'Фокусируйтесь на главном и храните историю',
      subtitle:
          'Включайте Помодоро-таймер для глубокой работы и смахивайте выполненные задачи вправо — прямо в личный архив.',
      primaryIcon: Icons.timer_outlined,
      secondaryIcon: Icons.inventory_2_outlined,
      accentColor: AppColors.active,
      features: [
        'Свайп вправо на выполненной карточке отправляет её в Архив профиля',
        'Встроенный таймер фокуса (15 / 25 / 45 мин) с привязкой к задаче',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await context.read<AuthController>().completeOnboarding();
    if (!mounted) return;
    context.goNamed(AppRouterNames.welcome);
  }

  void _nextSlide() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevSlide() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              // Top bar: Listodo logo badge + Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'TodoApp',
                        style: TextStyle(
                          color: AppColors.maintext,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.rotate(
                        angle: -8 * math.pi / 180,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentYellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'to-do',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Пропустить',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Main PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _OnboardingSlideWidget(slide: slide);
                  },
                ),
              ),

              // Step indicator pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: active ? 28 : 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accentYellow : Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Bottom navigation buttons: Back & Next / Start
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    TextButton(
                      onPressed: _prevSlide,
                      child: const Text(
                        'НАЗАД',
                        style: TextStyle(
                          color: AppColors.labeltext,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 72),
                  ElevatedButton(
                    onPressed: _nextSlide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.active,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isLast ? 'НАЧАТЬ РАБОТУ' : 'ДАЛЕЕ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideWidget extends StatelessWidget {
  const _OnboardingSlideWidget({required this.slide});

  final _OnboardingSlideData slide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // Hero visual card
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.accentColor.withValues(alpha: 0.12),
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(slide.primaryIcon, size: 74, color: slide.accentColor),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      slide.secondaryIcon,
                      size: 22,
                      color: AppColors.accentYellow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: slide.accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              slide.badge,
              style: TextStyle(
                color: slide.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.maintext,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.labeltext,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ...slide.features.map(
            (feat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: slide.accentColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feat,
                        style: const TextStyle(
                          color: AppColors.maintext,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
