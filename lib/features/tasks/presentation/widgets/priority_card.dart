import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';

/// Selectable priority row card displaying the priority icon, title, subtitle, and active state.
class PriorityCard extends StatelessWidget {
  const PriorityCard({
    super.key,
    required this.priority,
    required this.isSelected,
    this.onTap,
  });

  final PriorityLevel priority;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? priority.color.withValues(alpha: 0.16)
              : AppColors.bgmain,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? priority.color : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: priority.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(priority.icon, color: priority.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priority.label,
                    style: TextStyle(
                      color: isSelected ? priority.color : AppColors.maintext,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priority.subtitle,
                    style: TextStyle(
                      color: AppColors.labeltext,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: priority.color, size: 22),
          ],
        ),
      ),
    );
  }
}
