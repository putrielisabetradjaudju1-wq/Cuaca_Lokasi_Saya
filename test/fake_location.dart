// LocationService palsu untuk test (tanpa GPS sungguhan).

import 'package:info_cuaca/data/location_service.dart';

class FakeLocationService extends LocationService {
  FakeLocationService({
    this.serviceEnabled = true,
    this.permission = LocationAccess.denied,
    this.requestResult = LocationAccess.granted,
    this.point = const GeoPoint(
      latitude: -8.112,
      longitude: 115.088,
      accuracyMeters: 30,
    ), // Singaraja
    this.error,
  });

  bool serviceEnabled;
  LocationAccess permission;
  LocationAccess requestResult;
  GeoPoint point;
  LocationException? error;
  int requestCount = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationAccess> checkPermission() async => permission;

  @override
  Future<LocationAccess> requestPermission() async {
    requestCount++;
    permission = requestResult;
    return permission;
  }

  @override
  Future<GeoPoint> getCurrent() async {
    if (error != null) throw error!;
    return point;
  }

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;
}
