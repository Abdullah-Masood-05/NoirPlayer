// Riverpod state: settings persistence, playlists, the artwork cache and the
// sleep timer.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noir_player/core/models/playlist_model.dart';
import 'package:noir_player/core/state/artwork.dart';
import 'package:noir_player/core/state/playlists.dart';
import 'package:noir_player/core/state/settings.dart';
import 'package:noir_player/core/state/sleep_timer.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({
  Map<String, Object> prefs = const {},
  List<PlaylistModel>? playlists,
  PlaylistRepository? repository,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(instance),
      if (playlists != null)
        initialPlaylistsProvider.overrideWithValue(playlists),
      if (repository != null)
        playlistRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

PlaylistSong _song(int id) => PlaylistSong(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  data: '/m/$id.mp3',
);

void main() {
  group('settings', () {
    test('defaults when nothing is saved', () async {
      final c = await _container();
      final s = c.read(settingsProvider);
      expect(s.themeMode, ThemeMode.system);
      expect(s.resumeLastSong, isTrue);
      expect(s.stopOnAppSwipe, isFalse);
      expect(s.playbackSpeed, 1.0);
      expect(s.seekIntervalSeconds, 10);
      expect(s.musicFolderPath, isNull);
    });

    test('loads saved values and sanitizes a bad seek interval', () async {
      final c = await _container(
        prefs: {
          'settings.themeMode': 'dark',
          'settings.playbackSpeed': 1.5,
          'settings.seekIntervalSeconds': 9999,
          'settings.musicFolderPath': '/storage/emulated/0/Songs',
          'settings.equalizerBandGains': ['1.5', 'x', '-2'],
        },
      );
      final s = c.read(settingsProvider);
      expect(s.themeMode, ThemeMode.dark);
      expect(s.playbackSpeed, 1.5);
      expect(s.seekIntervalSeconds, 10);
      expect(s.musicFolderLabel, 'Songs');
      expect(s.equalizerBandGains, [1.5, 0.0, -2.0]);
    });

    test('changes update state at once and are saved', () async {
      final c = await _container();
      final notifier = c.read(settingsProvider.notifier);

      await notifier.setThemeMode(ThemeMode.light);
      await notifier.setSeekIntervalSeconds(30);
      await notifier.setSeekIntervalSeconds(0); // ignored
      await notifier.setLastFmApiKey('  abc  ');
      await notifier.setMusicFolderPath('/m');
      await notifier.setMusicFolderPath(null);

      final s = c.read(settingsProvider);
      expect(s.themeMode, ThemeMode.light);
      expect(s.seekIntervalSeconds, 30);
      expect(s.lastFmApiKey, 'abc');
      expect(s.musicFolderPath, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.themeMode'), 'light');
      expect(prefs.getInt('settings.seekIntervalSeconds'), 30);
      expect(prefs.getString('settings.lastFmApiKey'), 'abc');
      expect(prefs.containsKey('settings.musicFolderPath'), isFalse);

      await notifier.setLastFmApiKey('');
      expect(prefs.containsKey('settings.lastFmApiKey'), isFalse);
    });

    test('a watcher of one field is not notified for another', () async {
      final c = await _container();
      var themeChanges = 0;
      c.listen(
        settingsProvider.select((s) => s.themeMode),
        (_, _) => themeChanges++,
      );
      await c.read(settingsProvider.notifier).setPlaybackSpeed(2.0);
      expect(themeChanges, 0);
      await c.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(themeChanges, 1);
    });

    test('music folder matching', () {
      expect(AppSettings.isInFolder(null, '/storage/Music/a.mp3'), isTrue);
      expect(AppSettings.isInFolder(null, '/storage/Download/a.mp3'), isFalse);
      expect(
        AppSettings.isInFolder('/storage/Songs', '/storage/songs/a.mp3'),
        isTrue,
      );
    });
  });

  group('playlists', () {
    late Directory dir;
    final repos = <PlaylistRepository>[];
    setUp(() => dir = Directory.systemTemp.createTempSync('noir_playlists'));
    tearDown(() async {
      // Let queued saves finish before their folder goes away.
      for (final r in repos) {
        await r.flush();
      }
      repos.clear();
      dir.deleteSync(recursive: true);
    });

    PlaylistRepository repo() {
      final r = PlaylistRepository(
        file: () async => File('${dir.path}/playlists.json'),
      );
      repos.add(r);
      return r;
    }

    test('Favourites is always first and unique', () async {
      final c = await _container(
        playlists: [
          PlaylistModel(name: 'Gym', songs: const []),
          PlaylistModel(name: 'Favourites', songs: const [], isFavourite: true),
        ],
        repository: repo(),
      );
      final names = c.read(playlistsProvider).map((p) => p.name).toList();
      expect(names, ['Favourites', 'Gym']);
    });

    test('creating respects the limit and rejects duplicate names', () async {
      final c = await _container(repository: repo());
      final n = c.read(playlistsProvider.notifier);
      expect(n.createPlaylist('Gym'), isTrue);
      expect(n.createPlaylist('gym'), isFalse);
      expect(n.createPlaylist('  '), isFalse);
      for (var i = 0; i < 3; i++) {
        expect(n.createPlaylist('P$i'), isTrue);
      }
      expect(
        c.read(playlistsProvider),
        hasLength(PlaylistsNotifier.maxPlaylists),
      );
      expect(n.createPlaylist('One too many'), isFalse);
    });

    test('changes replace the playlist instead of mutating it', () async {
      final c = await _container(repository: repo());
      final n = c.read(playlistsProvider.notifier)..createPlaylist('Gym');
      final before = c.read(playlistsProvider)[1];

      n.addSong(before, _song(1));
      n.addSong(before, _song(1)); // duplicate ignored

      final after = c.read(playlistsProvider)[1];
      expect(before.songs, isEmpty);
      expect(after.songs.map((s) => s.id), [1]);
      expect(() => after.songs.add(_song(2)), throwsUnsupportedError);

      n.removeSong(after, 1);
      expect(c.read(playlistsProvider)[1].songs, isEmpty);
    });

    test(
      'favourite hearts follow toggles; Favourites cannot be deleted',
      () async {
        final c = await _container(repository: repo());
        final n = c.read(playlistsProvider.notifier);

        expect(c.read(isFavouriteProvider(7)), isFalse);
        n.toggleFavourite(_song(7));
        expect(c.read(isFavouriteProvider(7)), isTrue);
        expect(c.read(favouriteIdsProvider), {7});
        n.toggleFavourite(_song(7));
        expect(c.read(isFavouriteProvider(7)), isFalse);

        n.deletePlaylist(n.favourites);
        expect(c.read(playlistsProvider).first.isFavourite, isTrue);
      },
    );

    test('changes are saved and load back', () async {
      final repository = repo();
      final c = await _container(repository: repository);
      final n = c.read(playlistsProvider.notifier)..createPlaylist('Gym');
      n.addSong(n.byName('Gym')!, _song(3));
      n.toggleFavourite(_song(4));
      await repository.flush();

      final loaded = await repo().load();
      expect(loaded.map((p) => p.name), ['Favourites', 'Gym']);
      expect(loaded[0].songs.single.id, 4);
      expect(loaded[1].songs.single.id, 3);
    });
  });

  group('artwork cache', () {
    test('fetches each item once and evicts the least recently used', () async {
      final calls = <String>[];
      final cache = ArtworkCache((id, type, size) async {
        calls.add('$id@$size');
        return id == 0 ? null : Uint8List.fromList([id]);
      }, maxEntries: 2);

      expect(await cache.load(1, ArtworkType.AUDIO, 200), [1]);
      expect(await cache.load(1, ArtworkType.AUDIO, 200), [1]);
      expect(cache.peek(1, ArtworkType.AUDIO, 200), [1]);
      expect(calls, ['1@200']);

      await cache.load(2, ArtworkType.AUDIO, 200);
      await cache.load(1, ArtworkType.AUDIO, 200); // 1 is now most recent
      await cache.load(3, ArtworkType.AUDIO, 200); // evicts 2
      expect(cache.length, 2);
      expect(cache.peek(2, ArtworkType.AUDIO, 200), isNull);
      await cache.load(2, ArtworkType.AUDIO, 200);
      expect(calls, ['1@200', '2@200', '3@200', '2@200']);
    });

    test(
      'no artwork and failures resolve to null and are not retried',
      () async {
        var calls = 0;
        final cache = ArtworkCache((id, type, size) async {
          calls++;
          if (id == 9) throw Exception('broken file');
          return null;
        });
        expect(await cache.load(0, ArtworkType.AUDIO, 200), isNull);
        expect(await cache.load(9, ArtworkType.AUDIO, 200), isNull);
        expect(await cache.load(9, ArtworkType.AUDIO, 200), isNull);
        expect(cache.isResolved(9, ArtworkType.AUDIO, 200), isTrue);
        expect(calls, 2);
      },
    );
  });

  testWidgets('sleep timer counts down and switches itself off', (
    tester,
  ) async {
    var fakeNow = DateTime(2026);
    SleepTimerNotifier.now = () => fakeNow;
    addTearDown(() => SleepTimerNotifier.now = DateTime.now);
    Future<void> advance(int seconds) async {
      for (var i = 0; i < seconds; i++) {
        fakeNow = fakeNow.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
    }

    final c = ProviderContainer();
    addTearDown(c.dispose);
    final timer = c.read(sleepTimerProvider.notifier);

    timer.start(const Duration(seconds: 3));
    expect(c.read(sleepTimerProvider), const Duration(seconds: 3));
    expect(timer.isActive, isTrue);

    await advance(1);
    expect(c.read(sleepTimerProvider), const Duration(seconds: 2));

    await advance(2);
    expect(c.read(sleepTimerProvider), isNull);
    expect(timer.isActive, isFalse);

    timer.start(const Duration(minutes: 5));
    timer.cancel();
    expect(c.read(sleepTimerProvider), isNull);
  });
}
