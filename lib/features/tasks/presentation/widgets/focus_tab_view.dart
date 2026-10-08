import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

class _UserPlaylist {
  const _UserPlaylist({
    required this.id,
    required this.title,
    required this.url,
    this.coverImageUrl,
    this.coverImageBase64,
  });

  final String id;
  final String title;
  final String url;
  final String? coverImageUrl;
  final String? coverImageBase64;

  String get serviceBadge {
    final lower = url.toLowerCase();
    if (lower.contains('spotify')) return 'SPOTIFY';
    if (lower.contains('yandex')) return 'ЯНДЕКС';
    if (lower.contains('apple.com') || lower.startsWith('music:')) {
      return 'APPLE MUSIC';
    }
    if (lower.contains('youtube') || lower.contains('youtu.be')) {
      return 'YOUTUBE';
    }
    if (lower.contains('vk.com') || lower.contains('boom')) return 'VK МУЗЫКА';
    return 'ПЛЕЙЛИСТ';
  }

  List<Color> get fallbackGradient {
    final lower = url.toLowerCase();
    if (lower.contains('spotify')) {
      return const [Color(0xFF1DB954), Color(0xFF0E3B22)];
    }
    if (lower.contains('yandex')) {
      return const [Color(0xFFF59E0B), Color(0xFF451A03)];
    }
    if (lower.contains('apple.com') || lower.startsWith('music:')) {
      return const [Color(0xFFFA243C), Color(0xFF4C0519)];
    }
    if (lower.contains('youtube') || lower.contains('youtu.be')) {
      return const [Color(0xFFEF4444), Color(0xFF450A0A)];
    }
    return const [Color(0xFF6366F1), Color(0xFF1E1B4B)];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'coverImageUrl': coverImageUrl,
    'coverImageBase64': coverImageBase64,
  };

  factory _UserPlaylist.fromJson(Map<String, dynamic> json) => _UserPlaylist(
    id:
        (json['id'] as String?) ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    title: (json['title'] as String?) ?? 'Мой плейлист',
    url: (json['url'] as String?) ?? '',
    coverImageUrl: json['coverImageUrl'] as String?,
    coverImageBase64: json['coverImageBase64'] as String?,
  );
}

/// Listodo Focus Mode (Pomodoro Timer + Ambient Mixer + Spotify/Music Hub) tab view.
class FocusTabView extends StatefulWidget {
  const FocusTabView({super.key});

  @override
  State<FocusTabView> createState() => _FocusTabViewState();
}

