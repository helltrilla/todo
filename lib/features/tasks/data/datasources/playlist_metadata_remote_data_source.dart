import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/logging/app_logger.dart';
import 'package:todo/features/tasks/domain/entities/playlist_metadata.dart';

/// Contract for fetching playlist title, author, and cover art over network.
abstract interface class IPlaylistMetadataRemoteDataSource {
  Future<Result<PlaylistMetadata>> fetchMetadata(String rawUrl);
}

/// Remote data source implementation using Spotify/YouTube oEmbed APIs
/// and HTML OpenGraph tags (`og:title`, `og:image`) fallback.
class PlaylistMetadataRemoteDataSource
    implements IPlaylistMetadataRemoteDataSource {
  final http.Client _client;

  PlaylistMetadataRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<Result<PlaylistMetadata>> fetchMetadata(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return const Error(ServerFailure('URL не может быть пустым'));
    }

    var webUrl = trimmed;
    if (trimmed.startsWith('spotify:')) {
      final parts = trimmed.split(':');
      if (parts.length >= 3) {
        webUrl = 'https://open.spotify.com/${parts[1]}/${parts[2]}';
      }
    }

    final platform = PlaylistPlatform.fromUrl(webUrl);

    try {
      final lower = webUrl.toLowerCase();

      // 1. Spotify oEmbed API
      if (lower.contains('open.spotify.com')) {
        final oembedUri = Uri.parse(
          'https://open.spotify.com/oembed?url=${Uri.encodeComponent(webUrl)}',
        );
        final resp = await _client
            .get(oembedUri)
            .timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final title = (data['title'] as String?)?.trim();
          final thumb = (data['thumbnail_url'] as String?)?.trim();
          final author = (data['author_name'] as String?)?.trim();
          return Success(
            PlaylistMetadata(
              title: (title != null && title.isNotEmpty) ? title : 'Spotify Playlist',
              author: author,
              coverUrl: thumb,
              platform: PlaylistPlatform.spotify,
              sourceUrl: rawUrl,
            ),
          );
        }
      }

      // 2. YouTube oEmbed API
      if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
        final oembedUri = Uri.parse(
          'https://www.youtube.com/oembed?url=${Uri.encodeComponent(webUrl)}&format=json',
        );
        final resp = await _client
            .get(oembedUri)
            .timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final title = (data['title'] as String?)?.trim();
          final thumb = (data['thumbnail_url'] as String?)?.trim();
          final author = (data['author_name'] as String?)?.trim();
          return Success(
            PlaylistMetadata(
              title: (title != null && title.isNotEmpty) ? title : 'YouTube Playlist',
              author: author,
              coverUrl: thumb,
              platform: PlaylistPlatform.youtube,
              sourceUrl: rawUrl,
            ),
          );
        }
      }

      // 3. Generic OpenGraph HTML Scraper
      if (webUrl.startsWith('http://') || webUrl.startsWith('https://')) {
        final resp = await _client
            .get(
              Uri.parse(webUrl),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
              },
            )
            .timeout(const Duration(seconds: 4));

        if (resp.statusCode == 200) {
          final html = resp.body;
          final ogImageMatch =
              RegExp(
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

          final title = ogTitleMatch?.group(1)?.trim();
          final cover = ogImageMatch?.group(1)?.trim();

          if (title != null || cover != null) {
            return Success(
              PlaylistMetadata(
                title: (title != null && title.isNotEmpty) ? title : platform.badge,
                coverUrl: cover,
                platform: platform,
                sourceUrl: rawUrl,
              ),
            );
          }
        }
      }

      // Fallback: return platform badge default if valid URL
      return Success(
        PlaylistMetadata(
          title: platform.badge,
          platform: platform,
          sourceUrl: rawUrl,
        ),
      );
    } on TimeoutException {
      AppLogger.warning('Timeout fetching playlist metadata for $rawUrl');
      return const Error(NetworkFailure('Превышено время ожидания ответа сервера'));
    } on SocketException catch (e) {
      AppLogger.warning('Network error fetching playlist metadata for $rawUrl: $e');
      return Error(NetworkFailure('Нет сетевого подключения: ${e.message}'));
    } catch (e, st) {
      AppLogger.warning('Failed to fetch playlist metadata for $rawUrl', e, st);
      return Error(ServerFailure('Не удалось получить метаданные: $e'));
    }
  }
}
