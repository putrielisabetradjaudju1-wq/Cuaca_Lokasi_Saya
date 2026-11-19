// MODEL - Cuaca dari Open-Meteo Forecast API.
//
// Ciri khas Open-Meteo: data harian dikirim "berkolom" (columnar):
//   "daily": {"time": ["2026-10-07", "2026-10-08"],
//             "weather_code": [51, 53],
//             "temperature_2m_max": [31.0, 29.5], ...}
// Elemen ke-i di setiap array adalah data hari yang sama.
// fromJson di bawah mengubahnya menjadi List<DailyForecast> ("berbaris")
// supaya mudah ditampilkan sebagai daftar.

class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.weatherCode,
    required this.windSpeed,
  });

  final DateTime time;
  final double temperature; // °C
  final int humidity; // %
  final int weatherCode; // kode WMO, lihat ui/format.dart
  final double windSpeed; // km/jam

  factory CurrentWeather.fromJson(Map<String, dynamic> json) => CurrentWeather(
    time: DateTime.parse(json['time'] as String), // "2026-10-07T22:15"
    temperature: (json['temperature_2m'] as num).toDouble(),
    humidity: (json['relative_humidity_2m'] as num).toInt(),
    weatherCode: json['weather_code'] as int,
    windSpeed: (json['wind_speed_10m'] as num).toDouble(),
  );
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    this.precipitationProbability,
  });

  final DateTime date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final int? precipitationProbability; // % ; null bila server tidak punya datanya
}

class WeatherReport {
  const WeatherReport({
    required this.timezone,
    required this.current,
    required this.daily,
  });

  final String timezone;
  final CurrentWeather current;
  final List<DailyForecast> daily;

  factory WeatherReport.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    // Setiap kolom adalah List; cast() memastikan tipe elemennya.
    final dates = (daily['time'] as List<dynamic>).cast<String>();
    final codes = (daily['weather_code'] as List<dynamic>).cast<int>();
    final maxs = (daily['temperature_2m_max'] as List<dynamic>).cast<num>();
    final mins = (daily['temperature_2m_min'] as List<dynamic>).cast<num>();
    final rain = (daily['precipitation_probability_max'] as List<dynamic>?)
        ?.cast<int?>();

    return WeatherReport(
      timezone: json['timezone'] as String,
      current: CurrentWeather.fromJson(json['current'] as Map<String, dynamic>),
      daily: [
        for (var i = 0; i < dates.length; i++)
          DailyForecast(
            date: DateTime.parse(dates[i]),
            weatherCode: codes[i],
            tempMax: maxs[i].toDouble(),
            tempMin: mins[i].toDouble(),
            precipitationProbability: rain?[i],
          ),
      ],
    );
  }
}
