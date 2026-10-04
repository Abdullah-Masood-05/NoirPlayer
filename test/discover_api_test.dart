// Discover's request building and response parsing, against a mock HTTP
// client: no network, no platform plugins.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noir_player/core/services/discover_api.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Matcher throwsDiscover(String message) => throwsA(
  isA<DiscoverException>().having((e) => e.message, 'message', message),
);

void main() {
  late List<http.Request> requests;

  /// A [DiscoverApi] whose requests are recorded and answered by [handler].
  DiscoverApi api(
    Future<http.Response> Function(http.Request request) handler, {
    DiscoverKeys? keys,
  }) {
    requests = [];
    final client = MockClient((request) {
      requests.add(request);
      return handler(request);
    });
    return DiscoverApi(
      keys: () => keys ?? DiscoverKeys(),
      client: client,
      retryDelay: Duration.zero,
    );
  }

  group('through the backend (no keys of your own)', () {
    test('the chart is GET /api/tracks and parses chart-shaped artists', () async {
      final discover = api(
        (_) async => jsonResponse({
          'tracks': {
            'track': [
              {
                'name': 'Numb',
                'artist': {'name': 'Linkin Park'},
                'url': 'https://www.last.fm/music/Linkin+Park/_/Numb',
              },
            ],
          },
        }),
      );

      final tracks = await discover.fetchTrending();

      expect(requests, hasLength(1));
      final url = requests.single.url;
      expect(url.scheme, 'https');
      expect(url.host, 'noir-player-api.vercel.app');
      expect(url.path, '/api/tracks');
      expect(url.queryParameters, isEmpty);
      expect(requests.single.followRedirects, isFalse);
      expect(tracks, hasLength(1));
      expect(tracks.single.name, 'Numb');
      expect(tracks.single.artist, 'Linkin Park');
      expect(tracks.single.imageUrl, '');
    });

    test('a search sends ?q= trimmed and parses search-shaped artists', () async {
      final discover = api(
        (_) async => jsonResponse({
          'results': {
            'trackmatches': {
              'track': [
                {'name': 'Numb', 'artist': 'Linkin Park'},
                {'name': 'NUMB', 'artist': 'Givēon'},
              ],
            },
          },
        }),
      );

      final tracks = await discover.search('  numb  ');

      expect(requests.single.url.path, '/api/tracks');
      expect(requests.single.url.queryParameters, {'q': 'numb'});
      expect(tracks.map((t) => t.artist), ['Linkin Park', 'Givēon']);
    });

    test('an empty search makes no request', () async {
      final discover = api((_) async => jsonResponse({}));
      expect(await discover.search('   '), isEmpty);
      expect(requests, isEmpty);
    });

    test('a search the backend would refuse is refused before sending', () async {
      final discover = api((_) async => jsonResponse({}));
      final message =
          "That search is too long or contains characters it can't use.";

      await expectLater(discover.search('a' * 201), throwsDiscover(message));
      await expectLater(discover.search('bad\u0007query'), throwsDiscover(message));
      expect(requests, isEmpty);
    });

    test("the backend's error message is shown as it comes", () async {
      final discover = api(
        (_) async => jsonResponse({
          'error': "Discover isn't available right now. Try again later.",
        }, 503),
      );

      await expectLater(
        discover.fetchTrending(),
        throwsDiscover("Discover isn't available right now. Try again later."),
      );
    });

    test('an error without a message gets a generic one', () async {
      final discover = api((_) async => jsonResponse({}, 500));
      await expectLater(
        discover.fetchTrending(),
        throwsDiscover(
          "Noir Player's server couldn't handle that. Try again later.",
        ),
      );
    });

    test('a body that is not a JSON object is reported, not parsed', () async {
      final discover = api((_) async => http.Response('<html>oops</html>', 502));
      await expectLater(
        discover.fetchTrending(),
        throwsDiscover("Noir Player's server sent back something unexpected."),
      );
    });

    test('an unreachable server is reported', () async {
      final discover = api((_) async => throw http.ClientException('offline'));
      await expectLater(
        discover.fetchTrending(),
        throwsDiscover(
          "Couldn't reach Noir Player's server. Check your connection and try again.",
        ),
      );
    });

    test('the video search is GET /api/video?q=<song artist>', () async {
      final discover = api(
        (_) async => jsonResponse({
          'items': [
            {
              'id': {'videoId': 'kXYiU_JCYtU'},
            },
          ],
        }),
      );

      final id = await discover.findVideoId('Numb', 'Linkin Park');

      expect(id, 'kXYiU_JCYtU');
      expect(requests.single.url.path, '/api/video');
      expect(requests.single.url.queryParameters, {'q': 'Numb Linkin Park'});
    });

    test('no video found is reported', () async {
      final discover = api((_) async => jsonResponse({'items': []}));
      await expectLater(
        discover.findVideoId('Numb', 'Linkin Park'),
        throwsDiscover('No matching YouTube video was found.'),
      );
    });

    test('resolve asks again while processing, then returns the link', () async {
      var calls = 0;
      final discover = api((_) async {
        calls++;
        return calls < 3
            ? jsonResponse({'status': 'processing'})
            : jsonResponse({'link': 'https://cdn.example.com/song.mp3'});
      });

      final link = await discover.resolveAudioLink('kXYiU_JCYtU');

      expect(link, 'https://cdn.example.com/song.mp3');
      expect(requests, hasLength(3));
      expect(requests.first.url.path, '/api/resolve');
      expect(requests.first.url.queryParameters, {'id': 'kXYiU_JCYtU'});
    });

    test('resolve gives up after four processing answers', () async {
      final discover = api((_) async => jsonResponse({'status': 'processing'}));
      await expectLater(
        discover.resolveAudioLink('kXYiU_JCYtU'),
        throwsA(isA<DiscoverException>()),
      );
      expect(requests, hasLength(4));
    });

    test('resolve refuses a malformed video id without sending it', () async {
      final discover = api((_) async => jsonResponse({}));
      await expectLater(
        discover.resolveAudioLink('../etc/pass'),
        throwsA(isA<DiscoverException>()),
      );
      expect(requests, isEmpty);
    });

    test('a link carrying one of your keys is rejected', () async {
      final discover = api(
        (_) async =>
            jsonResponse({'link': 'https://cdn.example.com/a.mp3?k=my%2Dlastfm'}),
        keys: DiscoverKeys(lastFm: 'my-lastfm'),
      );
      await expectLater(
        discover.resolveAudioLink('kXYiU_JCYtU'),
        throwsDiscover(
          "The audio service sent back a link that isn't safe to use.",
        ),
      );
    });
  });

  group('directly, with your own keys', () {
    test('Last.fm search goes to Last.fm with your key and fetches art', () async {
      final discover = api((request) async {
        if (request.url.queryParameters['method'] == 'track.getInfo') {
          return jsonResponse({
            'track': {
              'album': {
                'image': [
                  {'#text': 'https://img.example.com/small.jpg'},
                  {'#text': 'https://img.example.com/large.jpg'},
                ],
              },
            },
          });
        }
        return jsonResponse({
          'results': {
            'trackmatches': {
              'track': [
                {'name': 'Numb', 'artist': 'Linkin Park'},
              ],
            },
          },
        });
      }, keys: DiscoverKeys(lastFm: '  my-lastfm  '));

      final tracks = await discover.search('numb');

      final search = requests.first.url;
      expect(search.host, 'ws.audioscrobbler.com');
      expect(search.queryParameters['method'], 'track.search');
      expect(search.queryParameters['track'], 'numb');
      expect(search.queryParameters['api_key'], 'my-lastfm');
      expect(search.queryParameters['format'], 'json');
      expect(tracks.single.imageUrl, 'https://img.example.com/large.jpg');
      expect(
        requests.where((r) => r.url.host == 'noir-player-api.vercel.app'),
        isEmpty,
      );
    });

    test('a Last.fm error answer is reported', () async {
      final discover = api(
        (_) async => jsonResponse({'error': 10, 'message': 'Invalid API key'}),
        keys: DiscoverKeys(lastFm: 'bad'),
      );
      await expectLater(
        discover.fetchTrending(),
        throwsA(isA<DiscoverException>()),
      );
    });

    test('only the services you have a key for skip the backend', () async {
      final discover = api((request) async {
        if (request.url.host == 'www.googleapis.com') {
          return jsonResponse({
            'items': [
              {
                'id': {'videoId': 'kXYiU_JCYtU'},
              },
            ],
          });
        }
        return jsonResponse({'link': 'https://cdn.example.com/song.mp3'});
      }, keys: DiscoverKeys(youtube: 'my-youtube'));

      final id = await discover.findVideoId('Numb', 'Linkin Park');
      final link = await discover.resolveAudioLink(id);

      expect(requests[0].url.host, 'www.googleapis.com');
      expect(requests[0].url.path, '/youtube/v3/search');
      expect(requests[0].url.queryParameters['key'], 'my-youtube');
      expect(requests[0].url.queryParameters['q'], 'Numb Linkin Park');
      expect(requests[1].url.host, 'noir-player-api.vercel.app');
      expect(requests[1].url.path, '/api/resolve');
      expect(link, 'https://cdn.example.com/song.mp3');
    });

    test('RapidAPI is called with your key in headers', () async {
      final discover = api(
        (_) async => jsonResponse({'link': 'https://cdn.example.com/song.mp3'}),
        keys: DiscoverKeys(rapidApi: 'my-rapid'),
      );

      await discover.resolveAudioLink('kXYiU_JCYtU');

      final request = requests.single;
      expect(request.url.host, 'youtube-mp36.p.rapidapi.com');
      expect(request.url.path, '/dl');
      expect(request.url.queryParameters, {'id': 'kXYiU_JCYtU'});
      expect(request.headers['X-RapidAPI-Key'], 'my-rapid');
      expect(request.headers['X-RapidAPI-Host'], 'youtube-mp36.p.rapidapi.com');
    });

    test('a link echoing your RapidAPI key is rejected', () async {
      final discover = api(
        (_) async =>
            jsonResponse({'link': 'https://cdn.example.com/x.mp3?key=my-rapid'}),
        keys: DiscoverKeys(rapidApi: 'my-rapid'),
      );
      await expectLater(
        discover.resolveAudioLink('kXYiU_JCYtU'),
        throwsA(isA<DiscoverException>()),
      );
    });
  });

  group('parsing', () {
    test('a single search match sent as an object is still a list', () {
      final tracks = parseTracks({
        'results': {
          'trackmatches': {
            'track': {'name': 'Song', 'artist': 'Artist'},
          },
        },
      }, search: true);
      expect(tracks.single.name, 'Song');
    });

    test('empty search results stay empty; a malformed chart is an error', () {
      expect(
        parseTracks({
          'results': {
            'trackmatches': {'track': []},
          },
        }, search: true),
        isEmpty,
      );
      expect(
        () => parseTracks({}, search: false),
        throwsA(isA<DiscoverException>()),
      );
    });

    test('video ids must be exactly eleven URL-safe characters', () {
      Map<String, dynamic> answer(String id) => {
        'items': [
          {
            'id': {'videoId': id},
          },
        ],
      };
      expect(parseVideoId(answer('abcDEF_12-3')), 'abcDEF_12-3');
      for (final bad in ['../bad', 'short', 'abcDEF_12-34', 'abc DEF_12-']) {
        expect(
          () => parseVideoId(answer(bad)),
          throwsA(isA<DiscoverException>()),
        );
      }
    });

    test('resolution: ready, processing, or an error', () {
      expect(parseResolution({'status': 'processing'}), isNull);
      expect(
        parseResolution({
          'link': 'https://audio.example.com/song.mp3',
          'status': 'processing',
        }),
        'https://audio.example.com/song.mp3',
      );
      for (final root in <Map<String, dynamic>>[
        {},
        {'status': 'failed'},
        {'link': 42},
        {'link': 'http://audio.example.com/song.mp3'},
      ]) {
        expect(() => parseResolution(root), throwsA(isA<DiscoverException>()));
      }
    });

    test('audio links must be HTTPS to a public DNS name', () {
      for (final url in [
        'http://audio.example.com/song',
        'https://localhost/song',
        'https://a.localhost/song',
        'https://127.0.0.1/song',
        'https://192.168.1.2/song',
        'https://[::1]/song',
        'https://2130706433/song',
        'https://0177.0.0.1/song',
        'https://user@audio.example.com/song',
        'https://audio.example.com:80/song',
        'https://audio.example.com\\@localhost/song',
        'https://audio.local/song',
        'https://audio.example.com./song',
        'https://audio.example.com/song#fragment',
        'https://audio.example.com/song\n',
      ]) {
        expect(isSafeAudioLink(url), isFalse, reason: url);
      }
      expect(
        isSafeAudioLink('https://audio.example.com/song.mp3?token=abc%20def'),
        isTrue,
      );
      expect(isSafeAudioLink('https://audio.example.com:443/song'), isTrue);
    });

    test('keys are caught raw or percent-encoded; empty keys are ignored', () {
      expect(
        () => rejectCredentialsInLink('https://a.example.com/?k=secret', [
          'secret',
        ]),
        throwsA(isA<DiscoverException>()),
      );
      expect(
        () => rejectCredentialsInLink('https://a.example.com/?k=s%65cret', [
          'secret',
        ]),
        throwsA(isA<DiscoverException>()),
      );
      rejectCredentialsInLink('https://a.example.com/song.mp3', ['', '', '']);
    });

    test('search limits match the backend', () {
      expect(validSearchQuery('  numb '), 'numb');
      expect(validSearchQuery('a' * 200), 'a' * 200);
      expect(validSearchQuery('a' * 201), isNull);
      expect(validSearchQuery('tab\there'), isNull);
      expect(validSearchQuery('   '), isNull);
    });

    test('video queries are cleaned and cut to the backend limit', () {
      expect(backendVideoQuery('Song\nName  Artist'), 'Song Name  Artist');
      expect(backendVideoQuery('a' * 300).length, 200);
      // A character outside the BMP straddling the limit is not split.
      final straddling = '${'a' * 199}\u{1F3B5}tail';
      final cut = backendVideoQuery(straddling);
      expect(cut, 'a' * 199);
    });

    test('backend error bodies give their message', () {
      expect(backendErrorMessage({'error': ' Try later. '}), 'Try later.');
      expect(
        backendErrorMessage({'error': 7}),
        "Noir Player's server couldn't handle that. Try again later.",
      );
    });
  });
}
