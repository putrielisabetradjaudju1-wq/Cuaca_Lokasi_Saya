// DATA LAYER - Pembungkus tipis di atas package `http`.
//
// Semua repository memakai kelas ini, sehingga aturan berikut berlaku di
// SATU tempat (tidak ditulis ulang di tiap repository):
//   1. batas waktu (timeout),
//   2. pemeriksaan status code,
//   3. decode JSON (UTF-8),
//   4. pemetaan error -> ApiException.
//
// Versi "tanpa pembungkus" (langsung http.get) ditunjukkan di slide;
// hasilnya sama, hanya lebih panjang bila diulang di banyak tempat.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.defaultHeaders = const {},
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// Header yang dikirim di setiap request, mis. API key: {'X-Api-Key': '...'}
  final Map<String, String> defaultHeaders;

  /// GET lalu decode JSON. Hasilnya `Map<String, dynamic>` atau `List<dynamic>`.
  Future<Object?> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
    Duration? timeout,
  }) async {
    final response = await _send(
      uri,
      timeout,
      () => _client.get(
        uri,
        headers: {'Accept': 'application/json', ...defaultHeaders, ...headers},
      ),
    );
    return _decodeJson(response, uri);
  }

  /// POST dengan body JSON (dipakai GraphQL dan API yang menerima data).
  Future<Object?> postJson(
    Uri uri,
    Object body, {
    Map<String, String> headers = const {},
    Duration? timeout,
  }) async {
    final response = await _send(
      uri,
      timeout,
      () => _client.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...defaultHeaders,
          ...headers,
        },
        body: jsonEncode(body),
      ),
    );
    return _decodeJson(response, uri);
  }

  Future<http.Response> _send(
    Uri uri,
    Duration? timeout,
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(timeout ?? this.timeout);
    } on TimeoutException {
      throw ApiException(ApiErrorKind.timeout, uri: uri);
    } on http.ClientException catch (e) {
      // package http membungkus SocketException (Android/iOS/desktop) dan
      // kegagalan fetch/CORS (web) menjadi ClientException, jadi satu
      // blok catch ini berlaku di semua platform.
      throw ApiException(ApiErrorKind.noConnection, detail: e.message, uri: uri);
    }
  }

  Object? _decodeJson(http.Response response, Uri uri) {
    final code = response.statusCode;
    if (code < 200 || code >= 300) {
      throw ApiException.fromStatusCode(code, body: response.body, uri: uri);
    }
    try {
      // bodyBytes + utf8.decode: aman untuk karakter non-ASCII ("°", "é").
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw ApiException(
        ApiErrorKind.invalidData,
        statusCode: code,
        detail: 'Bukan JSON: ${e.message}',
        uri: uri,
      );
    }
  }

  void close() => _client.close();
}
