// Alat bantu test: server palsu berbasis MockClient (package http/testing).
//
// Test TIDAK memanggil internet. Balasan server dibaca dari file JSON asli
// yang disimpan di test/fixtures/ (hasil unduhan API sungguhan), sehingga
// test cepat, stabil, dan bisa dijalankan tanpa koneksi.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

http.Response jsonResponse(String body, {int status = 200}) => http.Response(
  body,
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

typedef Handler = Future<http.Response> Function(http.Request request);

/// Server palsu: memilih balasan berdasarkan "host/path", mencatat semua request.
class FakeServer {
  final List<http.Request> requests = [];
  final Map<String, Handler> routes = {};

  MockClient get client => MockClient((request) async {
    requests.add(request);
    final handler = routes['${request.url.host}${request.url.path}'];
    if (handler == null) {
      return http.Response('{"error":true,"reason":"Not Found"}', 404);
    }
    return handler(request);
  });

  int countFor(String hostPath) =>
      requests.where((r) => '${r.url.host}${r.url.path}' == hostPath).length;
}

const geocodingPath = 'geocoding-api.open-meteo.com/v1/search';
const forecastPath = 'api.open-meteo.com/v1/forecast';
const autogempaPath = 'data.bmkg.go.id/DataMKG/TEWS/autogempa.json';
const gempaterkiniPath = 'data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json';

/// Semua endpoint menjawab sukses dengan data asli.
FakeServer happyServer() => FakeServer()
  ..routes.addAll({
    geocodingPath: (_) async => jsonResponse(fixture('open_meteo_geocoding.json')),
    forecastPath: (_) async => jsonResponse(fixture('open_meteo_forecast.json')),
    autogempaPath: (_) async => jsonResponse(fixture('bmkg_autogempa.json')),
    gempaterkiniPath: (_) async =>
        jsonResponse(fixture('bmkg_gempaterkini.json')),
  });
