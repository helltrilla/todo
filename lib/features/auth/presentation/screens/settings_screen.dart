import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_color_palette.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/app_theme/app_theme_mode.dart';
import 'package:todo/core/app_theme/theme_controller.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/localization/app_language.dart';
import 'package:todo/core/localization/app_localizations.dart';
import 'package:todo/core/localization/locale_controller.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/tasks/domain/services/i_smart_task_parser.dart';
import 'package:todo/features/tasks/presentation/controllers/sync_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

/// Dedicated Settings screen (appearance & theme, language, notifications, haptics, data management, privacy, account).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _privacyPolicyUrl =
      'https://github.com/helltrilla/todo/blob/main/PRIVACY_POLICY.md';

  Future<void> _showLanguagePickerSheet() async {
    AppHaptics.selection();
    final localeCtrl = context.read<LocaleController>();
    final currentLang = localeCtrl.currentLanguage;
    final tr = context.tr;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      color: AppColors.active,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr.selectLanguage,
                        style: TextStyle(
                          color: AppColors.maintext,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: Icon(Icons.close, color: AppColors.labeltext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                ...AppLanguage.values.map((lang) {
                  final isSelected = lang == currentLang;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? AppColors.active.withValues(alpha: 0.16)
                          : AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          AppHaptics.medium();
                          localeCtrl.setLanguage(lang);
                          Navigator.pop(sheetCtx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.active
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                lang.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.nativeName,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.active
                                            : AppColors.maintext,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lang.englishName,
                                      style: TextStyle(
                                        color: AppColors.labeltext,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.active,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmClearCompleted(int count) async {
    if (count == 0) return;
    AppHaptics.light();
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tr.clearCompletedConfirmTitle,
          style: TextStyle(color: AppColors.maintext),
        ),
        content: Text(
          tr.clearCompletedConfirmMsg(count),
          style: TextStyle(color: AppColors.labeltext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(tr.clear),
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
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tr.resetAllTasksConfirmTitle,
          style: TextStyle(color: AppColors.maintext),
        ),
        content: Text(
          tr.resetAllTasksConfirmMsg(totalCount),
          style: TextStyle(color: AppColors.labeltext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(tr.clearAll),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AppHaptics.heavy();
      await context.read<TaskController>().clearAllTasks();
    }
  }

  Future<void> _showAiApiKeyDialog() async {
    AppHaptics.light();
    final tr = context.tr;
    final parser = context.read<ISmartTaskParser>();
    final currentKey = parser.getGeminiApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tr.aiSettingsTitle,
          style: TextStyle(color: AppColors.maintext),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Для глубокого понимания задач используется Google Gemini Flash. Если ключ не указан — работает встроенный офлайн-парсер.',
              style: TextStyle(color: AppColors.labeltext, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: AppColors.maintext, fontSize: 13),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr.aiApiKeyLabel,
                hintText: 'AIzaSy...',
                labelStyle: TextStyle(
                  color: AppColors.labeltext,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (currentKey.isNotEmpty)
            TextButton(
              onPressed: () async {
                await parser.setGeminiApiKey(null);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Сбросить ключ'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await parser.setGeminiApiKey(controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8687E7),
              foregroundColor: Colors.white,
            ),
            child: Text(tr.save),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      AppHaptics.heavy();
      setState(() {});
    }
  }

  Future<void> _confirmSignOut() async {
    AppHaptics.light();
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tr.signOutConfirmTitle,
          style: TextStyle(color: AppColors.maintext),
        ),
        content: Text(
          tr.signOutConfirmMsg,
          style: TextStyle(color: AppColors.labeltext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
            child: Text(tr.exit),
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
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tr.deleteAccountConfirmTitle,
          style: TextStyle(color: AppColors.maintext),
        ),
        content: Text(
          tr.deleteAccountConfirmMsg,
          style: TextStyle(color: AppColors.labeltext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(tr.deleteForever),
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
    final tr = context.tr;
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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.active,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr.privacyPolicy,
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: AppColors.labeltext),
                  ),
                ],
              ),
              Divider(color: AppColors.divider),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      '1. Data Storage & Privacy',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All your tasks, subtasks, categories, and timer settings are stored securely on your device.',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '2. Email Authentication (Supabase OTP)',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your email address is only used to send a one-time 6-digit confirmation code. We never send spam or share your email.',
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
                child: OutlinedButton.icon(
                  onPressed: () async {
                    AppHaptics.medium();
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                      const ClipboardData(text: _privacyPolicyUrl),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    messenger.showSnackBar(
                      SnackBar(content: Text(tr.privacyLinkCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: Text(tr.copyPrivacyLink),
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
    final tr = context.tr;
    final taskController = context.watch<TaskController>();
    final syncController = context.watch<SyncController>();
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final authController = context.watch<AuthController>();
    final currentUser = authController.currentUser;

    final completed = taskController.completedTasksCount;
    final total = taskController.totalTasksCount;
    final currentTheme = themeController.mode;
    final currentLang = localeController.currentLanguage;

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        backgroundColor: AppColors.bgmain,
        elevation: 0,
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
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: AppColors.accentYellow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr.back,
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
            Expanded(
              child: Text(
                tr.settings,
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
          // 1. Appearance & Theme (Смена темы)
          Text(
            tr.appearanceAndTheme,
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.active.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        color: AppColors.active,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.theme,
                            style: TextStyle(
                              color: AppColors.maintext,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr.themeSubtitle,
                            style: TextStyle(
                              color: AppColors.labeltext,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Theme Mode Selector Grid (Light, Dark, Midnight, System)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: AppThemeMode.values.map((mode) {
                        final isSelected = currentTheme == mode;
                        final label = switch (mode) {
                          AppThemeMode.dark => tr.themeDark,
                          AppThemeMode.light => tr.themeLight,
                          AppThemeMode.midnight => tr.themeMidnight,
                          AppThemeMode.system => tr.themeSystem,
                        };

                        return SizedBox(
                          width: itemWidth,
                          child: Material(
                            color: isSelected
                                ? AppColors.active.withValues(alpha: 0.16)
                                : AppColors.bg,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () {
                                AppHaptics.selection();
                                themeController.setThemeMode(mode);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.active
                                        : AppColors.border,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      mode.icon,
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.active
                                          : AppColors.labeltext,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        label,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.active
                                              : AppColors.maintext,
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.active,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Divider(color: AppColors.border),
                const SizedBox(height: 16),
                // Accent Color Palette Selector (Палитра красок)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: themeController.palette.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.color_lens_outlined,
                        color: themeController.palette.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentLang.code == 'ru'
                                ? 'Палитра акцентов'
                                : 'Accent Color Palette',
                            style: TextStyle(
                              color: AppColors.maintext,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentLang.code == 'ru'
                                ? 'Выберите цвет кнопок, бейджей и акцентов'
                                : 'Choose primary color for buttons and highlights',
                            style: TextStyle(
                              color: AppColors.labeltext,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppColorPalette.values.map((palette) {
                      final isSelected = themeController.palette == palette;
                      final paletteName =
                          palette.localizedName(currentLang.code);

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.selection();
                            themeController.setPalette(palette);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.primary.withValues(alpha: 0.14)
                                  : AppColors.bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? palette.primary
                                    : AppColors.border,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [palette.primary, palette.accent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: palette.primary
                                                      .withValues(alpha: 0.45),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  paletteName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? palette.primary
                                        : AppColors.maintext,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Language Selector (Локализация языков)
          Text(
            tr.languageTitle,
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.language_rounded,
            title: tr.languageTitle,
            subtitle: '${currentLang.flag}  ${currentLang.nativeName}',
            iconColor: const Color(0xFF29B6F6),
            trailingWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.active.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.active.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${currentLang.flag} ${currentLang.code.toUpperCase()}',
                style: TextStyle(
                  color: AppColors.active,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onTap: _showLanguagePickerSheet,
          ),

          const SizedBox(height: 24),

          // 3. Cloud Synchronization (Синхронизация с Supabase)
          Text(
            tr.cloudSync,
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3ECF8E).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud_sync_rounded,
                        color: Color(0xFF3ECF8E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.cloudSync,
                            style: TextStyle(
                              color: AppColors.maintext,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentUser?.isLocal == true
                                ? tr.offlineModeDesc
                                : (syncController.lastSyncedAt != null
                                      ? '${tr.syncedJustNow}: ${syncController.lastSyncedAt!.hour.toString().padLeft(2, '0')}:${syncController.lastSyncedAt!.minute.toString().padLeft(2, '0')}'
                                      : tr.cloudSyncSubtitle),
                            style: TextStyle(
                              color: AppColors.labeltext,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (syncController.isSyncing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3ECF8E),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (currentUser?.isLocal == true
                                      ? Colors.grey
                                      : const Color(0xFF3ECF8E))
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentUser?.isLocal == true
                              ? tr.offlineMode
                              : tr.syncedJustNow,
                          style: TextStyle(
                            color: currentUser?.isLocal == true
                                ? AppColors.labeltext
                                : const Color(0xFF3ECF8E),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (currentUser?.isLocal != true) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: syncController.isSyncing
                          ? null
                          : () async {
                              AppHaptics.medium();
                              final ok = await syncController.syncWithCloud();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? tr.syncSuccess
                                          : (syncController.syncError ??
                                                'Ошибка синхронизации'),
                                    ),
                                  ),
                                );
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3ECF8E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(
                        Icons.sync_rounded,
                        size: 18,
                        color: Color(0xFF3ECF8E),
                      ),
                      label: Text(
                        tr.syncNow,
                        style: const TextStyle(
                          color: Color(0xFF3ECF8E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. AI & Smart Task Creation
          Text(
            tr.aiSettingsTitle,
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final parser = context.watch<ISmartTaskParser>();
              final hasKey = parser.hasGeminiApiKey;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8687E7), Color(0xFFA855F7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.aiSettingsTitle,
                                style: TextStyle(
                                  color: AppColors.maintext,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr.aiSettingsSubtitle,
                                style: TextStyle(
                                  color: AppColors.labeltext,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: hasKey
                            ? const Color(0xFF3ECF8E).withValues(alpha: 0.12)
                            : const Color(0xFF8687E7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasKey
                              ? const Color(0xFF3ECF8E).withValues(alpha: 0.3)
                              : const Color(0xFF8687E7).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasKey
                                ? Icons.bolt_rounded
                                : Icons.offline_bolt_rounded,
                            size: 16,
                            color: hasKey
                                ? const Color(0xFF3ECF8E)
                                : const Color(0xFF8687E7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasKey
                                ? 'Движок: Google Gemini 2.0 Flash'
                                : 'Движок: Встроенный офлайн NLP',
                            style: TextStyle(
                              color: hasKey
                                  ? const Color(0xFF3ECF8E)
                                  : const Color(0xFF8687E7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showAiApiKeyDialog,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF8687E7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        icon: const Icon(
                          Icons.key_rounded,
                          size: 18,
                          color: Color(0xFF8687E7),
                        ),
                        label: Text(
                          hasKey
                              ? 'Изменить ключ Gemini API'
                              : 'Настроить ключ Gemini API',
                          style: const TextStyle(
                            color: Color(0xFF8687E7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // 5. Notifications & Tactile Haptics
          Text(
            tr.notificationsAndHaptics,
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.notifications_active_outlined,
            title: tr.testNotification,
            subtitle: tr.testNotificationSubtitle,
            iconColor: const Color(0xFF4CAF50),
            onTap: () async {
              AppHaptics.medium();
              final messenger = ScaffoldMessenger.of(context);
              final notifSvc = context.read<INotificationService>();
              final ok = await notifSvc.sendTestNotification();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? tr.testNotificationSent
                        : tr.testNotificationPermissionError,
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
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.vibration_rounded,
                    color: AppColors.accentYellow,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.haptics,
                        style: TextStyle(
                          color: AppColors.maintext,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr.hapticsSubtitle,
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

          // 4. Data & Tasks Management
          Text(
            tr.dataManagement,
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.cleaning_services_outlined,
            title: tr.clearCompleted,
            subtitle: tr.clearCompletedSubtitle(completed),
            iconColor: AppColors.accentYellow,
            onTap: completed > 0
                ? () => _confirmClearCompleted(completed)
                : null,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.layers_clear_outlined,
            title: tr.resetAllTasks,
            subtitle: tr.resetAllTasksSubtitle(total),
            iconColor: Colors.orangeAccent,
            onTap: total > 0 ? () => _confirmClearAllTasks(total) : null,
          ),

          const SizedBox(height: 24),

          // 5. Account & Security
          Text(
            tr.accountAndSecurity,
            style: TextStyle(
              color: AppColors.maintext,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            title: tr.privacyPolicy,
            subtitle: tr.privacyPolicySubtitle,
            iconColor: const Color(0xFF00BCD4),
            onTap: _showPrivacyPolicySheet,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.logout_rounded,
            title: tr.signOut,
            subtitle: tr.signOutSubtitle,
            iconColor: Colors.orangeAccent,
            onTap: _confirmSignOut,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.delete_forever_outlined,
            title: tr.deleteAccount,
            subtitle: tr.deleteAccountSubtitle,
            iconColor: Colors.redAccent,
            onTap: _confirmDeleteAccount,
          ),

          const SizedBox(height: 24),

          // 6. App Info Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  color: AppColors.accentYellow,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr.tipFooter,
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
    this.trailingWidget,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;
  final Widget? trailingWidget;

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
              border: Border.all(color: AppColors.border),
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
                        style: TextStyle(
                          color: AppColors.maintext,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.labeltext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingWidget != null) ...[
                  const SizedBox(width: 8),
                  trailingWidget!,
                  const SizedBox(width: 4),
                ],
                if (enabled)
                  Icon(Icons.chevron_right_rounded, color: AppColors.labeltext),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
