// Test ViewModel: perubahan UiState (Loading -> Success/Failure), pencarian,
// pemilihan lokasi, coba lagi, dan laboratorium Uji API.

import 'package:flutter_test/flutter_test.dart';
import 'package:info_cuaca/data/api_client.dart';
import 'package:info_cuaca/data/api_exception.dart';
import 'package:info_cuaca/data/earthquake_repository.dart';
import 'package:info_cuaca/data/location_service.dart';
import 'package:info_cuaca/data/weather_repository.dart';
import 'package:info_cuaca/models/earthquake.dart';
import 'package:info_cuaca/models/location.dart';
import 'package:info_cuaca/models/weather.dart';
import 'package:info_cuaca/ui/api_test/api_test_view_model.dart';
import 'package:info_cuaca/ui/earthquake/earthquake_view_model.dart';
import 'package:info_cuaca/ui/ui_state.dart';
import 'package:info_cuaca/ui/weather/weather_view_model.dart';

import 'fake_location.dart';
import 'helpers.dart';

void main() {
  group('WeatherViewModel', () {
    test('loadInitial: Loading lalu Success untuk Denpasar', () async {
      final server = happyServer();
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: server.client)),
      );
      final seen = <String>[];
      vm.addListener(() => seen.add(vm.weatherState.runtimeType.toString()));

      await vm.loadInitial();

      expect(seen, ['Loading<WeatherReport>', 'Success<WeatherReport>']);
      expect(vm.location, Location.denpasar);
      final state = vm.weatherState as Success<WeatherReport>;
      expect(state.data.current.temperature, 25.7);

      await vm.loadInitial(); // tidak memuat ulang bila sudah ada data
      expect(server.countFor(forecastPath), 1);
    });

    test('search: < 2 huruf tidak memanggil server', () async {
      final server = happyServer();
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: server.client)),
      );
      await vm.search('D');
      expect(vm.searchState, isA<Idle<List<Location>>>());
      expect(server.requests, isEmpty);
    });

    test('search lalu select: lokasi berubah dan cuaca dimuat ulang', () async {
      final server = happyServer();
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: server.client)),
      );
      await vm.loadInitial();

      await vm.search('Denpasar');
      final results = (vm.searchState as Success<List<Location>>).data;
      expect(results, hasLength(1));

      await vm.select(results.first);
      expect(vm.searchState, isA<Idle<List<Location>>>()); // daftar ditutup
      expect(vm.location.name, 'Kota Denpasar');
      expect(server.countFor(forecastPath), 2);
    });

    test('search gagal -> Failure dengan pesan pengguna', () async {
      final server = FakeServer()
        ..routes[geocodingPath] =
            (_) async => jsonResponse('{"reason":"busy"}', status: 429);
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: server.client)),
      );
      await vm.search('Denpasar');
      final state = vm.searchState as Failure<List<Location>>;
      expect(state.error.kind, ApiErrorKind.rateLimited);
      expect(state.error.userMessage, contains('429'));
    });

    test('cuaca gagal (500) -> Failure; coba lagi setelah server pulih -> Success',
        () async {
      var down = true;
      final server = happyServer()
        ..routes[forecastPath] = (_) async => down
            ? jsonResponse('{"reason":"error"}', status: 500)
            : jsonResponse(fixture('open_meteo_forecast.json'));
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: server.client)),
      );

      await vm.loadWeather();
      expect(vm.weatherState, isA<Failure<WeatherReport>>());

      down = false;
      await vm.loadWeather();
      expect(vm.weatherState, isA<Success<WeatherReport>>());
    });

    test('refresh: data lama tetap Success sampai data baru datang', () async {
      final server = happyServer();
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: server.client)),
      );
      await vm.loadInitial();
      final seen = <UiState<WeatherReport>>[];
      vm.addListener(() => seen.add(vm.weatherState));

      await vm.refresh();

      expect(seen.every((s) => s is Success<WeatherReport>), isTrue);
      expect(server.countFor(forecastPath), 2);
    });
  });


  group('WeatherViewModel + lokasi (P7)', () {
    test('tanpa LocationService: fitur lokasi tidak tersedia', () async {
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: happyServer().client)),
      );
      expect(vm.canUseLocation, isFalse);
      await vm.useMyLocation(); // tidak melakukan apa-apa
      expect(vm.location, Location.denpasar);
    });

    test('izin diberikan: lokasi GPS dipakai untuk memuat cuaca', () async {
      final server = happyServer();
      final gps = FakeLocationService(permission: LocationAccess.denied);
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: server.client)),
        locationService: gps,
      );

      await vm.useMyLocation();

      expect(gps.requestCount, 1);
      expect(vm.location.name, startsWith('Lokasi saya'));
      expect(vm.location.label, 'Lokasi saya (-8.112, 115.088)');
      expect(vm.weatherState, isA<Success<WeatherReport>>());
      final q = server.requests.single.url.queryParameters;
      expect(q['latitude'], '-8.112');
      expect(q['longitude'], '115.088');
      expect(vm.locationMessage, isNull);
      expect(vm.isLocating, isFalse);
    });

    test('izin ditolak: pesan tampil, lokasi & cuaca tidak berubah', () async {
      final server = happyServer();
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: server.client)),
        locationService: FakeLocationService(
          permission: LocationAccess.denied,
          requestResult: LocationAccess.denied,
        ),
      );
      await vm.useMyLocation();
      expect(vm.locationMessage, contains('ditolak'));
      expect(vm.location, Location.denpasar);
      expect(server.requests, isEmpty); // API tidak dipanggil
    });

    test('ditolak permanen / GPS mati: tombol pengaturan yang sesuai', () async {
      final repo = OpenMeteoWeatherRepository(ApiClient(client: happyServer().client));
      final forever = FakeLocationService(permission: LocationAccess.deniedForever);
      final vm1 = WeatherViewModel(repo, locationService: forever);
      await vm1.useMyLocation();
      expect(vm1.locationDeniedForever, isTrue);
      await vm1.openAppSettings();
      expect(forever.appSettingsOpened, 1);

      final off = FakeLocationService(serviceEnabled: false);
      final vm2 = WeatherViewModel(repo, locationService: off);
      await vm2.useMyLocation();
      expect(vm2.locationServiceDisabled, isTrue);
      expect(vm2.locationMessage, contains('GPS'));

      vm2.dismissLocationMessage();
      expect(vm2.locationMessage, isNull);
    });

    test('GPS timeout: pesan dari LocationException', () async {
      final vm = WeatherViewModel(
        OpenMeteoWeatherRepository(ApiClient(client: happyServer().client)),
        locationService: FakeLocationService(
          permission: LocationAccess.granted,
          error: const LocationException('Lokasi tidak didapat dalam 15 detik.', code: 'timeout'),
        ),
      );
      await vm.useMyLocation();
      expect(vm.locationMessage, contains('15 detik'));
      expect(vm.isLocating, isFalse);
    });
  });

  group('EarthquakeViewModel', () {
    test('load: Success berisi gempa terbaru + 15 gempa', () async {
      final server = happyServer();
      final vm = EarthquakeViewModel(
        BmkgEarthquakeRepository(ApiClient(client: server.client)),
      );
      await vm.load();
      final feed = (vm.state as Success).data;
      expect(feed.latest.magnitude, 4.2);
      expect(feed.recent, hasLength(15));
    });

    test('load gagal (endpoint 404) -> Failure notFound, lalu pulih', () async {
      final server = FakeServer(); // belum ada rute: semua request 404
      final vm = EarthquakeViewModel(
        BmkgEarthquakeRepository(ApiClient(client: server.client)),
      );
      await vm.load();
      expect((vm.state as Failure).error.kind, ApiErrorKind.notFound);

      server.routes.addAll(happyServer().routes);
      await vm.load();
      expect(vm.state, isA<Success<EarthquakeFeed>>());
    });
  });

  group('ApiTestViewModel', () {
    test('kasus "ok" sukses dan mencatat ringkasan + waktu', () async {
      final server = happyServer();
      final vm = ApiTestViewModel(ApiClient(client: server.client));
      final ok = vm.cases.firstWhere((c) => c.id == 'ok');

      await vm.run(ok);

      final result = vm.resultOf('ok')!;
      expect(result.ok, isTrue);
      expect(result.summary, contains('Infogempa'));
      expect(vm.isRunning('ok'), isFalse);
    });

    test('kasus "notFound" menghasilkan ApiException notFound', () async {
      final vm = ApiTestViewModel(ApiClient(client: happyServer().client));
      await vm.run(vm.cases.firstWhere((c) => c.id == 'notFound'));
      final result = vm.resultOf('notFound')!;
      expect(result.ok, isFalse);
      expect(result.error!.kind, ApiErrorKind.notFound);
      expect(result.error!.statusCode, 404);
    });

    test('kasus "timeout": batas 1 ms terlampaui', () async {
      final server = happyServer()
        ..routes[forecastPath] = (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return jsonResponse(fixture('open_meteo_forecast.json'));
        };
      final vm = ApiTestViewModel(ApiClient(client: server.client));
      await vm.run(vm.cases.firstWhere((c) => c.id == 'timeout'));
      expect(vm.resultOf('timeout')!.error!.kind, ApiErrorKind.timeout);
    });

    test('kasus "wrongModel": JSON gempa diparse sebagai Location -> invalidData',
        () async {
      final vm = ApiTestViewModel(ApiClient(client: happyServer().client));
      await vm.run(vm.cases.firstWhere((c) => c.id == 'wrongModel'));
      expect(vm.resultOf('wrongModel')!.error!.kind, ApiErrorKind.invalidData);
    });

    test('judul kasus OpenWeather menyesuaikan ada/tidaknya key', () {
      final tanpa = ApiTestViewModel(ApiClient(client: happyServer().client));
      final dengan = ApiTestViewModel(
        ApiClient(client: happyServer().client),
        openWeatherKey: 'abc',
      );
      expect(
        tanpa.cases.firstWhere((c) => c.id == 'withKey').title,
        contains('belum dipasang'),
      );
      expect(
        dengan.cases.firstWhere((c) => c.id == 'withKey').title,
        contains('terpasang'),
      );
    });
  });
}
