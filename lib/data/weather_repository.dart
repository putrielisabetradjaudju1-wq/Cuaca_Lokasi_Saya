// DATA LAYER - Repository cuaca.
//
// Sama seperti TaskRepository di TugasKu (P3-P5): ViewModel hanya mengenal
// kontrak abstrak ini. Sumber datanya (Open-Meteo, OpenWeather, atau data
// palsu untuk test) bisa diganti tanpa menyentuh UI.

import '../models/location.dart';
import '../models/weather.dart';
import 'api_client.dart';
import 'api_exception.dart';

abstract class WeatherRepository {
  /// Mencari kota berdasarkan nama (minimal 2 huruf).
  Future<List<Location>> searchLocations(String query);

  /// Cuaca saat ini + prakiraan beberapa hari untuk satu lokasi.
  Future<WeatherReport> getForecast(Location location);
}

/// Implementasi dengan Open-Meteo: gratis, tanpa API key, mendukung CORS
/// (bisa dipanggil langsung dari Flutter web). Dokumentasi: open-meteo.com/en/docs
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository(this._api);

  final ApiClient _api;

  static const _geocodingHost = 'geocoding-api.open-meteo.com';
  static const _forecastHost = 'api.open-meteo.com';

  @override
  Future<List<Location>> searchLocations(String query) async {
    // Uri.https menyusun & meng-encode query string dengan benar
    // (spasi -> +, & -> %26, dst.). Jangan menyambung string URL secara manual.
    final uri = Uri.https(_geocodingHost, '/v1/search', {
      'name': query,
      'count': '8',
      'language': 'id',
      'format': 'json',
    });
    final json = await _api.getJson(uri) as Map<String, dynamic>;

    // Jebakan: bila tidak ada hasil, key "results" TIDAK ADA sama sekali
    // (bukan list kosong). Tanpa `?? const []` aplikasi akan error.
    final results = json['results'] as List<dynamic>? ?? const [];
    return parseOrThrow(
      () => [for (final r in results) Location.fromJson(r as Map<String, dynamic>)],
      uri: uri,
    );
  }

  @override
  Future<WeatherReport> getForecast(Location location) async {
    final uri = Uri.https(_forecastHost, '/v1/forecast', {
      'latitude': '${location.latitude}',
      'longitude': '${location.longitude}',
      'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'forecast_days': '4',
      'timezone': 'auto',
    });
    final json = await _api.getJson(uri) as Map<String, dynamic>;
    return parseOrThrow(() => WeatherReport.fromJson(json), uri: uri);
  }
}
