import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/presentation/widgets/priority_card.dart';

/// Dialog that lets the user pick a priority level.
/// Returns the selected [PriorityLevel] index via [Navigator.pop] / [context.pop].
class PriorityPickerDialog extends StatefulWidget {
  const PriorityPickerDialog({super.key, this.initialIndex});

  final int? initialIndex;

  @override
  State<PriorityPickerDialog> createState() => _PriorityPickerDialogState();
}

class _PriorityPickerDialogState extends State<PriorityPickerDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIndex ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Task Priority',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.maintext, fontSize: 16),
      ),
      content: SizedBox(
        height: 260,
        width: 327,
        child: GridView.builder(
          itemCount: PriorityLevel.values.length - 1, // exclude .none
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final priority = PriorityLevel.fromIndex(index);
            return PriorityCard(
              priority: priority,
              isActive: _selected == index,
              onTap: () =>
                  setState(() => _selected = _selected == index ? -1 : index),
            );
          },
        ),
      ),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.pop(_selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
