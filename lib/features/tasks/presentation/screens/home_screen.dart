import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_router/app_router_names.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/digest/presentation/controllers/daily_digest_controller.dart';
import 'package:todo/features/digest/presentation/widgets/daily_digest_card.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/presentation/controllers/sync_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/tasks/presentation/widgets/add_task_sheet.dart';
import 'package:todo/features/tasks/presentation/widgets/calendar_tab_view.dart';
import 'package:todo/features/tasks/presentation/widgets/create_category_dialog.dart';
import 'package:todo/features/tasks/presentation/widgets/eisenhower_matrix_view.dart';
import 'package:todo/features/tasks/presentation/widgets/focus_tab_view.dart';
import 'package:todo/features/tasks/presentation/widgets/profile_tab_view.dart';
import 'package:todo/features/tasks/presentation/widgets/task_card.dart';
import 'package:todo/features/voice/presentation/widgets/voice_input_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedTabIndex =
      0; // 0 = Задачи, 1 = Календарь, 2 = Фокус, 3 = Профиль

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TaskController>().load();
      if (mounted) {
        context.read<DailyDigestController>().loadDigest(
          context.read<TaskController>().tasks,
        );
        context.read<INotificationService>().registerQuickActionHandler(
          _handleQuickAction,
        );
      }
    });
  }

  Future<void> _openVoiceInputFlow() async {
    final draft = await VoiceInputModal.show(context);
    if (draft != null && mounted) {
      _openTaskSheet(
        initialTitle: draft.name,
        initialCategory: draft.category,
        initialPriorityIndex: draft.priorityIndex,
      );
    }
  }

  void _handleQuickAction(String actionType) {
    if (!mounted) return;
    AppHaptics.medium();

    if (actionType.startsWith('todo://') ||
        actionType.startsWith('todoapp://')) {
      final uri = Uri.tryParse(actionType);
      if (uri != null) {
        if (uri.host == 'tasks' || uri.path.contains('tasks')) {
          final title = uri.queryParameters['title'];
          final category = uri.queryParameters['category'];
          final prioStr = uri.queryParameters['priority'];
          final prio = prioStr != null ? int.tryParse(prioStr) : null;
          setState(() => _selectedTabIndex = 0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _openTaskSheet(
                initialTitle: title,
                initialCategory: category,
                initialPriorityIndex: prio,
              );
            }
          });
          return;
        } else if (uri.host == 'voice' || uri.path.contains('voice')) {
          _openVoiceInputFlow();
          return;
        } else if (uri.host == 'matrix' || uri.path.contains('matrix')) {
          setState(() => _selectedTabIndex = 0);
          context.read<TaskController>().toggleViewMode(true);
          return;
        } else if (uri.host == 'focus' || uri.path.contains('focus')) {
          setState(() => _selectedTabIndex = 2);
          return;
        } else if (uri.host == 'calendar' || uri.path.contains('calendar')) {
          setState(() => _selectedTabIndex = 1);
          return;
        }
      }
    }

    switch (actionType) {
      case 'add_task':
        setState(() => _selectedTabIndex = 0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openTaskSheet();
        });
      case 'voice_task':
        _openVoiceInputFlow();
      case 'open_focus':
        setState(() => _selectedTabIndex = 2);
      case 'open_calendar':
        setState(() => _selectedTabIndex = 1);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _listenErrors(BuildContext context, TaskController controller) {
    if (controller.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.error!),
            backgroundColor: Colors.red[700],
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: controller.clearError,
            ),
          ),
        );
        controller.clearError();
      });
    }
  }

  Future<bool?> _confirmDeleteDialog(Task task) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Удалить задачу?',
          style: TextStyle(color: AppColors.maintext),
        ),
        content: Text(
          'Удалить «${task.name}»?',
          style: TextStyle(color: AppColors.labeltext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptAddCategory() async {
    final created = await showDialog<TaskCategoryStyle>(
      context: context,
      builder: (_) => const CreateCategoryDialog(),
    );

    if (created != null && mounted) {
      await context.read<TaskController>().addCategory(
        created.name,
        iconIndex: created.iconIndex,
        colorIndex: created.colorIndex,
      );
    }
  }

  void _openTaskSheet({
    Task? task,
    String? initialTitle,
    String? initialCategory,
    int? initialPriorityIndex,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      builder: (_) => AddTaskSheet(
        initialTask: task,
        initialTitle: initialTitle,
        initialCategory: initialCategory,
        initialPriorityIndex: initialPriorityIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final displayName = (user != null && user.name.trim().isNotEmpty)
        ? user.name
        : 'Tasks';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: _selectedTabIndex == 0
            ? _ListodoHeaderTitle(name: displayName)
            : Text(
                switch (_selectedTabIndex) {
                  1 => 'Календарь задач',
                  2 => 'Режим фокуса',
                  _ => 'Мой профиль',
                },
                style: TextStyle(
                  color: AppColors.maintext,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          if (_selectedTabIndex == 0)
            Consumer<TaskController>(
              builder: (context, taskCtrl, _) {
                return IconButton(
                  tooltip: taskCtrl.isMatrixView
                      ? 'Вид: Список'
                      : 'Вид: Матрица Эйзенхауэра',
                  onPressed: () {
                    AppHaptics.selection();
                    taskCtrl.toggleViewMode();
                  },
                  icon: Icon(
                    taskCtrl.isMatrixView
                        ? Icons.view_agenda_rounded
                        : Icons.grid_view_rounded,
                    color: taskCtrl.isMatrixView
                        ? AppColors.active
                        : AppColors.icons,
                    size: 20,
                  ),
                );
              },
            ),
          _StreakHeaderBadge(
            onTap: () {
              AppHaptics.selection();
              setState(() => _selectedTabIndex = 3);
            },
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Настройки',
              onPressed: () {
                AppHaptics.selection();
                context.pushNamed(AppRouterNames.settings);
              },
              style: IconButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                shape: const CircleBorder(),
              ),
              icon: Icon(
                Icons.settings_outlined,
                color: AppColors.icons,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<TaskController>(
        builder: (context, controller, _) {
          _listenErrors(context, controller);

          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_selectedTabIndex == 1) {
            return CalendarTabView(
              confirmDismiss: _confirmDeleteDialog,
              onEditTask: (task) => _openTaskSheet(task: task),
            );
          }

          if (_selectedTabIndex == 2) {
            return const FocusTabView();
          }

          if (_selectedTabIndex == 3) {
            return const ProfileTabView();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const DailyDigestCard(),
                _ListodoSearchBar(
                  controller: _searchController,
                  onChanged: controller.setSearchQuery,
                ),
                const SizedBox(height: 16),
                _CategoryFilterRow(
                  categories: controller.categories,
                  selectedCategory: controller.selectedCategory,
                  onSelect: (category) {
                    AppHaptics.selection();
                    controller.selectCategory(category);
                  },
                  onAddCategory: _promptAddCategory,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: controller.tasks.isEmpty
                      ? const _EmptyState()
                      : controller.isMatrixView
                          ? EisenhowerMatrixView(
                              onEditTask: (task) => _openTaskSheet(task: task),
                            )
                          : _SectionedTaskList(
                          futureTasks: controller.futureTasks,
                          todayTasks: controller.todayTasks,
                          confirmDismiss: _confirmDeleteDialog,
                          onDelete: (task) {
                            AppHaptics.heavy();
                            controller.delete(task.id);
                          },
                          onArchive: (task) {
                            AppHaptics.heavy();
                            controller.archiveTask(task.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '«${task.name}» перемещена в архив профиля',
                                ),
                                action: SnackBarAction(
                                  label: 'Вернуть',
                                  textColor: AppColors.accentYellow,
                                  onPressed: () =>
                                      controller.unarchiveTask(task.id),
                                ),
                              ),
                            );
                          },
                          onToggleComplete: (task) {
                            AppHaptics.medium();
                            controller.toggleCompleted(task.id);
                          },
                          onEditTask: (task) {
                            AppHaptics.light();
                            _openTaskSheet(task: task);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _ListodoBottomBar(
        selectedIndex: _selectedTabIndex,
        onSelectTab: (idx) {
          AppHaptics.selection();
          setState(() => _selectedTabIndex = idx);
        },
        onAddTap: () {
          AppHaptics.medium();
          _openTaskSheet();
        },
      ),
    );
  }
}

class _ListodoBottomBar extends StatelessWidget {
  const _ListodoBottomBar({
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onAddTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onAddTap;

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_filled,
                label: 'Задачи',
                isSelected: selectedIndex == 0,
                onTap: () => onSelectTab(0),
              ),
              _BottomNavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Календарь',
                isSelected: selectedIndex == 1,
                onTap: () => onSelectTab(1),
              ),
              FloatingActionButton(
                heroTag: 'listodo_bottom_add_fab',
                backgroundColor: AppColors.active,
                elevation: 4,
                onPressed: onAddTap,
                child: const Icon(
                  CupertinoIcons.plus,
                  color: AppColors.white,
                  size: 26,
                ),
              ),
              _BottomNavItem(
                icon: Icons.timer_outlined,
                label: 'Фокус',
                isSelected: selectedIndex == 2,
                onTap: () => onSelectTab(2),
              ),
              _BottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Профиль',
                isSelected: selectedIndex == 3,
                onTap: () => onSelectTab(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.accentYellow : AppColors.labeltext;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListodoHeaderTitle extends StatelessWidget {
  const _ListodoHeaderTitle({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 44, top: 6),
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          top: -2,
          right: 0,
          child: Transform.rotate(
            angle: 12 * math.pi / 180,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'to-do',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListodoSearchBar extends StatelessWidget {
  const _ListodoSearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.icons, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: AppColors.maintext, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Try to find task....',
                hintStyle: TextStyle(color: AppColors.labeltext, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(controller.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.active,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                'Search',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
    required this.onAddCategory,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final allItems = [TaskController.allCategory, ...categories];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: onAddCategory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(Icons.add, color: AppColors.icons, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          ...allItems.map((category) {
            final isAll = category == TaskController.allCategory;
            final isSelected = selectedCategory == category;
            final style = isAll ? null : controller.styleForCategory(category);
            final activeColor = isAll ? AppColors.accentYellow : style!.color;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor
                        : (style != null
                              ? style.color.withValues(alpha: 0.1)
                              : Colors.transparent),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : (style != null
                                ? style.color.withValues(alpha: 0.4)
                                : AppColors.border),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (style != null) ...[
                        Icon(
                          style.icon,
                          size: 15,
                          color: isSelected ? Colors.black : style.color,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : (style != null
                                    ? AppColors.maintext
                                    : AppColors.labeltext),
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectionedTaskList extends StatelessWidget {
  const _SectionedTaskList({
    required this.futureTasks,
    required this.todayTasks,
    required this.confirmDismiss,
    required this.onDelete,
    required this.onArchive,
    required this.onToggleComplete,
    required this.onEditTask,
  });

  final List<Task> futureTasks;
  final List<Task> todayTasks;
  final Future<bool?> Function(Task) confirmDismiss;
  final void Function(Task) onDelete;
  final void Function(Task) onArchive;
  final void Function(Task) onToggleComplete;
  final void Function(Task) onEditTask;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.active,
      backgroundColor: AppColors.cardBg,
      onRefresh: () async {
        AppHaptics.light();
        await context.read<SyncController>().syncWithCloud();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          if (futureTasks.isNotEmpty) ...[
            Text(
              'Future',
              style: TextStyle(
                color: AppColors.maintext,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...futureTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskCard(
                  task: task,
                  confirmDismiss: () => confirmDismiss(task),
                  onDelete: () => onDelete(task),
                  onArchive: () => onArchive(task),
                  onToggleComplete: () => onToggleComplete(task),
                  onTap: () => onEditTask(task),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (todayTasks.isNotEmpty) ...[
            Text(
              'Today task',
              style: TextStyle(
                color: AppColors.maintext,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...todayTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskCard(
                  task: task,
                  confirmDismiss: () => confirmDismiss(task),
                  onDelete: () => onDelete(task),
                  onArchive: () => onArchive(task),
                  onToggleComplete: () => onToggleComplete(task),
                  onTap: () => onEditTask(task),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            'Нет задач по выбранному фильтру',
            style: TextStyle(color: AppColors.labeltext, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _StreakHeaderBadge extends StatelessWidget {
  const _StreakHeaderBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final streak = controller.currentStreakDays;
    final doneToday = controller.completedTodayCount > 0;
    final activeColor = doneToday
        ? const Color(0xFFFF8A00)
        : (streak > 0 ? AppColors.accentYellow : AppColors.labeltext);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: doneToday
              ? const Color(0xFFFF8A00).withValues(alpha: 0.16)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: doneToday
                ? const Color(0xFFFF8A00).withValues(alpha: 0.65)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: activeColor,
            ),
            const SizedBox(width: 4),
            Text(
              '$streak дн.',
              style: TextStyle(
                color: doneToday ? AppColors.white : activeColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
