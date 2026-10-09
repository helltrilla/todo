import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/logging/app_logger.dart';
import 'package:todo/core/notifications/media_playback_service.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/ambient/presentation/controllers/ambient_audio_controller.dart';
import 'package:todo/features/tasks/domain/entities/user_playlist.dart';
import 'package:todo/features/tasks/presentation/controllers/focus_playlist_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/pomodoro_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

/// Listodo Focus Mode (Pomodoro Timer + Ambient Mixer + Spotify/Music Hub) tab view.
class FocusTabView extends StatefulWidget {
  final double initialScrollOffset;
  const FocusTabView({super.key, this.initialScrollOffset = 0.0});

  @override
  State<FocusTabView> createState() => _FocusTabViewState();
}

class _FocusTabViewState extends State<FocusTabView>
    with WidgetsBindingObserver {
  static const _presetsMinutes = [15, 25, 45, 60];

  static const List<(String, String, IconData)> _ambientOptions = [
    ('off', 'Выкл', Icons.volume_off_rounded),
    ('rain', '🌧 Дождь', Icons.water_drop_outlined),
    ('fire', '🔥 Костер', Icons.local_fire_department_outlined),
    ('noise', '💨 Белый шум', Icons.air_rounded),
    ('waves', '🌊 Прибой', Icons.waves_rounded),
    ('cafe', '☕️ Кафе', Icons.local_cafe_outlined),
    ('vinyl', '💿 Винил', Icons.album_outlined),
  ];

  late final ScrollController _scrollController;
  INotificationService? _notificationService;

  String _ambientSound = 'off';
  double _ambientVolume = 0.45;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialScrollOffset,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationService ??= context.read<INotificationService>();
  }

  Future<void> _toggleSystemPlayPause() async {
    await context.read<MediaPlaybackService>().togglePlayPause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MediaPlaybackService>().onAppResumed();
    } else if (state == AppLifecycleState.paused) {
      context.read<MediaPlaybackService>().onAppPaused();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _notificationService?.setAmbientSound(sound: 'off');
    super.dispose();
  }

  void _selectPreset(int minutes) {
    context.read<PomodoroController>().selectPreset(minutes);
  }

  Future<void> _openCustomDurationPicker() async {
    AppHaptics.light();
    int tempMinutes = context.read<PomodoroController>().selectedMinutes;

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              14,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '⏱ Время фокуса',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.labeltext,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Large numeric display with plus / minus buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 36,
                      ),
                      color: tempMinutes > 1
                          ? AppColors.accentYellow
                          : AppColors.border,
                      onPressed: tempMinutes > 1
                          ? () {
                              AppHaptics.selection();
                              setSheetState(
                                () => tempMinutes = (tempMinutes - 5).clamp(
                                  1,
                                  180,
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgmain,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentYellow.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$tempMinutes',
                            style: TextStyle(
                              color: AppColors.maintext,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'мин',
                            style: TextStyle(
                              color: AppColors.labeltext,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 36,
                      ),
                      color: tempMinutes < 180
                          ? AppColors.accentYellow
                          : Colors.white24,
                      onPressed: tempMinutes < 180
                          ? () {
                              AppHaptics.selection();
                              setSheetState(
                                () => tempMinutes = (tempMinutes + 5).clamp(
                                  1,
                                  180,
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Slider
                SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    activeTrackColor: AppColors.accentYellow,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppColors.accentYellow,
                    overlayColor: AppColors.accentYellow.withValues(alpha: 0.2),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: tempMinutes.toDouble(),
                    min: 1,
                    max: 120,
                    divisions: 119,
                    onChanged: (val) {
                      setSheetState(() => tempMinutes = val.round());
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Popular preset chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [5, 10, 15, 20, 25, 30, 45, 50, 60, 90].map((mins) {
                    final isCurrent = tempMinutes == mins;
                    return ChoiceChip(
                      label: Text('$mins мин'),
                      selected: isCurrent,
                      selectedColor: AppColors.accentYellow,
                      backgroundColor: AppColors.bgmain,
                      labelStyle: TextStyle(
                        color: isCurrent ? Colors.black : AppColors.maintext,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        AppHaptics.selection();
                        setSheetState(() => tempMinutes = mins);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      AppHaptics.medium();
                      Navigator.pop(ctx, tempMinutes);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Применить время фокуса',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (selected != null && selected > 0) {
      _selectPreset(selected);
    }
  }

  void _selectAmbientSound(String soundKey) {
    AppHaptics.selection();
    setState(() => _ambientSound = soundKey);
    context.read<AmbientAudioController>().selectSound(soundKey);
  }

  void _updateAmbientVolume(double value) {
    setState(() => _ambientVolume = value);
    context.read<AmbientAudioController>().setVolume(value);
  }

  void _updateSystemVolume(double value) {
    context.read<MediaPlaybackService>().setSystemVolume(value);
  }

  Future<void> _launchMusicPreset({
    required String primaryUrl,
    String? fallbackUrl,
  }) async {
    AppHaptics.light();
    final notifSvc = _notificationService ?? context.read<INotificationService>();
    final opened = await notifSvc.openExternalUrl(
      url: primaryUrl,
      fallbackUrl: fallbackUrl,
    );
    if (opened && mounted) {
      context.read<MediaPlaybackService>().onExternalLinkLaunched();
    } else if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть ссылку музыкального сервиса'),
        ),
      );
    }
  }

  Future<void> _openPlaylistDialog({UserPlaylist? existing}) async {
    AppHaptics.light();
    final playlistCtrl = context.read<FocusPlaylistController>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    String? previewUrl = existing?.coverImageUrl;
    String? previewBase64 = existing?.coverImageBase64;
    bool isFetchingCover = false;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> autoFetchFromLink() async {
            final link = urlCtrl.text.trim();
            if (link.isEmpty) return;
            setDialogState(() => isFetchingCover = true);
            final metaResult = await playlistCtrl.fetchMetadata(link);
            setDialogState(() {
              isFetchingCover = false;
              switch (metaResult) {
                case Success(:final data):
                  if (data.coverUrl != null && data.coverUrl!.isNotEmpty) {
                    previewUrl = data.coverUrl;
                    previewBase64 = null;
                  }
                  if (titleCtrl.text.trim().isEmpty && data.title.isNotEmpty) {
                    titleCtrl.text = data.title;
                  }
                case Error():
                  break;
              }
            });
          }

          Uint8List? decodedBytes;
          if (previewBase64 != null && previewBase64!.isNotEmpty) {
            try {
              decodedBytes = base64Decode(previewBase64!);
            } catch (e, st) {
              AppLogger.debug('Failed to decode base64 preview: $e\n$st');
            }
          }

          return Dialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.album_rounded,
                        color: Color(0xFF1DB954),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          existing == null
                              ? 'Добавить плейлист'
                              : 'Настроить плейлист',
                          style: TextStyle(
                            color: AppColors.maintext,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (existing != null)
                        IconButton(
                          tooltip: 'Удалить плейлист',
                          onPressed: () => Navigator.of(ctx).pop('delete'),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Cover preview + actions row
                  Row(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: AppColors.bgmain,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          image: decodedBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(decodedBytes),
                                  fit: BoxFit.cover,
                                )
                              : (previewUrl != null && previewUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(previewUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            (decodedBytes == null &&
                                (previewUrl == null || previewUrl!.isEmpty))
                            ? Icon(
                                Icons.music_note_rounded,
                                color: AppColors.labeltext,
                                size: 30,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final notifSvc = _notificationService ??
                                    context.read<INotificationService>();
                                final b64 = await notifSvc.pickProfileImage();
                                if (b64 != null && b64.isNotEmpty) {
                                  setDialogState(() {
                                    previewBase64 = b64;
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.maintext,
                                side: BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 15,
                              ),
                              label: const Text(
                                'Фото из галереи',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: isFetchingCover ? null : autoFetchFromLink,
                              child: Text(
                                isFetchingCover
                                    ? 'Загружаем обложку...'
                                    : '✨ Подтянуть обложку по ссылке',
                                style: TextStyle(
                                  color: AppColors.accentYellow,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: urlCtrl,
                    style: TextStyle(
                      color: AppColors.maintext,
                      fontSize: 13,
                    ),
                    onChanged: (val) {
                      if (val.contains('http') || val.startsWith('spotify:')) {
                        autoFetchFromLink();
                      }
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: 'https://open.spotify.com/playlist/...',
                      labelText: 'Ссылка на плейлист (URL)',
                      labelStyle: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(
                      color: AppColors.maintext,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: 'Например: Lo-Fi для работы',
                      labelText: 'Название плейлиста',
                      labelStyle: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Отмена',
                          style: TextStyle(color: AppColors.labeltext),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop('save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DB954),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (action == 'delete' && existing != null) {
      await playlistCtrl.deletePlaylist(existing.id);
      return;
    }

    if (action == 'save') {
      final url = urlCtrl.text.trim();
      if (url.isEmpty) return;

      var title = titleCtrl.text.trim();
      if (previewUrl == null && previewBase64 == null) {
        final metaResult = await playlistCtrl.fetchMetadata(url);
        switch (metaResult) {
          case Success(:final data):
            previewUrl = data.coverUrl;
            if (title.isEmpty && data.title.isNotEmpty) {
              title = data.title;
            }
          case Error():
            break;
        }
      }
      if (title.isEmpty) {
        title = 'Мой плейлист';
      }

      final updatedItem = UserPlaylist(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        url: url,
        coverImageUrl: previewUrl,
        coverImageBase64: previewBase64,
      );

      if (existing != null) {
        await playlistCtrl.updatePlaylist(updatedItem);
      } else {
        await playlistCtrl.addPlaylist(updatedItem);
      }
    }
  }

  void _toggleTimer() {
    context.read<PomodoroController>().toggleTimer();
  }

  void _resetTimer() {
    context.read<PomodoroController>().reset();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final pomodoro = context.watch<PomodoroController>();
    final mediaService = context.watch<MediaPlaybackService>();
    final playlistCtrl = context.watch<FocusPlaylistController>();
    final activeTasks = controller.tasks.where((t) => !t.isCompleted).toList();
    final selectedMinutes = pomodoro.selectedMinutes;
    final isRunning = pomodoro.isRunning;
    final progress = pomodoro.progress;
    final formattedTime = pomodoro.formattedTime;
    final isSystemMusicPlaying = mediaService.isPlaying;
    final systemVolume = mediaService.systemVolume;
    final userPlaylists = playlistCtrl.playlists;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Preset duration selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._presetsMinutes.map((mins) {
                final isSelected = selectedMinutes == mins;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _selectPreset(mins),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentYellow
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentYellow
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        '$mins мин',
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.maintext,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Custom duration button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: _openCustomDurationPicker,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: !_presetsMinutes.contains(selectedMinutes)
                          ? AppColors.accentYellow
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: !_presetsMinutes.contains(selectedMinutes)
                            ? AppColors.accentYellow
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 15,
                          color: !_presetsMinutes.contains(selectedMinutes)
                              ? Colors.black
                              : AppColors.accentYellow,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          !_presetsMinutes.contains(selectedMinutes)
                              ? '$selectedMinutes мин'
                              : 'Своё',
                          style: TextStyle(
                            color: !_presetsMinutes.contains(selectedMinutes)
                                ? Colors.black
                                : AppColors.maintext,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Circular Countdown Ring (tap to adjust duration when paused)
        Center(
          child: SizedBox(
            width: 210,
            height: 210,
            child: CustomPaint(
              painter: _FocusRingPainter(progress: progress),
              child: Center(
                child: GestureDetector(
                  onTap: isRunning ? null : _openCustomDurationPicker,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: AppColors.maintext,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isRunning ? 'В фокусе...' : 'Готов к старту',
                            style: TextStyle(
                              color: AppColors.labeltext,
                              fontSize: 13,
                            ),
                          ),
                          if (!isRunning) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: AppColors.labeltext,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Start / Pause & Reset buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _toggleTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.active,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                isRunning ? 'Пауза' : 'Начать фокус',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _resetTimer,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.maintext,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Сброс'),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 1. Ambient Soundscape + Dual Audio Mixer (In-App Ambient + System Phone Volume)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _ambientSound != 'off'
                  ? AppColors.accentYellow.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: AppColors.accentYellow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Аудио-микшер и атмосфера',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_ambientSound != 'off')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Mix активен',
                        style: TextStyle(
                          color: AppColors.accentYellow,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _ambientOptions.map((opt) {
                    final key = opt.$1;
                    final label = opt.$2;
                    final icon = opt.$3;
                    final selected = _ambientSound == key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _selectAmbientSound(key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accentYellow
                                : AppColors.bgmain,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accentYellow
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: selected
                                    ? Colors.black
                                    : AppColors.labeltext,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.black
                                      : AppColors.maintext,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
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
              const SizedBox(height: 16),
              // Dual Mixer Container
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgmain,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Channel 1: In-app Ambient Volume
                    Row(
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          color: _ambientSound != 'off'
                              ? AppColors.accentYellow
                              : AppColors.labeltext,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 82,
                          child: Text(
                            'Атмосфера',
                            style: TextStyle(
                              color: AppColors.maintext,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _ambientSound != 'off'
                                  ? AppColors.accentYellow
                                  : AppColors.border,
                              inactiveTrackColor: AppColors.divider,
                              thumbColor: _ambientSound != 'off'
                                  ? AppColors.accentYellow
                                  : AppColors.labeltext,
                              trackHeight: 4,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: _ambientVolume,
                              min: 0.05,
                              max: 1.0,
                              onChanged: _updateAmbientVolume,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            _ambientSound == 'off'
                                ? 'ВЫКЛ'
                                : '${(_ambientVolume * 100).round()}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: _ambientSound != 'off'
                                  ? AppColors.accentYellow
                                  : AppColors.labeltext,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(color: AppColors.divider, height: 8),
                    // Channel 2: System Phone / Music Volume
                    Row(
                      children: [
                        const Icon(
                          Icons.speaker_rounded,
                          color: Color(0xFF1DB954),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 82,
                          child: Text(
                            'Телефон',
                            style: TextStyle(
                              color: AppColors.maintext,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF1DB954),
                              inactiveTrackColor: AppColors.divider,
                              thumbColor: const Color(0xFF1DB954),
                              trackHeight: 4,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: systemVolume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: _updateSystemVolume,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${(systemVolume * 100).round()}%',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF1DB954),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Large System Media Deck + Horizontal Playlist Cover Carousel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.headphones_rounded,
                    color: Color(0xFF1DB954),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Музыка для фокуса',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSystemMusicPlaying
                          ? const Color(0xFF1DB954).withValues(alpha: 0.18)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSystemMusicPlaying
                            ? const Color(0xFF1DB954).withValues(alpha: 0.45)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSystemMusicPlaying) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1DB954),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          isSystemMusicPlaying
                              ? 'Играет на шторке'
                              : 'Шторка на паузе',
                          style: TextStyle(
                            color: isSystemMusicPlaying
                                ? const Color(0xFF1DB954)
                                : AppColors.labeltext,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Large tactile media control deck
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _LargeMediaTransportBtn(
                      icon: Icons.skip_previous_rounded,
                      label: 'Назад',
                      onTap: () {
                        AppHaptics.light();
                        final mediaSvc = context.read<MediaPlaybackService>();
                        final notifSvc = _notificationService ??
                            context.read<INotificationService>();
                        unawaited(
                          notifSvc.sendMediaCommand('previous'),
                        );
                        Future.delayed(
                          const Duration(milliseconds: 350),
                          mediaSvc.refreshPlaybackState,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _LargeMediaTransportBtn(
                      icon: isSystemMusicPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      label: isSystemMusicPlaying ? 'Пауза' : 'Играть',
                      isPrimary: true,
                      isActive: isSystemMusicPlaying,
                      onTap: _toggleSystemPlayPause,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _LargeMediaTransportBtn(
                      icon: Icons.skip_next_rounded,
                      label: 'Вперёд',
                      onTap: () {
                        AppHaptics.light();
                        final mediaSvc = context.read<MediaPlaybackService>();
                        final notifSvc = _notificationService ??
                            context.read<INotificationService>();
                        unawaited(
                          notifSvc.sendMediaCommand('next'),
                        );
                        Future.delayed(
                          const Duration(milliseconds: 350),
                          mediaSvc.refreshPlaybackState,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Мои плейлисты',
                    style: TextStyle(
                      color: AppColors.maintext,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openPlaylistDialog(),
                    child: Text(
                      '+ Добавить плейлист',
                      style: TextStyle(
                        color: AppColors.accentYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (userPlaylists.isEmpty)
                GestureDetector(
                  onTap: () => _openPlaylistDialog(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgmain,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.accentYellow.withValues(alpha: 0.35),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.accentYellow,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Добавить свой плейлист (Spotify / Яндекс / Apple Music)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.maintext,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 154,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...userPlaylists.map((pl) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _PlaylistCoverCard(
                            serviceBadge: pl.serviceBadge,
                            title: pl.title,
                            subtitle: 'Нажми для запуска',
                            gradientColors: pl.fallbackGradient,
                            coverImageUrl: pl.coverImageUrl,
                            coverImageBase64: pl.coverImageBase64,
                            icon: Icons.album_rounded,
                            onTap: () => _launchMusicPreset(primaryUrl: pl.url),
                            onEditTap: () => _openPlaylistDialog(existing: pl),
                          ),
                        );
                      }),
                      // "+ Add another playlist" card at the end of carousel
                      GestureDetector(
                        onTap: () => _openPlaylistDialog(),
                        child: Container(
                          width: 124,
                          decoration: BoxDecoration(
                            color: AppColors.bgmain,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.accentYellow,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '+ Добавить',
                                style: TextStyle(
                                  color: AppColors.maintext,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. Task selector for current focus session
        Text(
          'Фокус на задаче',
          style: TextStyle(
            color: AppColors.maintext,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (activeTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Нет активных задач. Добавьте задачу кнопкой «+» по центру.',
              style: TextStyle(color: AppColors.labeltext, fontSize: 13),
            ),
          )
        else
          ...activeTasks.map((task) {
            final isFocused = pomodoro.focusedTaskId == task.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  AppHaptics.selection();
                  pomodoro.setFocusedTaskId(
                    isFocused ? null : task.id,
                    taskName: isFocused ? null : task.name,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFocused
                          ? AppColors.accentYellow
                          : AppColors.border,
                      width: isFocused ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFocused
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isFocused
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
                              task.name,
                              style: TextStyle(
                                color: AppColors.maintext,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (task.pomodoroCount > 0) ...[
                              const SizedBox(height: 3),
                              Text(
                                '🍅 ${task.pomodoroCount} сессий • ${task.focusMinutes} мин в фокусе',
                                style: TextStyle(
                                  color: AppColors.accentYellow,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isFocused)
                        TextButton(
                          onPressed: () {
                            AppHaptics.heavy();
                            controller.toggleCompleted(task.id);
                            pomodoro.setFocusedTaskId(null);
                          },
                          child: Text(
                            'Готово ✓',
                            style: TextStyle(
                              color: AppColors.accentYellow,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _LargeMediaTransportBtn extends StatelessWidget {
  const _LargeMediaTransportBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary
        ? (isActive
              ? const Color(0xFF1DB954).withValues(alpha: 0.24)
              : AppColors.bgmain)
        : AppColors.bgmain;
    final borderColor = isPrimary
        ? (isActive
              ? const Color(0xFF1DB954).withValues(alpha: 0.85)
              : Colors.white24)
        : Colors.white12;
    final fgColor = isPrimary
        ? (isActive ? const Color(0xFF1DB954) : AppColors.maintext)
        : AppColors.maintext;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 58,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isPrimary ? 1.4 : 1),
            boxShadow: (isPrimary && isActive)
                ? [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isPrimary ? 26 : 24, color: fgColor),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistCoverCard extends StatelessWidget {
  const _PlaylistCoverCard({
    required this.serviceBadge,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
    this.coverImageUrl,
    this.coverImageBase64,
    this.onEditTap,
  });

  final String serviceBadge;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final String? coverImageUrl;
  final String? coverImageBase64;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    Uint8List? memoryBytes;
    if (coverImageBase64 != null && coverImageBase64!.isNotEmpty) {
      try {
        memoryBytes = base64Decode(coverImageBase64!);
      } catch (e, st) {
        AppLogger.debug('Failed to decode coverImageBase64: $e\n$st');
      }
    }

    final hasCoverImage =
        memoryBytes != null ||
        (coverImageUrl != null && coverImageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Cover Image or Fallback Gradient Background
              if (memoryBytes != null)
                Image.memory(memoryBytes, fit: BoxFit.cover)
              else if (coverImageUrl != null && coverImageUrl!.isNotEmpty)
                Image.network(
                  coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                  ),
                ),

              // 2. High-contrast gradient scrim for legibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      hasCoverImage
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.transparent,
                      Colors.black.withValues(
                        alpha: hasCoverImage ? 0.88 : 0.45,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Subtle vinyl icon watermark in top-right if no cover
              if (!hasCoverImage)
                Positioned(
                  right: -18,
                  bottom: -18,
                  child: Icon(
                    icon,
                    size: 84,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),

              // 4. Foreground content: badge, edit icon, title, subtitle
              Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              serviceBadge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (onEditTap != null)
                          GestureDetector(
                            onTap: onEditTap,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (!hasCoverImage) ...[
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    final trackPaint = Paint()
      ..color = AppColors.cardBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final progressPaint = Paint()
      ..color = AppColors.active
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
