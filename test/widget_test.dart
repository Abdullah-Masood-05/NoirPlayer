// Unit tests for Noir Player.
//
// The app's widgets depend on platform plugins (audio_service, on_audio_query)
// that aren't available in the widget-test environment, so instead of pumping
// the whole app we cover plain-Dart logic here.

import 'package:flutter_test/flutter_test.dart';
import 'package:noir_player/core/models/discovered_track.dart';

void main() {
  test('DiscoveredTrack round-trips through JSON', () {
    final track = DiscoveredTrack(
      name: 'Aashiyan',
      artist: 'Shreya Ghoshal',
      imageUrl: 'https://example.com/art.jpg',
      youtubeVideoId: 'abc123',
      streamUrl: 'https://example.com/stream.mp3',
    );

    final restored = DiscoveredTrack.fromJson(track.toJson());

    expect(restored.name, track.name);
    expect(restored.artist, track.artist);
    expect(restored.imageUrl, track.imageUrl);
    expect(restored.youtubeVideoId, track.youtubeVideoId);
    expect(restored.streamUrl, track.streamUrl);
  });
}
