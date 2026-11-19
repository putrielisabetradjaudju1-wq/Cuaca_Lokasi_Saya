// UI LAYER - ViewModel halaman cuaca.
//
// P6: cari kota -> pilih -> muat cuaca (UiState Idle/Loading/Success/Failure).
// P7: tambahan useMyLocation(): GPS (fitur device) -> koordinat -> API cuaca.

import 'package:flutter/foundation.dart';

import '../../data/api_exception.dart';
import '../../data/location_service.dart';
import '../../data/weather_repository.dart';
import '../../models/location.dart';
import '../../models/weather.dart';
import '../ui_state.dart';

class WeatherViewModel extends ChangeNotifier {
  WeatherViewModel(this._repository, {this.locationService});

  final WeatherRepository _repository;

  /// P7: null = aplikasi dijalankan tanpa fitur lokasi (mis. di test lama).
  final LocationService? locationService;

  UiState<List<Location>> _searchState = const Idle();
  Location _location = Location.denpasar;
  UiState<WeatherReport> _weatherState = const Idle();
  String _lastQuery = '';

  bool _locating = false;
  String? _locationMessage;
  LocationAccess? _locationAccess;

  UiState<List<Location>> get searchState => _searchState;
  Location get location => _location;
  UiState<WeatherReport> get weatherState => _weatherState;

  bool get canUseLocation => locationService != null;
  bool get isLocating => _locating;
  String? get locationMessage => _locationMessage;
  bool get locationDeniedForever =>
      _locationAccess == LocationAccess.deniedForever;
  bool get locationServiceDisabled =>
      _locationAccess == LocationAccess.serviceDisabled;

  /// Dipanggil sekali saat halaman dibuka: cuaca lokasi awal.
  Future<void> loadInitial() async {
    if (_weatherState is Idle) await loadWeather();
  }

  Future<void> search(String query) async {
    final q = query.trim();
    _lastQuery = q;
    if (q.length < 2) {
      _searchState = const Idle();
      notifyListeners();
      return; // jangan membebani server untuk 1 huruf
    }
    _searchState = const Loading();
    notifyListeners();
    try {
      final results = await _repository.searchLocations(q);
      if (q != _lastQuery) return; // hasil basi: pengguna sudah mencari kata lain
      _searchState = Success(results);
    } on ApiException catch (e) {
      _searchState = Failure(e);
    }
    notifyListeners();
  }

  void clearSearch() {
    _lastQuery = '';
    _searchState = const Idle();
    notifyListeners();
  }

  Future<void> select(Location location) async {
    _location = location;
    _searchState = const Idle();
    await loadWeather();
  }

  /// P7: "cuaca di lokasi saya". Dua langkah yang masing-masing bisa gagal:
  ///   1. fitur device: izin + GPS  -> LocationException / akses ditolak
  ///   2. API eksternal: Open-Meteo -> ApiException (ditangani loadWeather)
  Future<void> useMyLocation() async {
    final service = locationService;
    if (service == null) return;
    _locating = true;
    _locationMessage = null;
    notifyListeners();
    try {
      final access = await service.ensureAccess();
      _locationAccess = access;
      if (!access.isGranted) {
        _locationMessage = LocationService.explain(access);
        return;
      }
      final point = await service.getCurrent();
      _location = Location.fromCoordinates(point.latitude, point.longitude);
      _searchState = const Idle();
    } on LocationException catch (e) {
      _locationMessage = e.message;
      return;
    } finally {
      _locating = false;
      notifyListeners();
    }
    await loadWeather();
  }

  void dismissLocationMessage() {
    _locationMessage = null;
    notifyListeners();
  }

  Future<void> openAppSettings() async => locationService?.openAppSettings();

  Future<void> openLocationSettings() async =>
      locationService?.openLocationSettings();

  /// Memuat dengan indikator penuh (pertama kali / setelah error).
  Future<void> loadWeather() async {
    _weatherState = const Loading();
    notifyListeners();
    await _fetch();
  }

  /// Memuat ulang "diam-diam" (tarik untuk menyegarkan): data lama tetap
  /// tampil sampai data baru datang.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      _weatherState = Success(await _repository.getForecast(_location));
    } on ApiException catch (e) {
      _weatherState = Failure(e);
    }
    notifyListeners();
  }
}
