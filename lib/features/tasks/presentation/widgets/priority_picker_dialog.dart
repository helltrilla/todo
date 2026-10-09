import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/presentation/widgets/priority_card.dart';

/// Dialog for choosing one of the 4 expressive task priority levels.
/// Returns the selected priority index (0..3), or -1 if cleared.
class PriorityPickerDialog extends StatefulWidget {
  const PriorityPickerDialog({super.key, this.initialIndex = -1});

  final int initialIndex;

  @override
  State<PriorityPickerDialog> createState() => _PriorityPickerDialogState();
}

class _PriorityPickerDialogState extends State<PriorityPickerDialog> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex >= 0 && widget.initialIndex <= 3
        ? widget.initialIndex
        : (widget.initialIndex > 3 ? 3 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final items = PriorityLevel.selectable;

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Приоритет задачи',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.maintext,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Влияет на позицию в списке и подсветку карточки',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.labeltext, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...List.generate(items.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PriorityCard(
                    priority: items[index],
                    isSelected: _selectedIndex == index,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.labeltext,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.pop(_selectedIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.active,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Сохранить',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
