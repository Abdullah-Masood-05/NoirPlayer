import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'settings.dart';

final onAudioQueryProvider = Provider<OnAudioQuery>((ref) => OnAudioQuery());

/// Outcome of asking for access to the device's music.
enum LibraryAccess {
  /// Access was already granted before this launch.
  granted,

  /// The user granted access just now.
  newlyGranted,

  denied;

  bool get isGranted => this != denied;
}

/// Asks for media access once per launch, shared by every Library tab.
final libraryAccessProvider = FutureProvider<LibraryAccess>((ref) async {
  // iOS: there is no storage/microphone gate. The media-library permission
  // is requested by on_audio_query itself (NSAppleMusicUsageDescription).
  // (Permission.audio maps to the microphone on iOS.)
  if (defaultTargetPlatform == TargetPlatform.iOS) return LibraryAccess.granted;

  if (await Permission.audio.isGranted || await Permission.storage.isGranted) {
    return LibraryAccess.granted;
  }
  if (await Permission.audio.request().isGranted ||
      await Permission.storage.request().isGranted) {
    return LibraryAccess.newlyGranted;
  }
  return LibraryAccess.denied;
});

/// Every song on the device, sorted by title. Queried once and shared by the
/// Music and Audio tabs, the artist covers and the folder picker. Refresh
/// with `ref.refresh(librarySongsProvider.future)`.
final librarySongsProvider = FutureProvider<List<SongModel>>((ref) async {
  final access = await ref.watch(libraryAccessProvider.future);
  if (!access.isGranted) return const [];
  return ref
      .read(onAudioQueryProvider)
      .querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
});

/// Songs in the chosen music folder (the Library's "Music" tab).
final musicFolderSongsProvider = Provider<AsyncValue<List<SongModel>>>((ref) {
  final folder = ref.watch(settingsProvider.select((s) => s.musicFolderPath));
  return ref
      .watch(librarySongsProvider)
      .whenData(
        (songs) => songs
            .where((s) => AppSettings.isInFolder(folder, s.data))
            .toList(growable: false),
      );
});

/// Folders that contain songs, sorted, for the music folder picker.
final songFoldersProvider = Provider<List<String>>((ref) {
  final songs = ref.watch(librarySongsProvider).value ?? const <SongModel>[];
  final folders = <String>{};
  for (final s in songs) {
    final idx = s.data.lastIndexOf('/');
    if (idx > 0) folders.add(s.data.substring(0, idx));
  }
  return folders.toList()..sort();
});

final albumsProvider = FutureProvider<List<AlbumModel>>((ref) async {
  final access = await ref.watch(libraryAccessProvider.future);
  if (!access.isGranted) return const [];
  return ref.read(onAudioQueryProvider).queryAlbums();
});

final artistsProvider = FutureProvider<List<ArtistModel>>((ref) async {
  final access = await ref.watch(libraryAccessProvider.future);
  if (!access.isGranted) return const [];
  return ref.read(onAudioQueryProvider).queryArtists();
});

/// Artist id -> id of one of their songs, whose artwork is used as the
/// artist's cover. Built from the song list already loaded, instead of one
/// query per artist.
final artistCoverSongIdsProvider = Provider<Map<int, int>>((ref) {
  final songs = ref.watch(librarySongsProvider).value ?? const <SongModel>[];
  final covers = <int, int>{};
  for (final s in songs) {
    final artistId = s.artistId;
    if (artistId != null) covers.putIfAbsent(artistId, () => s.id);
  }
  return covers;
});

/// The songs of one album; disposed when its screen closes.
final albumSongsProvider = FutureProvider.autoDispose
    .family<List<SongModel>, int>(
      (ref, albumId) => ref
          .read(onAudioQueryProvider)
          .queryAudiosFrom(AudiosFromType.ALBUM_ID, albumId),
    );

/// The songs of one artist; disposed when its screen closes.
final artistSongsProvider = FutureProvider.autoDispose
    .family<List<SongModel>, int>(
      (ref, artistId) => ref
          .read(onAudioQueryProvider)
          .queryAudiosFrom(AudiosFromType.ARTIST_ID, artistId),
    );
