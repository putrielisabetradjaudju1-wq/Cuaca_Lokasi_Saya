// DATA LAYER (P7) - Lokasi perangkat lewat package geolocator.
//
// Dipakai untuk "cuaca di lokasi saya": fitur device (GPS) + API eksternal
// (Open-Meteo). Kontrak abstrak memakai tipe milik kita sendiri supaya
// ViewModel & test tidak bergantung pada plugin (lihat DeviceLab untuk versi
// yang lebih lengkap: stream posisi, pengaturan, dll.).

import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled, unknown }

extension LocationAccessInfo on LocationAccess {
  bool get isGranted => this == LocationAccess.granted;
}

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

class LocationException implements Exception {
  const LocationException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'LocationException(${code ?? '-'}): $message';
}

abstract class LocationService {
  Future<bool> isServiceEnabled();
  Future<LocationAccess> checkPermission();
  Future<LocationAccess> requestPermission();
  Future<GeoPoint> getCurrent();
  Future<void> openAppSettings();
  Future<void> openLocationSettings();

  /// Alur standar: layanan hidup? -> izin? -> minta izin bila belum pernah.
  Future<LocationAccess> ensureAccess() async {
    if (!await isServiceEnabled()) return LocationAccess.serviceDisabled;
    var access = await checkPermission();
    if (access == LocationAccess.denied) access = await requestPermission();
    return access;
  }

  /// Pesan untuk pengguna bila akses tidak diberikan.
  static String explain(LocationAccess access) => switch (access) {
    LocationAccess.serviceDisabled =>
      'Layanan lokasi (GPS) mati. Nyalakan dulu di pengaturan perangkat.',
    LocationAccess.denied =>
      'Izin lokasi ditolak. Cari kota secara manual, atau izinkan lokasi.',
    LocationAccess.deniedForever =>
      'Izin lokasi ditolak permanen. Buka Pengaturan aplikasi untuk mengizinkannya.',
    LocationAccess.granted => '',
    LocationAccess.unknown => 'Status izin lokasi tidak dapat ditentukan.',
  };
}

class GeolocatorLocationService extends LocationService {
  static LocationAccess _map(LocationPermission p) => switch (p) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocationAccess.granted,
    LocationPermission.denied => LocationAccess.denied,
    LocationPermission.deniedForever => LocationAccess.deniedForever,
    LocationPermission.unableToDetermine => LocationAccess.unknown,
  };

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationAccess> checkPermission() async =>
      _map(await Geolocator.checkPermission());

  @override
  Future<LocationAccess> requestPermission() async =>
      _map(await Geolocator.requestPermission());

  @override
  Future<GeoPoint> getCurrent() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // Untuk cuaca, akurasi "medium" (ratusan meter) sudah cukup dan
          // lebih hemat baterai daripada GPS presisi.
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 30),
        ),
      );
      return GeoPoint(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracyMeters: p.accuracy,
      );
    } on TimeoutException {
      throw const LocationException(
        'Lokasi tidak didapat dalam 30 detik. Coba lagi atau cari kota manual.',
        code: 'timeout',
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        'Layanan lokasi mati. Nyalakan GPS di pengaturan perangkat.',
        code: 'service_disabled',
      );
    } on PermissionDeniedException {
      throw const LocationException('Izin lokasi ditolak.', code: 'denied');
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
