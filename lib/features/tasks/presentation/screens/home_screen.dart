import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_router/app_router_names.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/tasks/presentation/widgets/add_task_sheet.dart';
import 'package:todo/features/tasks/presentation/widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskController>().load();
    });
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
        title: const Text(
          'Удалить задачу?',
          style: TextStyle(color: AppColors.maintext),
        ),
        content: Text(
          'Удалить «${task.name}»?',
          style: const TextStyle(color: AppColors.labeltext),
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

  void _openTaskSheet({Task? task}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      builder: (_) => AddTaskSheet(initialTask: task),
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
        title: _ListodoHeaderTitle(name: displayName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Профиль и настройки',
              onPressed: () => context.pushNamed(AppRouterNames.settings),
              style: IconButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: const CircleBorder(),
              ),
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.white,
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

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _ListodoSearchBar(
                      controller: _searchController,
                      onChanged: controller.setSearchQuery,
                    ),
                    const SizedBox(height: 16),
                    _CategoryFilterRow(
                      categories: controller.categories,
                      selectedCategory: controller.selectedCategory,
                      onSelect: controller.selectCategory,
                      onAddCategory: _promptAddCategory,
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: controller.tasks.isEmpty
                          ? const _EmptyState()
                          : _SectionedTaskList(
                              futureTasks: controller.futureTasks,
                              todayTasks: controller.todayTasks,
                              confirmDismiss: _confirmDeleteDialog,
                              onDelete: (task) => controller.delete(task.id),
                              onArchive: (task) {
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
                              onToggleComplete: (task) =>
                                  controller.toggleCompleted(task.id),
                              onEditTask: (task) => _openTaskSheet(task: task),
                            ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  child: FloatingActionButton.large(
                    backgroundColor: AppColors.active,
                    onPressed: () => _openTaskSheet(),
                    child: const Icon(
                      CupertinoIcons.plus,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
            style: const TextStyle(
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
        color: AppColors.bgmain,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.maintext, fontSize: 14),
              decoration: const InputDecoration(
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
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.add, color: AppColors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          ...allItems.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentYellow
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentYellow
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.black : AppColors.labeltext,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
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
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        if (futureTasks.isNotEmpty) ...[
          const Text(
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
          const Text(
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'Нет задач по выбранному фильтру',
            style: TextStyle(color: AppColors.labeltext, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
