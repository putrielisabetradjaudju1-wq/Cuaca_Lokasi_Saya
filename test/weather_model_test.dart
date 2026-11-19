import 'package:flutter_test/flutter_test.dart';
import 'package:info_cuaca/models/weather.dart';

void main() {
  test('WeatherReport fromJson berhasil parsing data', () {
    final json = {
      "timezone": "Asia/Makassar",
      "current": {
        "time": "2026-11-17T14:00",
        "temperature_2m": 29.4,
        "relative_humidity_2m": 73,
        "weather_code": 3,
        "wind_speed_10m": 10.4
      },
      "daily": {
        "time": ["2026-11-17"],
        "weather_code": [3],
        "temperature_2m_max": [29.6],
        "temperature_2m_min": [24.2],
        "precipitation_probability_max": [100]
      }
    };

    final report = WeatherReport.fromJson(json);

    expect(report.timezone, "Asia/Makassar");
    expect(report.current.temperature, 29.4);
    expect(report.daily.length, 1);
  });
}