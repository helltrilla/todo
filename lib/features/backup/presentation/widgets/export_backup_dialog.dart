import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/features/backup/domain/entities/export_format.dart';
import 'package:todo/features/backup/presentation/controllers/backup_controller.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Modal dialog providing interactive Export, Backup, and Sharing choices.
class ExportBackupDialog extends StatefulWidget {
  const ExportBackupDialog({
    super.key,
    required this.tasks,
    required this.categories,
  });

  final List<Task> tasks;
  final List<String> categories;

  static Future<void> show(
    BuildContext context, {
    required List<Task> tasks,
    required List<String> categories,
  }) {
    AppHaptics.light();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExportBackupDialog(tasks: tasks, categories: categories),
    );
  }

  @override
  State<ExportBackupDialog> createState() => _ExportBackupDialogState();
}

class _ExportBackupDialogState extends State<ExportBackupDialog> {
  ExportFormat _selectedFormat = ExportFormat.json;

  @override
  Widget build(BuildContext context) {
    final backupCtrl = context.watch<BackupController>();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.accentYellow,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Экспорт и бэкап данных',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Сохраните или поделитесь задачами',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.labeltext),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Stats banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgmain,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Задач', value: '${widget.tasks.length}'),
                Container(width: 1, height: 24, color: Colors.white12),
                _StatItem(
                  label: 'Категорий',
                  value: '${widget.categories.length}',
                ),
                Container(width: 1, height: 24, color: Colors.white12),
                _StatItem(
                  label: 'Завершено',
                  value: '${widget.tasks.where((t) => t.isCompleted).length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Выберите формат экспорта:',
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          // Formats list
          ...ExportFormat.values.map((format) {
            final isSelected = _selectedFormat == format;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  AppHaptics.selection();
                  setState(() => _selectedFormat = format);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentYellow.withValues(alpha: 0.12)
                        : AppColors.bgmain,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentYellow
                          : Colors.white12,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _formatIcon(format),
                        color: isSelected
                            ? AppColors.accentYellow
                            : AppColors.labeltext,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              format.label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.accentYellow
                                    : AppColors.maintext,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDescription(format),
                              style: const TextStyle(
                                color: AppColors.labeltext,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? AppColors.accentYellow
                            : Colors.white24,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          // Feedback messages
          if (backupCtrl.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                backupCtrl.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          if (backupCtrl.successMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                backupCtrl.successMessage!,
                style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
              ),
            ),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: backupCtrl.isProcessing
                      ? null
                      : () async {
                          AppHaptics.light();
                          final res = await backupCtrl.exportTasks(
                            tasks: widget.tasks,
                            format: _selectedFormat,
                            categories: widget.categories,
                          );
                          if (res != null && context.mounted) {
                            await Clipboard.setData(
                              ClipboardData(text: res.content),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Содержимое скопировано в буфер обмена',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'Скопировать',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: backupCtrl.isProcessing
                      ? null
                      : () async {
                          AppHaptics.medium();
                          final navigator = Navigator.of(context);
                          final success = await backupCtrl.exportAndShare(
                            tasks: widget.tasks,
                            format: _selectedFormat,
                            categories: widget.categories,
                          );
                          if (success && mounted) {
                            navigator.pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: backupCtrl.isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Поделиться',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _formatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.data_object_rounded;
      case ExportFormat.csv:
        return Icons.table_chart_outlined;
      case ExportFormat.markdown:
        return Icons.description_outlined;
    }
  }

  String _formatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'Идеально для резервной копии и переноса на другое устройство';
      case ExportFormat.csv:
        return 'Удобно открыть в Excel, Apple Numbers или Google Таблицах';
      case ExportFormat.markdown:
        return 'Готовый список с чекбоксами для Notion, Obsidian и заметок';
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.maintext,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.labeltext, fontSize: 11),
        ),
      ],
    );
  }
}
