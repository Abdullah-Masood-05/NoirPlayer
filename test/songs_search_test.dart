// The Library songs search bar: the clear (x) button must empty the text
// field, not just the filter.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noir_player/core/state/library.dart';
import 'package:noir_player/core/state/settings.dart';
import 'package:noir_player/screens/library/tabs/songs_tab.dart';
import 'package:on_audio_query/on_audio_query.dart' show SongModel;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // permission_handler talks over this channel. Report every permission as
  // denied so the tab never reaches on_audio_query or audio_service.
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissions, (MethodCall call) async {
          switch (call.method) {
            case 'checkPermissionStatus':
              return 0; // denied
            case 'requestPermissions':
              final requested = call.arguments as List<dynamic>;
              return <int, int>{for (final p in requested) p as int: 0};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissions, null);
  });

  testWidgets('clear button empties the search field', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(body: SongsTab(onNavigateToPlayer: () {})),
        ),
      ),
    );
    await tester.pump();

    final field = find.byType(TextField);
    await tester.enterText(field, 'aashiyan');
    await tester.pump();

    expect(find.text('aashiyan'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.text('aashiyan'), findsNothing);
    expect(find.byIcon(Icons.clear), findsNothing);
  });

  testWidgets('the header counts the songs listed and follows the search', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    SongModel song(int id, String title, String artist) => SongModel({
      '_id': id,
      'title': title,
      'artist': artist,
      '_data': '/storage/emulated/0/Music/$title.mp3',
      'duration': 185000,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          libraryAccessProvider.overrideWith((ref) => LibraryAccess.granted),
          librarySongsProvider.overrideWith(
            (ref) => [
              song(1, 'Aashiyan', 'Pritam'),
              song(2, 'Blue Eyes', 'Honey Singh'),
              song(3, 'Kesariya', 'Arijit Singh'),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: SongsTab(onNavigateToPlayer: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 songs'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Pritam · 3:05'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'singh');
    await tester.pumpAndSettle();
    expect(find.text('2 songs'), findsOneWidget);
    expect(find.text('Aashiyan'), findsNothing);

    // Every row has a menu with Add to playlist.
    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    expect(find.text('Add to playlist…'), findsOneWidget);
  });
}
