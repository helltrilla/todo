import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

/// Listodo Profile & Settings screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _promptEditName(String currentName) async {
    final textController = TextEditingController(text: currentName);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Изменить имя',
          style: TextStyle(color: AppColors.maintext),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: AppColors.maintext),
          decoration: const InputDecoration(
            hintText: 'Введите ваше имя',
            hintStyle: TextStyle(color: AppColors.labeltext),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty && mounted) {
      await context.read<AuthController>().updateDisplayName(updated);
    }
  }

  Future<void> _promptAddCategory() async {
    final textController = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Новая категория',
          style: TextStyle(color: AppColors.maintext),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: AppColors.maintext),
          decoration: const InputDecoration(
            hintText: 'Например, Study или Fitness',
            hintStyle: TextStyle(color: AppColors.labeltext),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (created != null && created.isNotEmpty && mounted) {
      await context.read<TaskController>().addCategory(created);
    }
  }

  Future<void> _confirmClearCompleted(int count) async {
    if (count == 0) return;
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
      await context.read<TaskController>().clearCompleted();
    }
  }

  Future<void> _confirmSignOut() async {
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
      await context.read<AuthController>().signOut();
    }
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final taskController = context.watch<TaskController>();
    final user = authController.currentUser;

    final userName = (user != null && user.name.trim().isNotEmpty)
        ? user.name
        : 'User';
    final isCloud = !(user?.isLocal ?? true);
    final total = taskController.totalTasksCount;
    final completed = taskController.completedTasksCount;
    final pending = taskController.pendingTasksCount;
    final urgent = taskController.urgentPendingCount;
    final archivedTasks = taskController.archivedTasks;
    final progress = total > 0 ? completed / total : 0.0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              onTap: () => context.pop(),
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
                      'К задачам',
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
                'Профиль и настройки',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.maintext,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. User Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.active, Color(0xFF5E4AE3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppColors.accentYellow, width: 2),
                  ),
                  child: Text(
                    _initialsFor(userName),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.maintext,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _promptEditName(userName),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 17,
                                color: AppColors.accentYellow,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (user?.email != null && user!.email!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.email!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.labeltext,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCloud
                              ? AppColors.active.withValues(alpha: 0.18)
                              : AppColors.accentYellow.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCloud
                                  ? Icons.cloud_done_outlined
                                  : Icons.phone_iphone_outlined,
                              size: 13,
                              color: isCloud
                                  ? AppColors.active
                                  : AppColors.accentYellow,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isCloud ? 'Supabase Cloud' : 'Локальный профиль',
                              style: TextStyle(
                                color: isCloud
                                    ? AppColors.active
                                    : AppColors.accentYellow,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Task Statistics Dashboard
          const Text(
            'Статистика задач',
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatMetricCard(
                  label: 'В работе',
                  value: '$pending',
                  icon: Icons.pending_actions_outlined,
                  accentColor: AppColors.active,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatMetricCard(
                  label: 'Выполнено',
                  value: '$completed',
                  icon: Icons.task_alt_rounded,
                  accentColor: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatMetricCard(
                  label: 'Срочно 🔥',
                  value: '$urgent',
                  icon: Icons.local_fire_department_rounded,
                  accentColor: const Color(0xFFFF4D4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Прогресс выполнения',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}% ($completed из $total)',
                      style: const TextStyle(
                        color: AppColors.accentYellow,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentYellow,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Archive of right-swiped completed tasks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Архив выполненных',
                style: TextStyle(
                  color: AppColors.maintext,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${archivedTasks.length}',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: archivedTasks.isEmpty
                ? const Row(
                    children: [
                      Icon(
                        Icons.swipe_right_outlined,
                        color: AppColors.labeltext,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Свайпните выполненную задачу вправо на главном экране, чтобы убрать её в этот архив.',
                          style: TextStyle(
                            color: AppColors.labeltext,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: archivedTasks
                        .map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ArchivedTaskRow(
                              task: task,
                              onRestore: () =>
                                  taskController.unarchiveTask(task.id),
                              onDelete: () => taskController.delete(task.id),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),

          const SizedBox(height: 24),

          // 4. Categories Management
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Мои категории',
                style: TextStyle(
                  color: AppColors.maintext,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: _promptAddCategory,
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: AppColors.accentYellow,
                ),
                label: const Text(
                  'Добавить',
                  style: TextStyle(
                    color: AppColors.accentYellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Fixed Global category chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentYellow.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public,
                        size: 14,
                        color: AppColors.accentYellow,
                      ),
                      SizedBox(width: 6),
                      Text(
                        TaskController.globalCategory,
                        style: TextStyle(
                          color: AppColors.accentYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // User categories with delete button
                ...taskController.categories.map(
                  (cat) => Container(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 6,
                      top: 6,
                      bottom: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat,
                          style: const TextStyle(
                            color: AppColors.maintext,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => taskController.removeCategory(cat),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.labeltext,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 5. Quick Actions
          const Text(
            'Управление',
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
            icon: Icons.logout_rounded,
            title: 'Выйти из аккаунта',
            subtitle: 'Вернуться на экран приветствия',
            iconColor: Colors.redAccent,
            onTap: _confirmSignOut,
          ),
          const SizedBox(height: 16),

          // 6. Prominent Return to Home Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.active,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text(
                'Вернуться к списку задач',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _ArchivedTaskRow extends StatelessWidget {
  const _ArchivedTaskRow({
    required this.task,
    required this.onRestore,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: const TextStyle(
                    color: AppColors.maintext,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                if (task.category.isNotEmpty)
                  Text(
                    task.category,
                    style: const TextStyle(
                      color: AppColors.labeltext,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Вернуть на главный экран',
            onPressed: onRestore,
            icon: const Icon(
              Icons.unarchive_outlined,
              color: AppColors.accentYellow,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: 'Удалить навсегда',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  const _StatMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.maintext,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.labeltext, fontSize: 11),
          ),
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
