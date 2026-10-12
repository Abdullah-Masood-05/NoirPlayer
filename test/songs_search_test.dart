// The Library songs search bar: the clear (x) button must empty the text
// field, not just the filter.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noir_player/screens/library/tabs/songs_tab.dart';

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
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SongsTab(onNavigateToPlayer: () {})),
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
}
