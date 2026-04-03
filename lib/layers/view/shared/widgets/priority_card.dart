import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/layers/domain/entity/priority_level.dart';

class PriorityCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final PriorityLevel priority;

  const PriorityCard({
    super.key,
    required this.isActive,
    required this.onTap,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isActive ? priority.color : AppColors.unactive,
          borderRadius: BorderRadiusDirectional.circular(12),
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
              )
            ]
          ],
        ),
      ),
    );
  }
}
