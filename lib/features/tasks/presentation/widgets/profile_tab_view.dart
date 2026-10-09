import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:todo/features/productivity/presentation/widgets/category_donut_chart_card.dart';
import 'package:todo/features/productivity/presentation/widgets/github_heatmap_card.dart';
import 'package:todo/features/productivity/presentation/widgets/pomodoro_analytics_card.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/tasks/presentation/widgets/create_category_dialog.dart';

/// Dedicated Profile tab view showing user card, profile settings sheet
/// (photo + nickname), task statistics, categories, and archive.
class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final tasks = context.read<TaskController>().tasks;
        context.read<ProductivityController>().computeDashboard(tasks);
      }
    });
  }

  Future<void> _openProfileSettingsSheet({
    required String currentName,
    required String? currentAvatarBase64,
  }) async {
    AppHaptics.light();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProfileSettingsSheet(
        initialName: currentName,
        initialAvatarBase64: currentAvatarBase64,
      ),
    );
  }

  Future<void> _openArchiveSheet() async {
    AppHaptics.light();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ArchivedTasksSheet(),
    );
  }

  Future<void> _promptAddCategory() async {
    AppHaptics.light();
    final created = await showDialog<TaskCategoryStyle>(
      context: context,
      builder: (_) => const CreateCategoryDialog(),
    );

    if (created != null && mounted) {
      AppHaptics.medium();
      await context.read<TaskController>().addCategory(
        created.name,
        iconIndex: created.iconIndex,
        colorIndex: created.colorIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final taskController = context.watch<TaskController>();
    final prodController = context.watch<ProductivityController>();
    final dashboard = prodController.dashboard;
    final user = authController.currentUser;

    final userName = (user != null && user.name.trim().isNotEmpty)
        ? user.name
        : 'User';
    final avatarBase64 = user?.avatarBase64;
    final isCloud = !(user?.isLocal ?? true);
    final total = taskController.totalTasksCount;
    final completed = taskController.completedTasksCount;
    final pending = taskController.pendingTasksCount;
    final urgent = taskController.urgentPendingCount;
    final archivedTasks = taskController.archivedTasks;
    final progress = total > 0 ? completed / total : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
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
              GestureDetector(
                onTap: () => _openProfileSettingsSheet(
                  currentName: userName,
                  currentAvatarBase64: avatarBase64,
                ),
                child: _UserAvatarCircle(
                  name: userName,
                  avatarBase64: avatarBase64,
                  size: 66,
                  showCameraBadge: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.maintext,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
              IconButton(
                tooltip: 'Настройка профиля',
                onPressed: () => _openProfileSettingsSheet(
                  currentName: userName,
                  currentAvatarBase64: avatarBase64,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.bgmain.withValues(alpha: 0.65),
                  side: const BorderSide(color: Colors.white12),
                ),
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.accentYellow,
                  size: 20,
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
        const SizedBox(height: 12),
        _ProductivityStreakCard(taskController: taskController),
        const SizedBox(height: 14),

        // GitHub-Style Activity Heatmap
        if (dashboard.heatmapDays.isNotEmpty) ...[
          GithubHeatmapCard(
            heatmapDays: dashboard.heatmapDays,
            selectedDay: prodController.selectedDay,
            onDaySelected: prodController.selectDay,
            currentStreak: dashboard.currentStreak,
            bestStreak: dashboard.bestStreak,
          ),
          const SizedBox(height: 14),
        ],

        // Pomodoro Infographic Analytics
        if (dashboard.totalPomodoroSessions > 0 ||
            dashboard.totalFocusMinutes > 0) ...[
          PomodoroAnalyticsCard(
            totalSessions: dashboard.totalPomodoroSessions,
            totalFocusMinutes: dashboard.totalFocusMinutes,
            todayFocusMinutes: dashboard.todayFocusMinutes,
            weekFocusMinutes: dashboard.weekFocusMinutes,
          ),
          const SizedBox(height: 14),
        ],

        // Category & Priority Donut Chart
        if (dashboard.categoryStats.isNotEmpty) ...[
          CategoryDonutChartCard(
            categoryStats: dashboard.categoryStats,
            priorityStats: dashboard.priorityStats,
            totalTasks: dashboard.totalTasks,
            completionRate: dashboard.completionRate,
          ),
          const SizedBox(height: 14),
        ],

        const SizedBox(height: 10),

        // 3. Categories Management
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
                    Icon(Icons.public, size: 14, color: AppColors.accentYellow),
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
              ...taskController.categories.map((cat) {
                final style = taskController.styleForCategory(cat);
                return Container(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 6,
                    top: 6,
                    bottom: 6,
                  ),
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: style.color.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 14, color: style.color),
                      const SizedBox(width: 6),
                      Text(
                        cat,
                        style: TextStyle(
                          color: style.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          AppHaptics.light();
                          taskController.removeCategory(cat);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: style.color.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 4. Compact Archive Card (opens searchable modal sheet)
        Material(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: _openArchiveSheet,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF4CAF50),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Архив выполненных',
                          style: TextStyle(
                            color: AppColors.maintext,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          archivedTasks.isEmpty
                              ? 'Пока пусто • свайпните выполненную задачу вправо'
                              : 'Нажмите, чтобы открыть список и поиск по архиву',
                          style: const TextStyle(
                            color: AppColors.labeltext,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${archivedTasks.length}',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.labeltext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArchivedTasksSheet extends StatefulWidget {
  const _ArchivedTasksSheet();

  @override
  State<_ArchivedTasksSheet> createState() => _ArchivedTasksSheetState();
}

class _ArchivedTasksSheetState extends State<_ArchivedTasksSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final allArchived = taskController.archivedTasks;
    final cleanQuery = _query.trim().toLowerCase();
    final filtered = cleanQuery.isEmpty
        ? allArchived
        : allArchived.where((t) {
            return t.name.toLowerCase().contains(cleanQuery) ||
                t.value.toLowerCase().contains(cleanQuery) ||
                t.category.toLowerCase().contains(cleanQuery);
          }).toList();

    return DraggableScrollableSheet(
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
                  Icons.inventory_2_outlined,
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Архив выполненных',
                    style: TextStyle(
                      color: AppColors.maintext,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allArchived.length}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.labeltext),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.maintext, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Поиск в архиве по названию или категории...',
                hintStyle: const TextStyle(
                  color: AppColors.labeltext,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.labeltext,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.labeltext,
                          size: 18,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgmain,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.active),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: allArchived.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swipe_right_outlined,
                              color: Colors.white24,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'В архиве пока нет задач.\nСвайпните выполненную задачу вправо на главном экране, чтобы переместить её сюда.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.labeltext,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Ничего не найдено по вашему запросу',
                        style: TextStyle(
                          color: AppColors.labeltext,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        return _ArchivedTaskRow(
                          task: task,
                          onRestore: () {
                            AppHaptics.medium();
                            taskController.unarchiveTask(task.id);
                          },
                          onDelete: () {
                            AppHaptics.heavy();
                            taskController.delete(task.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatarCircle extends StatelessWidget {
  const _UserAvatarCircle({
    required this.name,
    required this.avatarBase64,
    required this.size,
    this.showCameraBadge = false,
  });

  final String name;
  final String? avatarBase64;
  final double size;
  final bool showCameraBadge;

  String _initialsFor(String input) {
    final parts = input.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Uint8List? _decodeAvatar(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeAvatar(avatarBase64);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: bytes == null
                ? const LinearGradient(
                    colors: [AppColors.active, Color(0xFF5E4AE3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            image: bytes != null
                ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                : null,
            border: Border.all(color: AppColors.accentYellow, width: 2),
          ),
          child: bytes == null
              ? Text(
                  _initialsFor(name),
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        if (showCameraBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBg, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 13,
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileSettingsSheet extends StatefulWidget {
  const _ProfileSettingsSheet({
    required this.initialName,
    required this.initialAvatarBase64,
  });

  final String initialName;
  final String? initialAvatarBase64;

  @override
  State<_ProfileSettingsSheet> createState() => _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends State<_ProfileSettingsSheet> {
  late final TextEditingController _nameController;
  String? _avatarBase64;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _avatarBase64 = widget.initialAvatarBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    AppHaptics.selection();
    final pickedBase64 = await NotificationService.instance.pickProfileImage();
    if (pickedBase64 != null && pickedBase64.isNotEmpty && mounted) {
      AppHaptics.medium();
      setState(() => _avatarBase64 = pickedBase64);
    }
  }

  void _removePhoto() {
    AppHaptics.light();
    setState(() => _avatarBase64 = null);
  }

  Future<void> _saveProfile() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) return;

    setState(() => _isSaving = true);
    AppHaptics.medium();
    final authCtrl = context.read<AuthController>();
    await authCtrl.updateDisplayName(trimmedName);
    await authCtrl.updateAvatar(_avatarBase64);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.manage_accounts_outlined,
                color: AppColors.accentYellow,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Настройка профиля',
                  style: TextStyle(
                    color: AppColors.maintext,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.labeltext),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Avatar preview + photo picker buttons
          GestureDetector(
            onTap: _pickPhoto,
            child: _UserAvatarCircle(
              name: _nameController.text.isEmpty
                  ? widget.initialName
                  : _nameController.text,
              avatarBase64: _avatarBase64,
              size: 92,
              showCameraBadge: true,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentYellow,
                  side: const BorderSide(color: AppColors.accentYellow),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Выбрать фото'),
              ),
              if (_avatarBase64 != null && _avatarBase64!.isNotEmpty)
                TextButton.icon(
                  onPressed: _removePhoto,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Убрать фото'),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Nickname input
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Никнейм профиля',
              style: TextStyle(
                color: AppColors.labeltext,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppColors.maintext, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Введите ваше имя',
              hintStyle: const TextStyle(color: AppColors.labeltext),
              filled: true,
              fillColor: AppColors.bgmain,
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: AppColors.accentYellow,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.active),
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.active,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(
                'Сохранить изменения',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
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

class _ProductivityStreakCard extends StatelessWidget {
  const _ProductivityStreakCard({required this.taskController});

  final TaskController taskController;

  static const List<String> _weekdayShort = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  @override
  Widget build(BuildContext context) {
    final streak = taskController.currentStreakDays;
    final best = taskController.bestStreakDays;
    final doneToday = taskController.completedTodayCount;
    final strip = taskController.last7DaysStreakStrip;
    final isLitToday = doneToday > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLitToday
              ? const Color(0xFFFF8A00).withValues(alpha: 0.45)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLitToday
                      ? const Color(0xFFFF8A00).withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: isLitToday
                      ? const Color(0xFFFF8A00)
                      : AppColors.labeltext,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Стрик: $streak дн. подряд',
                      style: const TextStyle(
                        color: AppColors.maintext,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLitToday
                          ? 'Сегодня выполнено задач: $doneToday'
                          : 'Выполни 1 задачу сегодня, чтобы продлить серию',
                      style: const TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Рекорд: $best',
                  style: const TextStyle(
                    color: AppColors.accentYellow,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: strip.map((entry) {
              final day = entry.$1;
              final active = entry.$2;
              final label = _weekdayShort[day.weekday - 1];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.labeltext,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? const Color(0xFFFF8A00).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: active
                            ? const Color(0xFFFF8A00)
                            : Colors.white12,
                        width: active ? 1.5 : 1.0,
                      ),
                    ),
                    child: Icon(
                      active
                          ? Icons.local_fire_department_rounded
                          : Icons.circle,
                      size: active ? 16 : 6,
                      color: active ? const Color(0xFFFF8A00) : Colors.white24,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
