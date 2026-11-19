// Test ApiClient: status code, timeout, koneksi, dan decode JSON
// dipetakan ke ApiException yang benar.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:info_cuaca/data/api_client.dart';
import 'package:info_cuaca/data/api_exception.dart';

import 'helpers.dart';

void main() {
  final uri = Uri.https('contoh.test', '/data');

  ApiClient clientWith(Future<http.Response> Function(http.Request) handler) =>
      ApiClient(client: MockClient(handler));

  group('ApiClient.getJson', () {
    test('200 dengan JSON objek -> Map', () async {
      final api = clientWith((_) async => jsonResponse('{"a": 1, "b": [1,2]}'));
      final json = await api.getJson(uri) as Map<String, dynamic>;
      expect(json['a'], 1);
      expect(json['b'], [1, 2]);
    });

    test('mengirim header Accept dan header tambahan', () async {
      late http.Request seen;
      final api = ApiClient(
        client: MockClient((r) async {
          seen = r;
          return jsonResponse('{}');
        }),
        defaultHeaders: {'X-Api-Key': 'rahasia'},
      );
      await api.getJson(uri, headers: {'X-Extra': '1'});
      expect(seen.method, 'GET');
      expect(seen.headers['accept'], 'application/json');
      expect(seen.headers['x-api-key'], 'rahasia');
      expect(seen.headers['x-extra'], '1');
    });

    test('decode UTF-8 dengan benar (karakter °)', () async {
      final api = clientWith((_) async => jsonResponse('{"unit": "°C"}'));
      final json = await api.getJson(uri) as Map<String, dynamic>;
      expect(json['unit'], '°C');
    });

    for (final (status, kind) in [
      (400, ApiErrorKind.badRequest),
      (401, ApiErrorKind.unauthorized),
      (403, ApiErrorKind.forbidden),
      (404, ApiErrorKind.notFound),
      (429, ApiErrorKind.rateLimited),
      (500, ApiErrorKind.server),
      (503, ApiErrorKind.server),
      (418, ApiErrorKind.unknown),
    ]) {
      test('status $status -> ${kind.name}', () async {
        final api = clientWith(
          (_) async => jsonResponse('{"message":"gagal"}', status: status),
        );
        final e = await api.getJson(uri).then<ApiException?>(
          (_) => null,
          onError: (Object e) => e as ApiException,
        );
        expect(e, isNotNull);
        expect(e!.kind, kind);
        expect(e.statusCode, status);
        expect(e.detail, contains('gagal')); // body server ikut disimpan
        expect(e.uri, uri);
      });
    }

    test('ClientException (tanpa koneksi / host tidak ada) -> noConnection',
        () async {
      final api = clientWith(
        (_) async => throw http.ClientException('Connection refused', uri),
      );
      await expectLater(
        api.getJson(uri),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.noConnection)
              .having((e) => e.detail, 'detail', contains('refused')),
        ),
      );
    });

    test('server terlalu lambat -> timeout', () async {
      final api = ApiClient(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return jsonResponse('{}');
        }),
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        api.getJson(uri),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.timeout),
        ),
      );
    });

    test('timeout per panggilan menimpa timeout bawaan', () async {
      final api = ApiClient(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return jsonResponse('{}');
        }),
        timeout: const Duration(seconds: 5),
      );
      await expectLater(
        api.getJson(uri, timeout: const Duration(milliseconds: 10)),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.timeout),
        ),
      );
    });

    test('status 200 tetapi body bukan JSON -> invalidData', () async {
      final api = clientWith(
        (_) async => http.Response('<html>Maintenance</html>', 200),
      );
      await expectLater(
        api.getJson(uri),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.invalidData)
              .having((e) => e.statusCode, 'statusCode', 200),
        ),
      );
    });
  });

  group('ApiClient.postJson', () {
    test('mengirim Content-Type JSON dan body ter-encode', () async {
      late http.Request seen;
      final api = clientWith((r) async {
        seen = r;
        return jsonResponse('{"data": {"ok": true}}');
      });
      final json = await api.postJson(uri, {'query': '{ country { name } }'});
      expect(seen.method, 'POST');
      expect(seen.headers['content-type'], startsWith('application/json'));
      expect(seen.body, '{"query":"{ country { name } }"}');
      expect((json as Map<String, dynamic>)['data'], {'ok': true});
    });
  });

  group('ApiException', () {
    test('setiap jenis error punya pesan pengguna & petunjuk pengembang', () {
      for (final kind in ApiErrorKind.values) {
        final e = ApiException(kind, statusCode: 500);
        expect(e.userMessage, isNotEmpty, reason: kind.name);
        expect(e.developerHint, isNotEmpty, reason: kind.name);
      }
    });

    test('parseOrThrow mengubah TypeError/FormatException -> invalidData', () {
      expect(
        () => parseOrThrow(() => (null as dynamic) as String),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.invalidData),
        ),
      );
      expect(
        () => parseOrThrow(() => double.parse('4,2')),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.invalidData),
        ),
      );
      expect(parseOrThrow(() => int.parse('42')), 42);
    });
  });
}