class _FocusTabViewState extends State<FocusTabView>
    with WidgetsBindingObserver {
  static const _presetsMinutes = [15, 25, 45];
  static const _userPlaylistsKey = 'focus_user_playlists_v2';
  static const _legacyCustomPlaylistUrlKey = 'focus_custom_playlist_url';
  static const _legacyCustomPlaylistTitleKey = 'focus_custom_playlist_title';

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
  bool _isSystemMusicPlaying = false;
  Timer? _playbackPollTimer;
  List<_UserPlaylist> _userPlaylists = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = _selectedMinutes * 60;
    _loadSavedPlaylists();
    _checkPlaybackState();
    _playbackPollTimer = Timer.periodic(
      const Duration(milliseconds: 1400),
      (_) => _checkPlaybackState(),
    );
  }

  Future<void> _checkPlaybackState() async {
    final isPlaying =
        await NotificationService.instance.getMediaPlaybackState();
    if (mounted && _isSystemMusicPlaying != isPlaying) {
      setState(() => _isSystemMusicPlaying = isPlaying);
    }
  }

  Future<void> _toggleSystemPlayPause() async {
    AppHaptics.medium();
    final nextState = !_isSystemMusicPlaying;
    setState(() => _isSystemMusicPlaying = nextState);
    unawaited(
      NotificationService.instance.sendMediaCommand(
        nextState ? 'play' : 'pause',
      ),
    );
    Future.delayed(const Duration(milliseconds: 350), _checkPlaybackState);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPlaybackState();
      NotificationService.instance.getSystemVolume().then((vol) {
        if (mounted) setState(() => _systemVolume = vol);
      });
    }
  }

  Future<void> _loadSavedPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final sysVol = await NotificationService.instance.getSystemVolume();
    final rawJson = prefs.getString(_userPlaylistsKey);
    final loaded = <_UserPlaylist>[];

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            loaded.add(_UserPlaylist.fromJson(item));
          }
        }
      } catch (_) {}
    } else {
      // Migrate single legacy custom playlist if present
      final legacyUrl = prefs.getString(_legacyCustomPlaylistUrlKey);
      final legacyTitle =
          prefs.getString(_legacyCustomPlaylistTitleKey) ?? 'Мой плейлист';
      if (legacyUrl != null && legacyUrl.isNotEmpty) {
        loaded.add(
          _UserPlaylist(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: legacyTitle,
            url: legacyUrl,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _userPlaylists = loaded;
      _systemVolume = sysVol;
    });

    // Auto-fetch missing cover artwork in the background for migrated playlists
    for (var i = 0; i < _userPlaylists.length; i++) {
      final item = _userPlaylists[i];
      if (item.coverImageUrl == null && item.coverImageBase64 == null) {
        final meta = await _fetchPlaylistMetadata(item.url);
        if (meta.$2 != null && mounted) {
          setState(() {
            _userPlaylists[i] = _UserPlaylist(
              id: item.id,
              title: item.title,
              url: item.url,
              coverImageUrl: meta.$2,
              coverImageBase64: item.coverImageBase64,
            );
          });
          await _persistPlaylists();
        }
      }
    }
  }

  Future<void> _persistPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_userPlaylists.map((e) => e.toJson()).toList());
    await prefs.setString(_userPlaylistsKey, encoded);
  }

  /// Automatically fetches `(title, coverImageUrl)` from Spotify oEmbed,
  /// YouTube oEmbed, or OpenGraph (`og:image` / `og:title`) tags.
  Future<(String?, String?)> _fetchPlaylistMetadata(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return (null, null);

    var webUrl = trimmed;
    if (trimmed.startsWith('spotify:')) {
      // Convert spotify:playlist:ID to https://open.spotify.com/playlist/ID
      final parts = trimmed.split(':');
      if (parts.length >= 3) {
        webUrl = 'https://open.spotify.com/${parts[1]}/${parts[2]}';
      }
    }

    try {
      final lower = webUrl.toLowerCase();
      if (lower.contains('open.spotify.com')) {
        final oembedUri = Uri.parse(
          'https://open.spotify.com/oembed?url=${Uri.encodeComponent(webUrl)}',
        );
        final resp = await http
            .get(oembedUri)
            .timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final title = data['title'] as String?;
          final thumb = data['thumbnail_url'] as String?;
          return (title, thumb);
        }
      } else if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
        final oembedUri = Uri.parse(
          'https://www.youtube.com/oembed?url=${Uri.encodeComponent(webUrl)}&format=json',
        );
        final resp = await http
            .get(oembedUri)
            .timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final title = data['title'] as String?;
          final thumb = data['thumbnail_url'] as String?;
          return (title, thumb);
        }
      }

      if (webUrl.startsWith('http://') || webUrl.startsWith('https://')) {
        final resp = await http
            .get(
              Uri.parse(webUrl),
              headers: {'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)'},
            )
            .timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final html = resp.body;
          final ogImageMatch = RegExp(
            r'<meta[^>]+property=["\x27]og:image["\x27][^>]+content=["\x27]([^"\x27]+)["\x27]',
            caseSensitive: false,
          ).firstMatch(html) ??
              RegExp(
                r'<meta[^>]+content=["\x27]([^"\x27]+)["\x27][^>]+property=["\x27]og:image["\x27]',
                caseSensitive: false,
              ).firstMatch(html);
          final ogTitleMatch = RegExp(
            r'<meta[^>]+property=["\x27]og:title["\x27][^>]+content=["\x27]([^"\x27]+)["\x27]',
            caseSensitive: false,
          ).firstMatch(html);
          return (ogTitleMatch?.group(1), ogImageMatch?.group(1));
        }
      }
    } catch (_) {}
    return (null, null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playbackPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> _openPlaylistDialog({_UserPlaylist? existing}) async {
    AppHaptics.light();
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
            final meta = await _fetchPlaylistMetadata(link);
            setDialogState(() {
              isFetchingCover = false;
              if (meta.$2 != null) {
                previewUrl = meta.$2;
                previewBase64 = null;
              }
              if (titleCtrl.text.trim().isEmpty && meta.$1 != null) {
                titleCtrl.text = meta.$1!;
              }
            });
          }

          Uint8List? decodedBytes;
          if (previewBase64 != null && previewBase64!.isNotEmpty) {
            try {
              decodedBytes = base64Decode(previewBase64!);
            } catch (_) {}
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
                          style: const TextStyle(
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
                          border: Border.all(color: Colors.white12),
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
                            ? const Icon(
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
                                final b64 = await NotificationService.instance
                                    .pickProfileImage();
                                if (b64 != null && b64.isNotEmpty) {
                                  setDialogState(() {
                                    previewBase64 = b64;
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.maintext,
                                side: const BorderSide(color: Colors.white24),
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
                                style: const TextStyle(
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
                    style: const TextStyle(
                      color: AppColors.maintext,
                      fontSize: 13,
                    ),
                    onChanged: (val) {
                      if (val.contains('http') || val.startsWith('spotify:')) {
                        autoFetchFromLink();
                      }
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
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
                    style: const TextStyle(
                      color: AppColors.maintext,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
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
                        child: const Text(
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
      setState(() {
        _userPlaylists.removeWhere((e) => e.id == existing.id);
      });
      await _persistPlaylists();
      return;
    }

    if (action == 'save') {
      final url = urlCtrl.text.trim();
      if (url.isEmpty) return;

      var title = titleCtrl.text.trim();
      if (previewUrl == null && previewBase64 == null) {
        final meta = await _fetchPlaylistMetadata(url);
        previewUrl = meta.$2;
        if (title.isEmpty && meta.$1 != null) {
          title = meta.$1!;
        }
      }
      if (title.isEmpty) {
        title = 'Мой плейлист';
      }

      final updatedItem = _UserPlaylist(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        url: url,
        coverImageUrl: previewUrl,
        coverImageBase64: previewBase64,
      );

      if (!mounted) return;
      setState(() {
        if (existing != null) {
          final idx = _userPlaylists.indexWhere((e) => e.id == existing.id);
          if (idx >= 0) {
            _userPlaylists[idx] = updatedItem;
          } else {
            _userPlaylists.add(updatedItem);
          }
        } else {
          _userPlaylists.add(updatedItem);
        }
      });
      await _persistPlaylists();
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
                      color: _isSystemMusicPlaying
                          ? const Color(0xFF1DB954).withValues(alpha: 0.18)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isSystemMusicPlaying
                            ? const Color(0xFF1DB954).withValues(alpha: 0.45)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSystemMusicPlaying) ...[
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
                          _isSystemMusicPlaying
                              ? 'Играет на шторке'
                              : 'Шторка на паузе',
                          style: TextStyle(
                            color: _isSystemMusicPlaying
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
                        unawaited(
                          NotificationService.instance.sendMediaCommand(
                            'previous',
                          ),
                        );
                        Future.delayed(
                          const Duration(milliseconds: 350),
                          _checkPlaybackState,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _LargeMediaTransportBtn(
                      icon: _isSystemMusicPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      label: _isSystemMusicPlaying ? 'Пауза' : 'Играть',
                      isPrimary: true,
                      isActive: _isSystemMusicPlaying,
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
                        unawaited(
                          NotificationService.instance.sendMediaCommand(
                            'next',
                          ),
                        );
                        Future.delayed(
                          const Duration(milliseconds: 350),
                          _checkPlaybackState,
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
                  const Text(
                    'Мои плейлисты',
                    style: TextStyle(
                      color: AppColors.maintext,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openPlaylistDialog(),
                    child: const Text(
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
              if (_userPlaylists.isEmpty)
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.accentYellow,
                          size: 22,
                        ),
                        SizedBox(width: 10),
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
                      ..._userPlaylists.map((pl) {
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
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.accentYellow,
                                size: 28,
                              ),
                              SizedBox(height: 8),
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
      } catch (_) {}
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
                      Colors.black.withValues(alpha: hasCoverImage ? 0.88 : 0.45),
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
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 4),
                        ],
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
