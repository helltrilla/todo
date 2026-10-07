import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';

/// Displays a single selectable priority tile in the priority picker grid.
class PriorityCard extends StatelessWidget {
  const PriorityCard({
    super.key,
    required this.priority,
    required this.isActive,
    required this.onTap,
  });

  final PriorityLevel priority;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isActive ? priority.color : AppColors.unactive,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              priority.icon,
              color: isActive ? AppColors.white : priority.color,
              size: 16,
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Text(
                priority.label,
                style: const TextStyle(color: AppColors.white, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
