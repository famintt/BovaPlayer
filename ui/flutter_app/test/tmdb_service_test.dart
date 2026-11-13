import 'dart:convert';

import 'package:bova_player_flutter/core/config/env_config.dart';
import 'package:bova_player_flutter/features/discover/models/discover_feed.dart';
import 'package:bova_player_flutter/features/discover/services/tmdb_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
    EnvConfig.applyTmdbCredential('');
  });

  tearDown(() {
    EnvConfig.applyTmdbCredential('');
    dotenv.clean();
  });

  test('missing TMDB endpoints use official defaults', () {
    expect(EnvConfig.tmdbBaseUrl, 'https://api.themoviedb.org/3');
    expect(EnvConfig.tmdbImageBaseUrl, 'https://image.tmdb.org/t/p/');
  });

  final invalidEndpoints = <String, String>{
    'empty CI secrets': '',
    'whitespace': '   ',
    'relative path': '/3',
    'missing scheme': 'api.themoviedb.org/3',
    'missing host': 'https://',
    'unsupported scheme': 'ftp://example.test/3',
    'malformed URI': 'https://[invalid',
  };
  for (final entry in invalidEndpoints.entries) {
    test('${entry.key} use official TMDB endpoints', () {
      dotenv.testLoad(
        mergeWith: {
          'TMDB_BASE_URL': entry.value,
          'TMDB_IMAGE_BASE_URL': entry.value,
        },
      );
      expect(EnvConfig.tmdbBaseUrl, 'https://api.themoviedb.org/3');
      expect(EnvConfig.tmdbImageBaseUrl, 'https://image.tmdb.org/t/p/');
    });
  }

  for (final scheme in ['https', 'http']) {
    test('valid $scheme endpoint overrides are preserved and trimmed', () {
      dotenv.testLoad(
        mergeWith: {
          'TMDB_BASE_URL': '  $scheme://tmdb.example.test/3/  ',
          'TMDB_IMAGE_BASE_URL': '  $scheme://images.example.test/t/p/  ',
        },
      );
      expect(EnvConfig.tmdbBaseUrl, '$scheme://tmdb.example.test/3/');
      expect(EnvConfig.tmdbImageBaseUrl, '$scheme://images.example.test/t/p/');
    });
  }

  for (final useReadToken in [true, false]) {
    test(
      'empty CI endpoints load the home feed with ${useReadToken ? 'a read token' : 'an API key'}',
      () async {
        dotenv.testLoad(
          fileInput: '''
TMDB_BASE_URL=
TMDB_IMAGE_BASE_URL=
TMDB_READ_ACCESS_TOKEN=
''',
        );
        final credential = useReadToken
            ? 'eyJ${List.filled(80, 'x').join()}'
            : '0123456789abcdef0123456789abcdef';
        EnvConfig.applyTmdbCredential(credential);
        final requestedPaths = <String>[];
        final client = MockClient((request) async {
          requestedPaths.add(request.url.path);
          expect(request.url.scheme, 'https');
          expect(request.url.host, 'api.themoviedb.org');
          expect(request.url.queryParameters['language'], 'en-US');
          if (useReadToken) {
            expect(request.headers['Authorization'], 'Bearer $credential');
            expect(request.url.queryParameters.containsKey('api_key'), isFalse);
          } else {
            expect(request.url.queryParameters['api_key'], credential);
            expect(request.headers.containsKey('Authorization'), isFalse);
          }
          // Discovery must still use the default image URL when the optional
          // configuration request fails, including when CI wrote an empty URL.
          if (request.url.path == '/3/configuration') {
            return http.Response('unavailable', 503);
          }
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 1,
                  'media_type': 'movie',
                  'title': 'Test movie',
                  'poster_path': '/poster.jpg',
                  'backdrop_path': '/backdrop.jpg',
                },
              ],
            }),
            200,
          );
        });
        addTearDown(client.close);
        final service = TmdbService(client: client);
        final payload = await service.fetchPayload(DiscoverFeed.home);
        expect(payload.featured, isNotNull);
        expect(payload.wallItems, isNotEmpty);
        expect(
          requestedPaths,
          unorderedEquals([
            '/3/configuration',
            '/3/trending/all/day',
            '/3/movie/popular',
            '/3/tv/popular',
            '/3/movie/now_playing',
          ]),
        );
        expect(
          service.imageUrl('/poster.jpg'),
          'https://image.tmdb.org/t/p/w780/poster.jpg',
        );
      },
    );
  }
}
