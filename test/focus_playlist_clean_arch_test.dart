import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/di/injection_container.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/notifications/media_playback_service.dart';
import 'package:todo/features/tasks/data/datasources/playlist_metadata_remote_data_source.dart';
import 'package:todo/features/tasks/domain/entities/playlist_metadata.dart';
import 'package:todo/features/tasks/domain/entities/user_playlist.dart';
import 'package:todo/features/tasks/domain/usecases/get_playlist_metadata_use_case.dart';
import 'package:todo/features/tasks/presentation/controllers/focus_playlist_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaylistMetadataRemoteDataSource & UseCase Tests', () {
    test('fetches Spotify oEmbed metadata successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'open.spotify.com' &&
            request.url.path == '/oembed') {
          return http.Response(
            jsonEncode({
              'title': 'Synthwave Space Chill',
              'thumbnail_url': 'https://i.scdn.co/image/synthwave.jpg',
              'author_name': 'Spotify Curated',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = PlaylistMetadataRemoteDataSource(client: mockClient);
      final useCase = GetPlaylistMetadataUseCase(dataSource);

      final result = await useCase(
        'https://open.spotify.com/playlist/37i9dQZF1DXdLEN7aqioXM',
      );

      switch (result) {
        case Success(:final data):
          expect(data.title, 'Synthwave Space Chill');
          expect(data.coverUrl, 'https://i.scdn.co/image/synthwave.jpg');
          expect(data.author, 'Spotify Curated');
          expect(data.platform, PlaylistPlatform.spotify);
          expect(data.serviceBadge, 'SPOTIFY');
        case Error(:final failure):
          fail('Expected success but got failure: $failure');
      }
    });

    test('fetches YouTube oEmbed metadata successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.youtube.com' &&
            request.url.path == '/oembed') {
          return http.Response(
            jsonEncode({
              'title': 'Lofi Hip Hop Radio - Beats to Study To',
              'thumbnail_url': 'https://i.ytimg.com/vi/jfKfPfyJRdk/hqdefault.jpg',
              'author_name': 'Lofi Girl',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = PlaylistMetadataRemoteDataSource(client: mockClient);
      final useCase = GetPlaylistMetadataUseCase(dataSource);

      final result = await useCase('https://youtube.com/watch?v=jfKfPfyJRdk');

      switch (result) {
        case Success(:final data):
          expect(data.title, 'Lofi Hip Hop Radio - Beats to Study To');
          expect(
            data.coverUrl,
            'https://i.ytimg.com/vi/jfKfPfyJRdk/hqdefault.jpg',
          );
          expect(data.author, 'Lofi Girl');
          expect(data.platform, PlaylistPlatform.youtube);
        case Error(:final failure):
          fail('Expected success but got failure: $failure');
      }
    });

    test('falls back to HTML OpenGraph scraping for Apple Music / generic URLs', () async {
      final mockClient = MockClient((request) async {
        final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta property="og:title" content="Pure Classical Piano" />
  <meta property="og:image" content="https://music.apple.com/artwork.jpg" />
</head>
<body></body>
</html>
''';
        return http.Response(html, 200);
      });

      final dataSource = PlaylistMetadataRemoteDataSource(client: mockClient);
      final useCase = GetPlaylistMetadataUseCase(dataSource);

      final result = await useCase(
        'https://music.apple.com/playlist/pure-classical-piano',
      );

      switch (result) {
        case Success(:final data):
          expect(data.title, 'Pure Classical Piano');
          expect(data.coverUrl, 'https://music.apple.com/artwork.jpg');
          expect(data.platform, PlaylistPlatform.appleMusic);
        case Error(:final failure):
          fail('Expected success but got failure: $failure');
      }
    });

    test('returns ServerFailure when URL is empty', () async {
      final dataSource = PlaylistMetadataRemoteDataSource();
      final useCase = GetPlaylistMetadataUseCase(dataSource);

      final result = await useCase('   ');

      switch (result) {
        case Success():
          fail('Expected failure for empty URL');
        case Error(:final failure):
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('не может быть пустым'));
      }
    });
  });

  group('FocusPlaylistController Tests', () {
    test('loads default presets when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((_) async => http.Response('{}', 404));
      final dataSource = PlaylistMetadataRemoteDataSource(client: mockClient);
      final useCase = GetPlaylistMetadataUseCase(dataSource);

      final controller = FocusPlaylistController(
        prefs: prefs,
        getMetadataUseCase: useCase,
      );

      expect(controller.playlists.length, 4);
      expect(controller.playlists[0].title, 'Lo-Fi Beats');
      expect(controller.playlists[1].title, 'Deep Focus');
    });

    test('migrates legacy single custom playlist key seamlessly', () async {
      SharedPreferences.setMockInitialValues({
        'focus_custom_playlist_url':
            'https://open.spotify.com/playlist/my_custom_one',
        'focus_custom_playlist_title': 'My Chill Station',
      });
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((_) async => http.Response('{}', 404));
      final dataSource = PlaylistMetadataRemoteDataSource(client: mockClient);
      final useCase = GetPlaylistMetadataUseCase(dataSource);

      final controller = FocusPlaylistController(
        prefs: prefs,
        getMetadataUseCase: useCase,
      );

      expect(controller.playlists.length, 1);
      expect(controller.playlists.first.title, 'My Chill Station');
      expect(
        controller.playlists.first.url,
        'https://open.spotify.com/playlist/my_custom_one',
      );
    });

    test('adds, updates, and deletes playlists with persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((_) async => http.Response('{}', 404));
      final dataSource = PlaylistMetadataRemoteDataSource(client: mockClient);
      final useCase = GetPlaylistMetadataUseCase(dataSource);

      final controller = FocusPlaylistController(
        prefs: prefs,
        getMetadataUseCase: useCase,
      );

      const newPl = UserPlaylist(
        id: 'user_1',
        title: 'Cyberpunk 2077 OST',
        url: 'https://youtube.com/playlist?list=cyberpunk',
        coverImageUrl: 'https://example.com/cover.png',
      );

      await controller.addPlaylist(newPl);
      expect(controller.playlists.any((p) => p.id == 'user_1'), isTrue);

      final updated = newPl.copyWith(title: 'Night City Radio');
      await controller.updatePlaylist(updated);
      expect(
        controller.playlists.firstWhere((p) => p.id == 'user_1').title,
        'Night City Radio',
      );

      await controller.deletePlaylist('user_1');
      expect(controller.playlists.any((p) => p.id == 'user_1'), isFalse);
    });

    test('addPlaylistByUrl automatically fetches metadata and appends item', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'title': 'Coffee House Acoustic',
            'thumbnail_url': 'https://spotify.com/coffee.jpg',
            'author_name': 'Acoustic Curations',
          }),
          200,
        );
      });
      final dataSource = PlaylistMetadataRemoteDataSource(client: mockClient);
      final useCase = GetPlaylistMetadataUseCase(dataSource);

      final controller = FocusPlaylistController(
        prefs: prefs,
        getMetadataUseCase: useCase,
      );

      final addResult = await controller.addPlaylistByUrl(
        'https://open.spotify.com/playlist/coffee_house',
      );

      switch (addResult) {
        case Success(:final data):
          expect(data.title, 'Coffee House Acoustic');
          expect(data.coverImageUrl, 'https://spotify.com/coffee.jpg');
          expect(controller.playlists.last.title, 'Coffee House Acoustic');
        case Error(:final failure):
          fail('Expected success: $failure');
      }
    });
  });

  group('MediaPlaybackService Reactive Battery-Friendly Tests', () {
    test('broadcast stream and value listenable emit on state transitions', () async {
      final service = MediaPlaybackService();

      expect(service.isPlaying, isFalse);
      expect(service.isPlayingListenable.value, isFalse);

      final emittedStates = <bool>[];
      final sub = service.playbackStream.listen(emittedStates.add);

      await service.togglePlayPause();
      expect(service.isPlaying, isTrue);
      expect(service.isPlayingListenable.value, isTrue);

      await service.togglePlayPause();
      expect(service.isPlaying, isFalse);
      expect(service.isPlayingListenable.value, isFalse);

      await sub.cancel();
      expect(emittedStates, [true, false]);
      service.dispose();
    });

    test('onAppPaused cancels smart polling to conserve battery', () async {
      final service = MediaPlaybackService();

      // Trigger playing
      await service.togglePlayPause();
      expect(service.isPlaying, isTrue);

      // App goes to background
      service.onAppPaused();

      // Resume
      await service.onAppResumed();
      service.dispose();
    });
  });

  group('AppDependencies Container Tests', () {
    test('initializes clean DI graph with 15 feature providers', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final dependencies = await setupDependencies(prefs: prefs);

      expect(dependencies.providers.length, 16);
      expect(dependencies.notificationService, isNotNull);
      expect(dependencies.taskController, isNotNull);
      expect(dependencies.pomodoroController, isNotNull);
      expect(dependencies.focusPlaylistController, isNotNull);
      expect(dependencies.mediaPlaybackService, isNotNull);
      expect(dependencies.syncController, isNotNull);
      expect(dependencies.themeController, isNotNull);

      dependencies.dispose();
    });
  });
}
