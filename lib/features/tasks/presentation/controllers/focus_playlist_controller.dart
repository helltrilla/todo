import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/logging/app_logger.dart';
import 'package:todo/features/tasks/domain/entities/playlist_metadata.dart';
import 'package:todo/features/tasks/domain/entities/user_playlist.dart';
import 'package:todo/features/tasks/domain/usecases/get_playlist_metadata_use_case.dart';

/// Presentation controller managing user-curated and preset music playlists
/// in the Focus Hub.
class FocusPlaylistController extends ChangeNotifier {
  static const _userPlaylistsKey = 'focus_user_playlists_v2';
  static const _legacyCustomPlaylistUrlKey = 'focus_custom_playlist_url';
  static const _legacyCustomPlaylistTitleKey = 'focus_custom_playlist_title';

  final SharedPreferences _prefs;
  final GetPlaylistMetadataUseCase _getMetadataUseCase;

  List<UserPlaylist> _playlists = [];
  bool _isLoadingMetadata = false;
  String? _errorMessage;

  FocusPlaylistController({
    required SharedPreferences prefs,
    required GetPlaylistMetadataUseCase getMetadataUseCase,
  })  : _prefs = prefs,
        _getMetadataUseCase = getMetadataUseCase {
    loadPlaylists();
  }

  List<UserPlaylist> get playlists => List.unmodifiable(_playlists);
  bool get isLoadingMetadata => _isLoadingMetadata;
  String? get errorMessage => _errorMessage;

  /// Loads playlists from persistence, runs legacy migrations,
  /// and lazily enriches items missing cover artwork.
  Future<void> loadPlaylists() async {
    final rawJson = _prefs.getString(_userPlaylistsKey);
    final loaded = <UserPlaylist>[];

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            loaded.add(UserPlaylist.fromJson(item));
          }
        }
      } catch (e, st) {
        AppLogger.warning('Failed to load user playlists from prefs', e, st);
      }
    } else {
      // Migrate legacy single custom playlist if present
      final legacyUrl = _prefs.getString(_legacyCustomPlaylistUrlKey);
      final legacyTitle =
          _prefs.getString(_legacyCustomPlaylistTitleKey) ?? 'Мой плейлист';
      if (legacyUrl != null && legacyUrl.isNotEmpty) {
        loaded.add(
          UserPlaylist(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: legacyTitle,
            url: legacyUrl,
          ),
        );
      }
    }

    if (loaded.isEmpty) {
      loaded.addAll(defaultPresets);
    }

    _playlists = loaded;
    notifyListeners();

    // Auto-fetch missing artwork in the background
    unawaited(_enrichMissingCovers());
  }

  static const List<UserPlaylist> defaultPresets = [
    UserPlaylist(
      id: 'preset_lofi',
      title: 'Lo-Fi Beats',
      url: 'https://open.spotify.com/playlist/0vvXsWCC9xrXsKd4FyS8kM',
    ),
    UserPlaylist(
      id: 'preset_deep_focus',
      title: 'Deep Focus',
      url: 'https://open.spotify.com/playlist/37i9dQZF1DWZeKCadgRdKQ',
    ),
    UserPlaylist(
      id: 'preset_synthwave',
      title: 'Synthwave Chill',
      url: 'https://open.spotify.com/playlist/37i9dQZF1DXdLEN7aqioXM',
    ),
    UserPlaylist(
      id: 'preset_apple_piano',
      title: 'Peaceful Piano',
      url:
          'https://music.apple.com/playlist/peaceful-piano/pl.784d5da438a04b76a08ec2284920fe14',
    ),
  ];

  Future<void> _enrichMissingCovers() async {
    var hasChanges = false;
    for (var i = 0; i < _playlists.length; i++) {
      final item = _playlists[i];
      if (item.coverImageUrl == null && item.coverImageBase64 == null) {
        final result = await _getMetadataUseCase(item.url);
        switch (result) {
          case Success(:final data):
            if (data.coverUrl != null && data.coverUrl!.isNotEmpty) {
              _playlists[i] = item.copyWith(coverImageUrl: data.coverUrl);
              hasChanges = true;
            }
          case Error():
            break;
        }
      }
    }
    if (hasChanges) {
      await _persistPlaylists();
      notifyListeners();
    }
  }

  Future<void> _persistPlaylists() async {
    try {
      final encoded = jsonEncode(
        _playlists.map((e) => e.toJson()).toList(),
      );
      await _prefs.setString(_userPlaylistsKey, encoded);
    } catch (e, st) {
      AppLogger.warning('Failed to persist playlists', e, st);
    }
  }

  /// Resolves title, author, and cover art for a playlist URL.
  Future<Result<PlaylistMetadata>> fetchMetadata(String url) async {
    _isLoadingMetadata = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getMetadataUseCase(url);

    _isLoadingMetadata = false;
    switch (result) {
      case Success():
        _errorMessage = null;
      case Error(:final failure):
        _errorMessage = failure.message;
    }
    notifyListeners();
    return result;
  }

  /// Adds a playlist resolved from a link, automatically applying fetched metadata.
  Future<Result<UserPlaylist>> addPlaylistByUrl(
    String url, {
    String? customTitle,
    String? customCoverBase64,
  }) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      return const Error(ServerFailure('URL плейлиста не может быть пустым'));
    }

    final metaResult = await fetchMetadata(trimmedUrl);
    UserPlaylist created;

    switch (metaResult) {
      case Success(:final data):
        final finalTitle = (customTitle != null && customTitle.trim().isNotEmpty)
            ? customTitle.trim()
            : data.title;
        created = UserPlaylist(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: finalTitle,
          url: trimmedUrl,
          coverImageUrl: data.coverUrl,
          coverImageBase64: customCoverBase64,
        );
      case Error():
        final finalTitle = (customTitle != null && customTitle.trim().isNotEmpty)
            ? customTitle.trim()
            : 'Мой плейлист';
        created = UserPlaylist(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: finalTitle,
          url: trimmedUrl,
          coverImageBase64: customCoverBase64,
        );
    }

    await addPlaylist(created);
    return Success(created);
  }

  Future<void> addPlaylist(UserPlaylist playlist) async {
    _playlists.add(playlist);
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> updatePlaylist(UserPlaylist playlist) async {
    final idx = _playlists.indexWhere((e) => e.id == playlist.id);
    if (idx >= 0) {
      _playlists[idx] = playlist;
    } else {
      _playlists.add(playlist);
    }
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((e) => e.id == id);
    await _persistPlaylists();
    notifyListeners();
  }
}
