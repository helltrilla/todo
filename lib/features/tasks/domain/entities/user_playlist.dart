import 'package:flutter/material.dart';
import 'package:todo/features/tasks/domain/entities/playlist_metadata.dart';

/// Immutable domain entity representing a user-saved music playlist.
class UserPlaylist {
  final String id;
  final String title;
  final String url;
  final String? coverImageUrl;
  final String? coverImageBase64;

  const UserPlaylist({
    required this.id,
    required this.title,
    required this.url,
    this.coverImageUrl,
    this.coverImageBase64,
  });

  PlaylistPlatform get platform => PlaylistPlatform.fromUrl(url);

  String get serviceBadge => platform.badge;

  List<Color> get fallbackGradient => platform.gradient;

  UserPlaylist copyWith({
    String? id,
    String? title,
    String? url,
    String? coverImageUrl,
    String? coverImageBase64,
  }) {
    return UserPlaylist(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImageBase64: coverImageBase64 ?? this.coverImageBase64,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'coverImageUrl': coverImageUrl,
    'coverImageBase64': coverImageBase64,
  };

  factory UserPlaylist.fromJson(Map<String, dynamic> json) => UserPlaylist(
    id:
        (json['id'] as String?) ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    title: (json['title'] as String?) ?? 'Мой плейлист',
    url: (json['url'] as String?) ?? '',
    coverImageUrl: json['coverImageUrl'] as String?,
    coverImageBase64: json['coverImageBase64'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPlaylist &&
          other.id == id &&
          other.title == title &&
          other.url == url &&
          other.coverImageUrl == coverImageUrl &&
          other.coverImageBase64 == coverImageBase64);

  @override
  int get hashCode =>
      Object.hash(id, title, url, coverImageUrl, coverImageBase64);
}
