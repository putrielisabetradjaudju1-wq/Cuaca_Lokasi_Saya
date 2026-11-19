// Test repository: parsing JSON asli (fixtures) menjadi model, susunan
// query string, dan penanganan struktur yang tidak sesuai.

import 'package:flutter_test/flutter_test.dart';
import 'package:info_cuaca/data/api_client.dart';
import 'package:info_cuaca/data/api_exception.dart';
import 'package:info_cuaca/data/earthquake_repository.dart';
import 'package:info_cuaca/data/weather_repository.dart';
import 'package:info_cuaca/models/location.dart';

import 'helpers.dart';

void main() {
  group('OpenMeteoWeatherRepository', () {
    test('searchLocations: parsing hasil & query string', () async {
      final server = happyServer();
      final repo = OpenMeteoWeatherRepository(ApiClient(client: server.client));

      final results = await repo.searchLocations('Denpasar');

      expect(results, hasLength(1));
      final loc = results.first;
      expect(loc.id, 1645528);
      expect(loc.name, 'Kota Denpasar');
      expect(loc.admin1, 'Provinsi Bali');
      expect(loc.latitude, closeTo(-8.65, 0.001));
      expect(loc.label, 'Kota Denpasar, Provinsi Bali, Indonesia');

      final req = server.requests.single;
      expect(req.url.host, 'geocoding-api.open-meteo.com');
      expect(req.url.queryParameters['name'], 'Denpasar');
      expect(req.url.queryParameters['language'], 'id');
    });

    test('searchLocations: spasi & karakter khusus di-encode oleh Uri.https',
        () async {
      final server = happyServer();
      final repo = OpenMeteoWeatherRepository(ApiClient(client: server.client));
      await repo.searchLocations('Nusa Dua & Kuta');
      // spasi -> "+", "&" -> "%26": tanpa encoding, "&" akan dianggap pemisah parameter
      expect(server.requests.single.url.query, contains('name=Nusa+Dua+%26+Kuta'));
      expect(server.requests.single.url.queryParameters['name'], 'Nusa Dua & Kuta');
    });

    test('searchLocations: tanpa hasil -> key "results" tidak ada -> list kosong',
        () async {
      final server = FakeServer()
        ..routes[geocodingPath] =
            (_) async => jsonResponse('{"generationtime_ms":0.13}');
      final repo = OpenMeteoWeatherRepository(ApiClient(client: server.client));
      expect(await repo.searchLocations('xyzzy'), isEmpty);
    });

    test('Location tanpa admin1 tetap bisa diparse', () {
      final loc = Location.fromJson({
        'id': 1,
        'name': 'Singapore',
        'latitude': 1, // int, bukan double
        'longitude': 103.8,
        'country': 'Singapore',
      });
      expect(loc.admin1, isNull);
      expect(loc.latitude, 1.0);
      expect(loc.label, 'Singapore, Singapore');
    });

    test('getForecast: parsing current + daily (berkolom -> berbaris)', () async {
      final server = happyServer();
      final repo = OpenMeteoWeatherRepository(ApiClient(client: server.client));

      final report = await repo.getForecast(Location.denpasar);

      expect(report.timezone, 'Asia/Makassar');
      expect(report.current.temperature, 25.7);
      expect(report.current.humidity, 80);
      expect(report.current.weatherCode, 1);
      expect(report.current.windSpeed, 6.2);
      expect(report.current.time, DateTime(2026, 10, 7, 22, 15));
      expect(report.daily, hasLength(4));
      expect(report.daily.first.date, DateTime(2026, 10, 7));
      expect(report.daily.first.tempMax, 31.0);
      expect(report.daily.first.tempMin, 23.2);
      expect(report.daily.first.precipitationProbability, 71);
      expect(report.daily.last.weatherCode, 2);

      final q = server.requests.single.url.queryParameters;
      expect(q['latitude'], '-8.65');
      expect(q['longitude'], '115.21667');
      expect(q['daily'], contains('temperature_2m_max'));
      expect(q['timezone'], 'auto');
    });

    test('getForecast: struktur berubah (field hilang) -> invalidData', () async {
      final server = FakeServer()
        ..routes[forecastPath] = (_) async =>
            jsonResponse('{"timezone":"Asia/Makassar","current":{},"daily":{}}');
      final repo = OpenMeteoWeatherRepository(ApiClient(client: server.client));
      await expectLater(
        repo.getForecast(Location.denpasar),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.invalidData)
              .having((e) => e.uri?.host, 'uri.host', 'api.open-meteo.com'),
        ),
      );
    });

    test('getForecast: server 503 -> ApiException server (tidak crash)', () async {
      final server = FakeServer()
        ..routes[forecastPath] =
            (_) async => jsonResponse('{"reason":"down"}', status: 503);
      final repo = OpenMeteoWeatherRepository(ApiClient(client: server.client));
      await expectLater(
        repo.getForecast(Location.denpasar),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.server)
              .having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  group('BmkgEarthquakeRepository', () {
    test('getFeed: JSON bersarang, angka-string, koordinat gabungan', () async {
      final server = happyServer();
      final repo = BmkgEarthquakeRepository(ApiClient(client: server.client));

      final feed = await repo.getFeed();

      expect(feed.latest.magnitude, 4.2); // "4.2" (String) -> 4.2 (double)
      expect(feed.latest.latitude, -8.35); // dari "Coordinates":"-8.35,121.44"
      expect(feed.latest.longitude, 121.44);
      expect(feed.latest.wilayah, contains('Nagekeo'));
      expect(feed.latest.dirasakan, isNotNull);
      expect(feed.latest.shakemapUrl.toString(), contains('data.bmkg.go.id'));
      expect(feed.latest.dateTime.isUtc, isTrue);

      expect(feed.recent, hasLength(15));
      expect(feed.recent.every((q) => q.magnitude >= 5.0), isTrue);
      expect(feed.recent.first.dirasakan, isNull); // field hanya di autogempa

      // dua endpoint dipanggil, masing-masing sekali
      expect(server.countFor(autogempaPath), 1);
      expect(server.countFor(gempaterkiniPath), 1);
    });

    test('getFeed: Magnitude bukan angka -> invalidData', () async {
      final server = happyServer()
        ..routes[autogempaPath] = (_) async => jsonResponse(
              fixture('bmkg_autogempa.json').replaceFirst('"4.2"', '"empat"'),
            );
      final repo = BmkgEarthquakeRepository(ApiClient(client: server.client));
      await expectLater(
        repo.getFeed(),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.invalidData),
        ),
      );
    });

    test('getFeed: salah satu endpoint 404 -> notFound', () async {
      final server = happyServer()..routes.remove(gempaterkiniPath);
      final repo = BmkgEarthquakeRepository(ApiClient(client: server.client));
      await expectLater(
        repo.getFeed(),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.notFound),
        ),
      );
    });
  });
}
