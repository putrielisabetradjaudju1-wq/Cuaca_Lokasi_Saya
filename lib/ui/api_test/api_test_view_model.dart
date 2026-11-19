// UI LAYER - ViewModel tab "Uji API": laboratorium error (indikator e & f).
//
// Setiap kasus memanggil API SUNGGUHAN dengan kondisi tertentu (URL salah,
// tanpa API key, host tidak ada, batas waktu sangat pendek, ...) lalu
// menampilkan bagaimana ApiClient memetakan kegagalannya. Tujuannya agar
// mahasiswa melihat sendiri bentuk setiap error dan tahu cara mengatasinya.

import 'package:flutter/foundation.dart';

import '../../data/api_client.dart';
import '../../data/api_exception.dart';
import '../../models/location.dart';

class ApiTestCase {
  const ApiTestCase({
    required this.id,
    required this.title,
    required this.request,
    required this.expected,
    required this.run,
  });

  final String id;
  final String title;
  final String request; // ringkasan request yang dikirim
  final String expected; // hasil yang diharapkan
  final Future<String> Function() run; // mengembalikan ringkasan bila sukses
}

class ApiTestResult {
  const ApiTestResult({required this.elapsed, this.summary, this.error});

  final Duration elapsed;
  final String? summary;
  final ApiException? error;

  bool get ok => error == null;
}

class ApiTestViewModel extends ChangeNotifier {
  ApiTestViewModel(this._api, {this.openWeatherKey = ''});

  final ApiClient _api;

  /// Diisi lewat `--dart-define=OPENWEATHER_KEY=...` (lihat main.dart).
  final String openWeatherKey;

  final Map<String, ApiTestResult> _results = {};
  final Set<String> _running = {};

  bool get hasOpenWeatherKey => openWeatherKey.isNotEmpty;
  ApiTestResult? resultOf(String id) => _results[id];
  bool isRunning(String id) => _running.contains(id);

  late final List<ApiTestCase> cases = [
    ApiTestCase(
      id: 'ok',
      title: 'Endpoint benar',
      request: 'GET data.bmkg.go.id/DataMKG/TEWS/autogempa.json',
      expected: '200 + JSON',
      run: () async {
        final uri = Uri.https('data.bmkg.go.id', '/DataMKG/TEWS/autogempa.json');
        final json = await _api.getJson(uri) as Map<String, dynamic>;
        return '200 OK · kunci JSON teratas: ${json.keys.join(', ')}';
      },
    ),
    ApiTestCase(
      id: 'notFound',
      title: 'Path salah (typo)',
      request: 'GET api.open-meteo.com/v1/forecst?latitude=…',
      expected: '404 · notFound',
      run: () async {
        final uri = Uri.https('api.open-meteo.com', '/v1/forecst', {
          'latitude': '-8.65',
          'longitude': '115.22',
        });
        await _api.getJson(uri);
        return 'Tidak diharapkan: server menjawab sukses';
      },
    ),
    ApiTestCase(
      id: 'badRequest',
      title: 'Parameter salah',
      request: 'GET api.open-meteo.com/v1/forecast?latitude=abc',
      expected: '400 · badRequest',
      run: () async {
        final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
          'latitude': 'abc',
          'longitude': '115.22',
          'current': 'temperature_2m',
        });
        await _api.getJson(uri);
        return 'Tidak diharapkan: server menjawab sukses';
      },
    ),
    ApiTestCase(
      id: 'unauthorized',
      title: 'Tanpa API key',
      request: 'GET api.openweathermap.org/data/2.5/weather?q=Denpasar',
      expected: '401 · unauthorized',
      run: () async {
        final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
          'q': 'Denpasar,ID',
        });
        await _api.getJson(uri);
        return 'Tidak diharapkan: server menjawab sukses';
      },
    ),
    ApiTestCase(
      id: 'withKey',
      title: hasOpenWeatherKey
          ? 'Dengan API key (terpasang)'
          : 'Dengan API key (belum dipasang)',
      request: 'GET …/data/2.5/weather?q=Denpasar&appid=<OPENWEATHER_KEY>',
      expected: hasOpenWeatherKey ? '200 + suhu' : '401 (key kosong)',
      run: () async {
        final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
          'q': 'Denpasar,ID',
          'units': 'metric',
          'lang': 'id',
          'appid': openWeatherKey, // key TIDAK ditulis di kode
        });
        final json = await _api.getJson(uri) as Map<String, dynamic>;
        return parseOrThrow(uri: uri, () {
          final main = json['main'] as Map<String, dynamic>;
          final weather = (json['weather'] as List<dynamic>).first;
          final desc = (weather as Map<String, dynamic>)['description'];
          return '200 OK · ${json['name']}: ${main['temp']}°C, $desc';
        });
      },
    ),
    ApiTestCase(
      id: 'noConnection',
      title: 'Host tidak ada',
      request: 'GET api.tidak-ada.invalid/',
      expected: 'noConnection',
      run: () async {
        await _api.getJson(Uri.https('api.tidak-ada.invalid', '/'));
        return 'Tidak diharapkan: server menjawab sukses';
      },
    ),
    ApiTestCase(
      id: 'timeout',
      title: 'Batas waktu 1 ms',
      request: 'GET api.open-meteo.com/v1/forecast (timeout: 1 ms)',
      expected: 'timeout',
      run: () async {
        final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
          'latitude': '-8.65',
          'longitude': '115.22',
          'current': 'temperature_2m',
        });
        await _api.getJson(uri, timeout: const Duration(milliseconds: 1));
        return 'Tidak diharapkan: server menjawab dalam 1 ms';
      },
    ),
    ApiTestCase(
      id: 'notJson',
      title: 'Balasan bukan JSON (XML)',
      request: 'GET data.bmkg.go.id/DataMKG/TEWS/autogempa.xml',
      // Android/iOS: 200 + XML -> invalidData. Di web, server BMKG menjawab
      // 406 Not Acceptable karena header Accept: application/json ditolak.
      expected: 'invalidData (XML), atau 406 di web',
      run: () async {
        final uri = Uri.https('data.bmkg.go.id', '/DataMKG/TEWS/autogempa.xml');
        await _api.getJson(uri);
        return 'Tidak diharapkan: XML berhasil di-decode';
      },
    ),
    ApiTestCase(
      id: 'wrongModel',
      title: 'Model tidak cocok',
      request: 'JSON gempa BMKG diparse dengan Location.fromJson',
      expected: 'invalidData (field hilang)',
      run: () async {
        final uri = Uri.https('data.bmkg.go.id', '/DataMKG/TEWS/autogempa.json');
        final json = await _api.getJson(uri) as Map<String, dynamic>;
        return parseOrThrow(() => Location.fromJson(json).label, uri: uri);
      },
    ),
  ];

  Future<void> run(ApiTestCase testCase) async {
    _running.add(testCase.id);
    _results.remove(testCase.id);
    notifyListeners();
    final stopwatch = Stopwatch()..start();
    try {
      final summary = await testCase.run();
      _results[testCase.id] = ApiTestResult(
        elapsed: stopwatch.elapsed,
        summary: summary,
      );
    } on ApiException catch (e) {
      _results[testCase.id] = ApiTestResult(elapsed: stopwatch.elapsed, error: e);
    } finally {
      _running.remove(testCase.id);
      notifyListeners();
    }
  }

  Future<void> runAll() async {
    for (final testCase in cases) {
      await run(testCase);
    }
  }
}
