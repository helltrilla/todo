import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todo/core/app_router/app_router_names.dart';
import 'package:todo/core/app_theme/app_colors.dart';

/// Initial onboarding / welcome screen styled after the Listodo UI Kit.
/// Lets the user choose between:
/// 1. Email OTP authentication via Supabase
/// 2. Internal local registration / login
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgmain,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const _ListodoHeroBanner(),
              const SizedBox(height: 24),
              const Text(
                'Управляй своими задачами легко и стильно',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.maintext,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Выбери удобный способ входа: через реальную почту с кодом подтверждения (Supabase) или создай внутренний локальный профиль.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.labeltext,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context.pushNamed(AppRouterNames.emailAuth),
                icon: const Icon(Icons.mark_email_unread_outlined, size: 20),
                label: const Text(
                  'Вход по Почте (Код OTP)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.active,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => context.pushNamed(AppRouterNames.internalAuth),
                icon: const Icon(Icons.person_outline, size: 20),
                label: const Text(
                  'Внутренняя регистрация / Вход',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentYellow,
                  side: const BorderSide(
                    color: AppColors.accentYellow,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListodoHeroBanner extends StatelessWidget {
  const _ListodoHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: AppColors.active,
                ),
                SizedBox(height: 12),
                Text(
                  'Listtodo',
                  style: TextStyle(
                    color: AppColors.maintext,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            right: -14,
            child: Transform.rotate(
              angle: 12 * math.pi / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'to-do',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
