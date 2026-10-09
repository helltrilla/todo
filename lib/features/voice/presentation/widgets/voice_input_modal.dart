import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/voice/presentation/controllers/voice_task_controller.dart';

/// Interactive modal sheet with real-time waveform visualizer for speech-to-text task creation.
class VoiceInputModal extends StatefulWidget {
  const VoiceInputModal({super.key});

  static Future<SmartTaskDraft?> show(BuildContext context) {
    AppHaptics.heavy();
    return showModalBottomSheet<SmartTaskDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VoiceInputModal(),
    );
  }

  @override
  State<VoiceInputModal> createState() => _VoiceInputModalState();
}

class _VoiceInputModalState extends State<VoiceInputModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskController = context.read<TaskController>();
      final voiceController = context.read<VoiceTaskController>();
      voiceController.startListening(
        availableCategories: taskController.categories,
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceController = context.watch<VoiceTaskController>();
    final status = voiceController.status;

    // When voice NLP processing finishes, return draft to caller
    if (status == VoiceTaskStatus.completed && voiceController.draft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppHaptics.heavy();
          final draft = voiceController.draft;
          voiceController.reset();
          Navigator.of(context).pop(draft);
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _buildVisualizer(voiceController),
          const SizedBox(height: 18),
          _buildStatusHeader(status),
          const SizedBox(height: 14),
          _buildTranscriptBox(voiceController),
          const SizedBox(height: 20),
          _buildActionButtons(voiceController),
        ],
      ),
    );
  }

  Widget _buildVisualizer(VoiceTaskController controller) {
    final isListening = controller.isListening;
    final isProcessing = controller.isProcessing;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isListening
            ? 1.0 +
                  (_pulseAnimation.value * 0.18) +
                  (controller.soundLevelDb.clamp(0, 10) * 0.03)
            : 1.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (isListening)
              Container(
                width: 100 * scale,
                height: 100 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8687E7).withValues(alpha: 0.2),
                ),
              ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8687E7), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8687E7).withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: isProcessing
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.mic_fill,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusHeader(VoiceTaskStatus status) {
    String text;
    Color color;

    switch (status) {
      case VoiceTaskStatus.initializing:
        text = 'Подготовка микрофона...';
        color = AppColors.labeltext;
        break;
      case VoiceTaskStatus.listening:
        text = 'Слушаю... Говорите свободно';
        color = const Color(0xFF3ECF8E);
        break;
      case VoiceTaskStatus.processingNlp:
        text = 'ИИ раскладывает задачу по полочкам...';
        color = const Color(0xFF8687E7);
        break;
      case VoiceTaskStatus.completed:
        text = 'Задача сформирована!';
        color = const Color(0xFF3ECF8E);
        break;
      case VoiceTaskStatus.error:
        text = 'Ошибка записи';
        color = Colors.redAccent;
        break;
      case VoiceTaskStatus.idle:
        text = 'Нажмите, чтобы начать';
        color = AppColors.maintext;
        break;
    }

    return Text(
      text,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTranscriptBox(VoiceTaskController controller) {
    final text = controller.transcript;
    final hasError = controller.errorMessage != null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 80, maxHeight: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgmain,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Colors.redAccent.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: SingleChildScrollView(
        child: Text(
          hasError
              ? controller.errorMessage!
              : (text.isNotEmpty
                    ? text
                    : 'Например: «мне в шарагу через 3 часа и успеть похавать до этого и напомнить за час»'),
          style: TextStyle(
            color: hasError
                ? Colors.redAccent
                : (text.isNotEmpty ? AppColors.maintext : AppColors.labeltext),
            fontSize: 14,
            height: 1.4,
            fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionButtons(VoiceTaskController controller) {
    final isListening = controller.isListening;
    final isProcessing = controller.isProcessing;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              AppHaptics.selection();
              controller.cancel();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppColors.labeltext,
            ),
            child: const Text('Отмена', style: TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isProcessing
                ? null
                : (isListening
                      ? () {
                          AppHaptics.medium();
                          controller.stopAndProcess();
                        }
                      : () {
                          AppHaptics.medium();
                          final taskController = context.read<TaskController>();
                          controller.startListening(
                            availableCategories: taskController.categories,
                          );
                        }),
            style: ElevatedButton.styleFrom(
              backgroundColor: isListening
                  ? const Color(0xFF3ECF8E)
                  : const Color(0xFF8687E7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: Icon(
              isListening ? Icons.done_rounded : Icons.mic_rounded,
              size: 20,
            ),
            label: Text(
              isListening ? 'Готово (Разобрать)' : 'Начать запись',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
