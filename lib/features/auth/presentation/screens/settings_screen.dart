import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

/// Dedicated Settings screen (notifications, haptics, data management, privacy, account).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _privacyPolicyUrl =
      'https://github.com/helltrilla/todo/blob/main/PRIVACY_POLICY.md';

  Future<void> _confirmClearCompleted(int count) async {
    if (count == 0) return;
    AppHaptics.light();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Очистить выполненные?',
          style: TextStyle(color: AppColors.maintext),
        ),
        content: Text(
          'Будет удалено выполненных задач: $count.',
          style: const TextStyle(color: AppColors.labeltext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AppHaptics.heavy();
      await context.read<TaskController>().clearCompleted();
    }
  }

  Future<void> _confirmClearAllTasks(int totalCount) async {
    if (totalCount == 0) return;
    AppHaptics.light();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Сбросить все задачи?',
          style: TextStyle(color: AppColors.maintext),
        ),
        content: Text(
          'Все задачи ($totalCount) и архив будут очищены, но ваш профиль останется активным.',
          style: const TextStyle(color: AppColors.labeltext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Очистить всё'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AppHaptics.heavy();
      await context.read<TaskController>().clearAllTasks();
    }
  }

  Future<void> _confirmSignOut() async {
    AppHaptics.light();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Выход из аккаунта',
          style: TextStyle(color: AppColors.maintext),
        ),
        content: const Text(
          'Вы уверены, что хотите выйти из текущего профиля?',
          style: TextStyle(color: AppColors.labeltext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AppHaptics.heavy();
      await context.read<AuthController>().signOut();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    AppHaptics.light();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Удалить аккаунт и данные?',
          style: TextStyle(color: AppColors.maintext),
        ),
        content: const Text(
          'Ваш профиль и все созданные задачи будут безвозвратно удалены с этого устройства. Это действие нельзя отменить.',
          style: TextStyle(color: AppColors.labeltext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AppHaptics.heavy();
      final taskCtrl = context.read<TaskController>();
      final authCtrl = context.read<AuthController>();
      await taskCtrl.clearAllTasks();
      await authCtrl.deleteAccount();
    }
  }

  Future<void> _showPrivacyPolicySheet() async {
    AppHaptics.light();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.active,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Политика конфиденциальности',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.labeltext),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    SizedBox(height: 8),
                    Text(
                      '1. Хранение задач и категорий',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Все ваши задачи, подзадачи, категории и настройки таймера хранятся локально на вашем устройстве и не передаются третьим лицам.',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      '2. Авторизация по Email (Supabase OTP)',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'При выборе входа по Email ваш адрес электронной почты используется исключительно для отправки одноразового 6-значного кода подтверждения (OTP) через Supabase Auth. Мы не рассылаем спам и не передаём ваш Email рекламным сервисам.',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      '3. Удаление аккаунта и данных',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Вы можете в любой момент полностью удалить свой профиль и все сохранённые задачи прямо в приложении в разделе «Настройки» → «Удалить аккаунт и данные».',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      '4. Контакты разработчика',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Email: helltrilla66@gmail.com\nTelegram: @helltrilla66',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                      const ClipboardData(text: _privacyPolicyUrl),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Ссылка на политику конфиденциальности скопирована',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: const Text('Скопировать ссылку на документ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final completed = taskController.completedTasksCount;
    final total = taskController.totalTasksCount;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              onTap: () {
                AppHaptics.selection();
                context.pop();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: AppColors.accentYellow,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Назад',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Настройки',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.maintext,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        children: [
          // 1. Notifications & Tactile Haptics
          const Text(
            'Уведомления и отклик',
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.notifications_active_outlined,
            title: 'Проверить Push-уведомление',
            subtitle: 'Отправить тестовое уведомление через 2 секунды',
            iconColor: const Color(0xFF4CAF50),
            onTap: () async {
              AppHaptics.medium();
              final messenger = ScaffoldMessenger.of(context);
              final ok = await NotificationService.instance
                  .sendTestNotification();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Тестовое уведомление отправлено! (придёт через 2 сек)'
                        : 'Разрешите уведомления для TodoApp в настройках телефона',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.vibration_rounded,
                    color: AppColors.accentYellow,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Тактильная вибрация (Haptics)',
                        style: TextStyle(
                          color: AppColors.maintext,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Отклик Taptic Engine при кликах и прокрутке времени',
                        style: TextStyle(
                          color: AppColors.labeltext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: AppHaptics.enabled,
                  activeTrackColor: AppColors.active,
                  onChanged: (val) {
                    setState(() => AppHaptics.enabled = val);
                    if (val) AppHaptics.medium();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Data & Tasks Management
          const Text(
            'Управление данными',
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.cleaning_services_outlined,
            title: 'Очистить выполненные задачи',
            subtitle: completed > 0
                ? 'Удалить завершённые задачи ($completed)'
                : 'Нет выполненных задач',
            iconColor: AppColors.accentYellow,
            onTap: completed > 0
                ? () => _confirmClearCompleted(completed)
                : null,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.layers_clear_outlined,
            title: 'Сбросить все задачи',
            subtitle: total > 0
                ? 'Удалить все задачи и архив ($total)'
                : 'Список задач пуст',
            iconColor: Colors.orangeAccent,
            onTap: total > 0 ? () => _confirmClearAllTasks(total) : null,
          ),

          const SizedBox(height: 24),

          // 3. Account & Security
          const Text(
            'Аккаунт и безопасность',
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Политика конфиденциальности',
            subtitle: 'Условия хранения данных и конфиденциальность',
            iconColor: const Color(0xFF00BCD4),
            onTap: _showPrivacyPolicySheet,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.logout_rounded,
            title: 'Выйти из аккаунта',
            subtitle: 'Вернуться на экран приветствия',
            iconColor: Colors.orangeAccent,
            onTap: _confirmSignOut,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.delete_forever_outlined,
            title: 'Удалить аккаунт и данные',
            subtitle: 'Безвозвратно удалить профиль и все задачи',
            iconColor: Colors.redAccent,
            onTap: _confirmDeleteAccount,
          ),

          const SizedBox(height: 24),

          // 4. App Info Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  color: AppColors.accentYellow,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Совет: зажмите иконку TodoApp на домашнем экране телефона для быстрого создания задачи или запуска Фокуса.',
                    style: TextStyle(color: AppColors.labeltext, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.maintext,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.labeltext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.labeltext,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
