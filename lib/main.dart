// InfoCuaca - contoh integrasi API eksternal (Pertemuan 6).
//
// Sumber data (semua gratis & berformat JSON):
//   - Open-Meteo  : pencarian kota + cuaca/prakiraan, TANPA API key
//   - BMKG        : gempa terkini, TANPA API key
//   - OpenWeather : hanya di tab "Uji API", PERLU API key (contoh autentikasi)
//
// P7: + GPS perangkat (package geolocator) untuk "cuaca di lokasi saya".
//     Konfigurasi izin: lihat platform-config/ (AndroidManifest.xml, Info.plist).
//
// Arsitektur sama dengan TugasKu (MVVM + Repository):
//   View -> ViewModel -> Repository -> ApiClient (package http) -> internet
//                     -> LocationService (geolocator) -> GPS

import 'package:flutter/material.dart';

import 'data/api_client.dart';
import 'data/earthquake_repository.dart';
import 'data/location_service.dart';
import 'data/weather_repository.dart';
import 'ui/api_test/api_test_view_model.dart';
import 'ui/earthquake/earthquake_view_model.dart';
import 'ui/home/home_shell.dart';
import 'ui/weather/weather_view_model.dart';

/// API key OpenWeather dibaca SAAT KOMPILASI dari:
///   flutter run --dart-define=OPENWEATHER_KEY=isi_key_anda
/// Key tidak ditulis di kode dan tidak masuk repository Git. Bila kosong,
/// kasus "Dengan API key" di tab Uji API akan memperlihatkan error 401.
const openWeatherKey = String.fromEnvironment('OPENWEATHER_KEY');

void main() {
  final api = ApiClient();
  runApp(
    InfoCuacaApp(
      apiClient: api,
      weatherRepository: OpenMeteoWeatherRepository(api),
      earthquakeRepository: BmkgEarthquakeRepository(api),
      locationService: GeolocatorLocationService(),
      openWeatherKey: openWeatherKey,
    ),
  );
}

class InfoCuacaApp extends StatefulWidget {
  const InfoCuacaApp({
    super.key,
    required this.apiClient,
    required this.weatherRepository,
    required this.earthquakeRepository,
    this.locationService,
    this.openWeatherKey = '',
  });

  final ApiClient apiClient;
  final WeatherRepository weatherRepository;
  final EarthquakeRepository earthquakeRepository;
  final LocationService? locationService; // P7; null = tanpa tombol lokasi
  final String openWeatherKey;

  @override
  State<InfoCuacaApp> createState() => _InfoCuacaAppState();
}

class _InfoCuacaAppState extends State<InfoCuacaApp> {
  late final WeatherViewModel _weather;
  late final EarthquakeViewModel _earthquake;
  late final ApiTestViewModel _apiTest;

  @override
  void initState() {
    super.initState();
    _weather = WeatherViewModel(
      widget.weatherRepository,
      locationService: widget.locationService,
    );
    _earthquake = EarthquakeViewModel(widget.earthquakeRepository);
    _apiTest = ApiTestViewModel(
      widget.apiClient,
      openWeatherKey: widget.openWeatherKey,
    );
  }

  @override
  void dispose() {
    _weather.dispose();
    _earthquake.dispose();
    _apiTest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuaca Lokasi Saya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
         seedColor: const Color.fromARGB(255, 203, 139, 214),)),
      home: HomeShell(
        weatherViewModel: _weather,
        earthquakeViewModel: _earthquake,
        apiTestViewModel: _apiTest,
      ),
    );
  }
}
