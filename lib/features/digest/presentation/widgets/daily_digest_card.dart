import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/features/digest/presentation/controllers/daily_digest_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

class DailyDigestCard extends StatefulWidget {
  const DailyDigestCard({super.key});

  @override
  State<DailyDigestCard> createState() => _DailyDigestCardState();
}

class _DailyDigestCardState extends State<DailyDigestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  void _syncShimmer(bool isLoading) {
    if (isLoading && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!isLoading && _shimmerController.isAnimating) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DailyDigestController, TaskController>(
      builder: (context, digestController, taskController, _) {
        _syncShimmer(digestController.isLoading);
        if (!digestController.isVisible) {
          return const SizedBox.shrink();
        }

        if (digestController.isLoading) {
          return _buildShimmerSkeleton();
        }

        final digest = digestController.digest;
        if (digest == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF221A3A),
                Color(0xFF16152B),
                Color(0xFF121212),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8875FF).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8875FF).withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -24,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8875FF).withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8875FF), Color(0xFFFF52D9)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'AI DAILY DIGEST',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            color: AppColors.labeltext,
                            tooltip: 'Обновить бриф',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              AppHaptics.selection();
                              digestController.refresh(taskController.tasks);
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: AppColors.labeltext,
                            tooltip: 'Скрыть',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              AppHaptics.light();
                              digestController.dismiss();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Headline
                      Text(
                        digest.headline,
                        style: const TextStyle(
                          color: AppColors.maintext,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildBadge(
                            icon: Icons.bolt_rounded,
                            label: 'Фокус: ${digest.topFocus}',
                            color: const Color(0xFFFFA940),
                          ),
                          _buildBadge(
                            icon: Icons.schedule_rounded,
                            label: digest.productivitySlot,
                            color: const Color(0xFF5C7CFA),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Summary
                      Text(
                        digest.summary,
                        style: const TextStyle(
                          color: Color(0xFFC7C7CC),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(width: 110, height: 22, radius: 10),
                  const Spacer(),
                  _shimmerBox(width: 20, height: 20, radius: 10),
                ],
              ),
              const SizedBox(height: 14),
              _shimmerBox(width: double.infinity, height: 18, radius: 6),
              const SizedBox(height: 10),
              Row(
                children: [
                  _shimmerBox(width: 140, height: 24, radius: 8),
                  const SizedBox(width: 8),
                  _shimmerBox(width: 100, height: 24, radius: 8),
                ],
              ),
              const SizedBox(height: 12),
              _shimmerBox(width: double.infinity, height: 14, radius: 4),
              const SizedBox(height: 6),
              _shimmerBox(width: 200, height: 14, radius: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C38),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
