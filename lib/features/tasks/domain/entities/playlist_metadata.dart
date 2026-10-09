import 'package:flutter/material.dart';

enum PlaylistPlatform {
  spotify('SPOTIFY', [Color(0xFF1DB954), Color(0xFF0E3B22)]),
  yandex('ЯНДЕКС', [Color(0xFFF59E0B), Color(0xFF451A03)]),
  appleMusic('APPLE MUSIC', [Color(0xFFFA243C), Color(0xFF4C0519)]),
  youtube('YOUTUBE', [Color(0xFFEF4444), Color(0xFF450A0A)]),
  vk('VK МУЗЫКА', [Color(0xFF0077FF), Color(0xFF002A66)]),
  other('ПЛЕЙЛИСТ', [Color(0xFF6366F1), Color(0xFF1E1B4B)]);

  final String badge;
  final List<Color> gradient;

  const PlaylistPlatform(this.badge, this.gradient);

  static PlaylistPlatform fromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('spotify') || lower.startsWith('spotify:')) {
      return PlaylistPlatform.spotify;
    }
    if (lower.contains('yandex')) {
      return PlaylistPlatform.yandex;
    }
    if (lower.contains('apple.com') || lower.startsWith('music:')) {
      return PlaylistPlatform.appleMusic;
    }
    if (lower.contains('youtube') || lower.contains('youtu.be')) {
      return PlaylistPlatform.youtube;
    }
    if (lower.contains('vk.com') || lower.contains('boom')) {
      return PlaylistPlatform.vk;
    }
    return PlaylistPlatform.other;
  }
}

/// Immutable domain entity representing resolved metadata for a playlist link.
class PlaylistMetadata {
  final String title;
  final String? author;
  final String? coverUrl;
  final PlaylistPlatform platform;
  final String sourceUrl;

  const PlaylistMetadata({
    required this.title,
    required this.platform,
    required this.sourceUrl,
    this.author,
    this.coverUrl,
  });

  String get serviceBadge => platform.badge;
  List<Color> get fallbackGradient => platform.gradient;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistMetadata &&
          other.title == title &&
          other.author == author &&
          other.coverUrl == coverUrl &&
          other.platform == platform &&
          other.sourceUrl == sourceUrl);

  @override
  int get hashCode => Object.hash(title, author, coverUrl, platform, sourceUrl);
}
