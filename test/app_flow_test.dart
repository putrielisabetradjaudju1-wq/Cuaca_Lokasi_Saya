// Widget test alur aplikasi dengan server palsu (tanpa internet).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_cuaca/data/api_client.dart';
import 'package:info_cuaca/data/earthquake_repository.dart';
import 'package:info_cuaca/data/location_service.dart';
import 'package:info_cuaca/data/weather_repository.dart';
import 'package:info_cuaca/main.dart';

import 'fake_location.dart';
import 'helpers.dart';

Widget buildApp(FakeServer server, {LocationService? location}) {
  final api = ApiClient(client: server.client);
  return InfoCuacaApp(
    apiClient: api,
    weatherRepository: OpenMeteoWeatherRepository(api),
    earthquakeRepository: BmkgEarthquakeRepository(api),
    locationService: location,
  );
}

void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('tab Cuaca menampilkan cuaca Denpasar dan prakiraan', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildApp(happyServer()));
    await tester.pumpAndSettle();

    expect(find.text('Kota Denpasar, Provinsi Bali, Indonesia'), findsOneWidget);
    expect(find.text('25,7°'), findsOneWidget);
    expect(find.text('Cerah berawan'), findsOneWidget);
    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.textContaining('hujan 71%'), findsOneWidget);

    // hari berikutnya ada di bawah layar ponsel -> gulir dulu
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Kam, 8 Okt'), findsOneWidget);
  });

  testWidgets('cari kota lalu pilih hasilnya memuat cuaca lokasi baru', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final server = happyServer();
    await tester.pumpWidget(buildApp(server));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Denpasar');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsWidgets);
    expect(server.countFor(geocodingPath), 1);

    await tester.tap(find.widgetWithText(ListTile, 'Kota Denpasar, Provinsi Bali, Indonesia'));
    await tester.pumpAndSettle();

    expect(server.countFor(forecastPath), 2); // awal + setelah memilih
    expect(find.byType(ListTile), findsWidgets); // daftar harian tetap ada
  });

  testWidgets('tab Gempa menampilkan gempa terbaru dan daftar', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildApp(happyServer()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gempa'));
    await tester.pumpAndSettle();

    expect(find.text('M 4,2'), findsOneWidget);
    expect(find.textContaining('Mbay-Nagekeo'), findsOneWidget);
    expect(find.text('15 gempa terakhir (M ≥ 5,0)'), findsOneWidget);
  });

  testWidgets('server error menampilkan pesan + "Coba lagi" memulihkan', (
    tester,
  ) async {
    usePhoneViewport(tester);
    var down = true;
    final server = happyServer()
      ..routes[forecastPath] = (_) async => down
          ? jsonResponse('{"reason":"down"}', status: 503)
          : jsonResponse(fixture('open_meteo_forecast.json'));
    await tester.pumpWidget(buildApp(server));
    await tester.pumpAndSettle();

    expect(
      find.text('Server sedang bermasalah (503). Coba lagi nanti.'),
      findsOneWidget,
    );
    expect(find.text('25,7°'), findsNothing);

    down = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('25,7°'), findsOneWidget);
  });

  testWidgets('tab Uji API: menjalankan kasus 404 menampilkan analisis', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildApp(happyServer()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uji API'));
    await tester.pumpAndSettle();

    final card = find.widgetWithText(Card, 'Path salah (typo)');
    await tester.scrollUntilVisible(card, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(
      find.descendant(of: card, matching: find.text('Jalankan')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('notFound · HTTP 404'), findsOneWidget);
    expect(find.textContaining('Pengguna melihat:'), findsOneWidget);
    expect(find.textContaining('Pengembang:'), findsOneWidget);
  });


  testWidgets('P7: tombol lokasi saya memuat cuaca di koordinat GPS', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final server = happyServer();
    final gps = FakeLocationService(permission: LocationAccess.denied);
    await tester.pumpWidget(buildApp(server, location: gps));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cuaca di lokasi saya'));
    await tester.pumpAndSettle();

    expect(gps.requestCount, 1);
    expect(find.text('Lokasi saya (-8.112, 115.088)'), findsOneWidget);
    expect(find.text('25,7°'), findsOneWidget);
    expect(server.countFor(forecastPath), 2); // awal (Denpasar) + lokasi GPS
  });

  testWidgets('P7: izin ditolak permanen menampilkan pesan + Buka pengaturan', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final gps = FakeLocationService(permission: LocationAccess.deniedForever);
    await tester.pumpWidget(buildApp(happyServer(), location: gps));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cuaca di lokasi saya'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ditolak permanen'), findsOneWidget);
    await tester.tap(find.text('Buka pengaturan'));
    expect(gps.appSettingsOpened, 1);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ditolak permanen'), findsNothing);
    expect(find.text('Kota Denpasar, Provinsi Bali, Indonesia'), findsOneWidget);
  });

  testWidgets('tanpa LocationService tombol lokasi tidak ada', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildApp(happyServer()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cuaca di lokasi saya'), findsNothing);
  });

  testWidgets('layar lebar memakai NavigationRail', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp(happyServer()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
