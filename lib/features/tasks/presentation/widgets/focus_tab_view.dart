import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

/// Listodo Focus Mode (Pomodoro Timer + Ambient Mixer + Spotify/Music Hub) tab view.
class FocusTabView extends StatefulWidget {
  const FocusTabView({super.key});

  @override
  State<FocusTabView> createState() => _FocusTabViewState();
}

class _FocusTabViewState extends State<FocusTabView> {
  static const _presetsMinutes = [15, 25, 45];
  static const _customPlaylistUrlKey = 'focus_custom_playlist_url';
  static const _customPlaylistTitleKey = 'focus_custom_playlist_title';

  static const List<(String, String, IconData)> _ambientOptions = [
    ('off', 'Выкл', Icons.volume_off_rounded),
    ('rain', '🌧 Дождь', Icons.water_drop_outlined),
    ('waves', '🌊 Прибой', Icons.waves_rounded),
    ('cafe', '☕️ Кафе', Icons.local_cafe_outlined),
    ('vinyl', '💿 Винил', Icons.album_outlined),
  ];

  int _selectedMinutes = 25;
  late int _remainingSeconds;
  bool _isRunning = false;
  Timer? _timer;
  int? _focusedTaskId;

  String _ambientSound = 'off';
  double _ambientVolume = 0.45;
  double _systemVolume = 0.65;
  String? _customPlaylistUrl;
  String _customPlaylistTitle = 'Мой плейлист';

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedMinutes * 60;
    _loadSavedPlaylist();
  }

  Future<void> _loadSavedPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final sysVol = await NotificationService.instance.getSystemVolume();
    if (!mounted) return;
    setState(() {
      _customPlaylistUrl = prefs.getString(_customPlaylistUrlKey);
      _customPlaylistTitle =
          prefs.getString(_customPlaylistTitleKey) ?? 'Мой плейлист';
      _systemVolume = sysVol;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    NotificationService.instance.setAmbientSound(sound: 'off');
    super.dispose();
  }

  void _selectPreset(int minutes) {
    AppHaptics.selection();
    _timer?.cancel();
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _isRunning = false;
    });
  }

  void _selectAmbientSound(String soundKey) {
    AppHaptics.selection();
    setState(() => _ambientSound = soundKey);
    NotificationService.instance.setAmbientSound(
      sound: soundKey,
      volume: _ambientVolume,
    );
  }

  void _updateAmbientVolume(double value) {
    setState(() => _ambientVolume = value);
    if (_ambientSound != 'off') {
      NotificationService.instance.setAmbientSound(
        sound: _ambientSound,
        volume: value,
      );
    }
  }

  void _updateSystemVolume(double value) {
    setState(() => _systemVolume = value);
    NotificationService.instance.setSystemVolume(value);
  }

  Future<void> _launchMusicPreset({
    required String primaryUrl,
    String? fallbackUrl,
  }) async {
    AppHaptics.light();
    final opened = await NotificationService.instance.openExternalUrl(
      url: primaryUrl,
      fallbackUrl: fallbackUrl,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть ссылку музыкального сервиса'),
        ),
      );
    }
  }

  Future<void> _configureCustomPlaylist() async {
    AppHaptics.light();
    final titleCtrl = TextEditingController(text: _customPlaylistTitle);
    final urlCtrl = TextEditingController(text: _customPlaylistUrl ?? '');

    final saved = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    color: Color(0xFF1DB954),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Привязать свой плейлист',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Вставь ссылку на любимый плейлист из Spotify, Яндекс Музыки, Apple Music или YouTube Music:',
                style: TextStyle(color: AppColors.labeltext, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.maintext, fontSize: 14),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: 'Название кнопки',
                  labelStyle: TextStyle(
                    color: AppColors.labeltext,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                style: const TextStyle(color: AppColors.maintext, fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  hintText: 'https://open.spotify.com/playlist/...',
                  labelText: 'Ссылка (URL)',
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
                    child: const Text(
                      'Отмена',
                      style: TextStyle(color: AppColors.labeltext),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim().isEmpty
                          ? 'Мой плейлист'
                          : titleCtrl.text.trim();
                      final url = urlCtrl.text.trim();
                      Navigator.of(ctx).pop((title, url));
                    },
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
      ),
    );

    if (saved != null) {
      final prefs = await SharedPreferences.getInstance();
      final title = saved.$1;
      final url = saved.$2;
      if (url.isEmpty) {
        await prefs.remove(_customPlaylistUrlKey);
        if (!mounted) return;
        setState(() {
          _customPlaylistUrl = null;
          _customPlaylistTitle = 'Мой плейлист';
        });
      } else {
        await prefs.setString(_customPlaylistTitleKey, title);
        await prefs.setString(_customPlaylistUrlKey, url);
        if (!mounted) return;
        setState(() {
          _customPlaylistTitle = title;
          _customPlaylistUrl = url;
        });
      }
    }
  }

  void _toggleTimer() {
    AppHaptics.medium();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        AppHaptics.heavy();
        final taskController = context.read<TaskController>();
        final tasks = taskController.tasks;
        String? focusedName;
        if (_focusedTaskId != null) {
          for (final t in tasks) {
            if (t.id == _focusedTaskId) {
              focusedName = t.name;
              break;
            }
          }
          taskController.recordFocusSession(
            _focusedTaskId!,
            minutes: _selectedMinutes,
          );
        }
        NotificationService.instance.sendFocusCompletedNotification(
          taskName: focusedName,
        );
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              focusedName != null
                  ? 'Фокус-сессия (+1 🍅) по задаче «$focusedName» завершена!'
                  : 'Сессия фокуса завершена! Отличная работа 🔥',
            ),
          ),
        );
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _resetTimer() {
    AppHaptics.light();
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
      _isRunning = false;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final activeTasks = controller.tasks.where((t) => !t.isCompleted).toList();
    final totalSeconds = _selectedMinutes * 60;
    final progress = totalSeconds > 0
        ? (_remainingSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Preset duration selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _presetsMinutes.map((mins) {
            final isSelected = _selectedMinutes == mins;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => _selectPreset(mins),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
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
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Circular Countdown Ring
        Center(
          child: SizedBox(
            width: 210,
            height: 210,
            child: CustomPaint(
              painter: _FocusRingPainter(progress: progress),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        color: AppColors.maintext,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRunning ? 'В фокусе...' : 'Готов к старту',
                      style: const TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                _isRunning ? 'Пауза' : 'Начать фокус',
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
                side: const BorderSide(color: Colors.white24),
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
                  : Colors.white12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.accentYellow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
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
                      child: const Text(
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
                                  : Colors.white12,
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
                  border: Border.all(color: Colors.white10),
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
                        const SizedBox(
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
                                  : Colors.white24,
                              inactiveTrackColor: Colors.white12,
                              thumbColor: _ambientSound != 'off'
                                  ? AppColors.accentYellow
                                  : Colors.white54,
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
                    const Divider(color: Colors.white10, height: 8),
                    // Channel 2: System Phone / Music Volume
                    Row(
                      children: [
                        const Icon(
                          Icons.speaker_rounded,
                          color: Color(0xFF1DB954),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const SizedBox(
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
                              inactiveTrackColor: Colors.white12,
                              thumbColor: const Color(0xFF1DB954),
                              trackHeight: 4,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: _systemVolume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: _updateSystemVolume,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${(_systemVolume * 100).round()}%',
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
            border: Border.all(color: Colors.white12),
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
                  const Expanded(
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
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Активный плеер на шторке',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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
                        NotificationService.instance.sendMediaCommand(
                          'previous',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _LargeMediaTransportBtn(
                      icon: Icons.play_arrow_rounded,
                      secondaryIcon: Icons.pause_rounded,
                      label: 'Плей / Пауза',
                      isPrimary: true,
                      onTap: () {
                        AppHaptics.medium();
                        NotificationService.instance.sendMediaCommand(
                          'playPause',
                        );
                      },
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
                        NotificationService.instance.sendMediaCommand('next');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Подборки и потоки',
                    style: TextStyle(
                      color: AppColors.maintext,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: _configureCustomPlaylist,
                    child: const Text(
                      'Изменить свой URL',
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
              SizedBox(
                height: 152,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _PlaylistCoverCard(
                      serviceBadge: 'SPOTIFY',
                      title: 'Deep Focus',
                      subtitle: 'Погружение без слов',
                      gradientColors: const [
                        Color(0xFF1DB954),
                        Color(0xFF0E3B22),
                      ],
                      icon: Icons.graphic_eq_rounded,
                      onTap: () => _launchMusicPreset(
                        primaryUrl: 'spotify:playlist:37i9dQZF1DWZeKCadgRdKQ',
                        fallbackUrl:
                            'https://open.spotify.com/playlist/37i9dQZF1DWZeKCadgRdKQ',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PlaylistCoverCard(
                      serviceBadge: 'SPOTIFY',
                      title: 'Lo-Fi Beats',
                      subtitle: 'Мягкий бит для кода',
                      gradientColors: const [
                        Color(0xFF6366F1),
                        Color(0xFF1E1B4B),
                      ],
                      icon: Icons.headphones_rounded,
                      onTap: () => _launchMusicPreset(
                        primaryUrl: 'spotify:playlist:37i9dQZF1DWWQRwui0ExPn',
                        fallbackUrl:
                            'https://open.spotify.com/playlist/37i9dQZF1DWWQRwui0ExPn',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PlaylistCoverCard(
                      serviceBadge: 'APPLE MUSIC',
                      title: 'Pure Focus',
                      subtitle: 'Чистая концентрация',
                      gradientColors: const [
                        Color(0xFFFA243C),
                        Color(0xFF4C0519),
                      ],
                      icon: Icons.library_music_rounded,
                      onTap: () => _launchMusicPreset(
                        primaryUrl:
                            'https://music.apple.com/us/playlist/pure-focus/pl.dbd712beded846dca273d5d3259d28aa',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PlaylistCoverCard(
                      serviceBadge: 'ЯНДЕКС МУЗЫКА',
                      title: 'Моя волна',
                      subtitle: 'Персональный поток',
                      gradientColors: const [
                        Color(0xFFF59E0B),
                        Color(0xFF451A03),
                      ],
                      icon: Icons.waves_rounded,
                      onTap: () => _launchMusicPreset(
                        primaryUrl: 'yandexmusic://',
                        fallbackUrl: 'https://music.yandex.ru/',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PlaylistCoverCard(
                      serviceBadge: 'СВОЙ ПЛЕЙЛИСТ',
                      title: _customPlaylistUrl != null
                          ? _customPlaylistTitle
                          : '+ Добавить ссылку',
                      subtitle: _customPlaylistUrl != null
                          ? 'Твой быстрый поток'
                          : 'Spotify / Яндекс / YouTube',
                      gradientColors: const [
                        Color(0xFFD97706),
                        Color(0xFF1F2937),
                      ],
                      icon: _customPlaylistUrl != null
                          ? Icons.star_rounded
                          : Icons.add_link_rounded,
                      onTap: () {
                        if (_customPlaylistUrl != null &&
                            _customPlaylistUrl!.isNotEmpty) {
                          _launchMusicPreset(primaryUrl: _customPlaylistUrl!);
                        } else {
                          _configureCustomPlaylist();
                        }
                      },
                      onEditTap: _configureCustomPlaylist,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. Task selector for current focus session
        const Text(
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
              border: Border.all(color: Colors.white12),
            ),
            child: const Text(
              'Нет активных задач. Добавьте задачу кнопкой «+» по центру.',
              style: TextStyle(color: AppColors.labeltext, fontSize: 13),
            ),
          )
        else
          ...activeTasks.map((task) {
            final isFocused = _focusedTaskId == task.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  AppHaptics.selection();
                  setState(() => _focusedTaskId = task.id);
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
                          : Colors.white12,
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
                              style: const TextStyle(
                                color: AppColors.maintext,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (task.pomodoroCount > 0) ...[
                              const SizedBox(height: 3),
                              Text(
                                '🍅 ${task.pomodoroCount} сессий • ${task.focusMinutes} мин в фокусе',
                                style: const TextStyle(
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
                            setState(() => _focusedTaskId = null);
                          },
                          child: const Text(
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
    this.secondaryIcon,
    this.isPrimary = false,
  });

  final IconData icon;
  final IconData? secondaryIcon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary
        ? const Color(0xFF1DB954).withValues(alpha: 0.18)
        : AppColors.bgmain;
    final borderColor = isPrimary
        ? const Color(0xFF1DB954).withValues(alpha: 0.65)
        : Colors.white12;
    final fgColor = isPrimary ? const Color(0xFF1DB954) : AppColors.maintext;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isPrimary ? 1.4 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: isPrimary ? 26 : 24, color: fgColor),
                  if (secondaryIcon != null) ...[
                    Icon(secondaryIcon, size: 22, color: fgColor),
                  ],
                ],
              ),
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
    this.onEditTap,
  });

  final String serviceBadge;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
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
        child: Stack(
          children: [
            // Subtle decorative vinyl / soundwave circle in top-right
            Positioned(
              right: -18,
              bottom: -18,
              child: Icon(
                icon,
                size: 84,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        serviceBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (onEditTap != null)
                      GestureDetector(
                        onTap: onEditTap,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
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
                          color: Colors.white.withValues(alpha: 0.22),
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
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
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
