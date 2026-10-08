import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  @override
  void initState() {
    super.initState();
    // Load tasks after the first frame — widget tree is ready, Provider is live.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskController>().load();
    });
  }

  // Show errors as SnackBar so the UI stays usable (optimistic update already applied).
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

  Future<void> _confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('Удалить «${task.name}»?'),
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

    if (confirmed == true && mounted) {
      await context.read<TaskController>().delete(task.id);
    }
  }

  Future<void> _confirmSignOut() async {
    final user = context.read<AuthController>().currentUser;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Профиль'),
        content: Text(
          user != null
              ? 'Вы вошли как ${user.name}${user.email != null ? ' (${user.email})' : ''}.\nХотите выйти из аккаунта?'
              : 'Выйти из аккаунта?',
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
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthController>().signOut();
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      builder: (_) => const AddTaskSheet(),
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
              tooltip: 'Профиль / Выход',
              onPressed: _confirmSignOut,
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
            padding: const EdgeInsets.all(20),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                controller.tasks.isEmpty
                    ? const _EmptyState()
                    : _TaskList(
                        tasks: controller.tasks,
                        onDelete: _confirmDelete,
                      ),
                Positioned(
                  bottom: 0,
                  child: FloatingActionButton.large(
                    backgroundColor: AppColors.active,
                    onPressed: _openAddSheet,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.check_circle_outline, size: 80, color: AppColors.icons),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.onDelete});

  final List<Task> tasks;
  final void Function(Task) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final task = tasks[index];
        return TaskCard(task: task, onDelete: () => onDelete(task));
      },
    );
  }
}
