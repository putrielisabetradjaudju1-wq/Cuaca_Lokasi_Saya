// DATA LAYER - Repository gempa (BMKG).

import '../models/earthquake.dart';
import 'api_client.dart';
import 'api_exception.dart';

abstract class EarthquakeRepository {
  Future<EarthquakeFeed> getFeed();
}

/// Data terbuka BMKG: https://data.bmkg.go.id/gempabumi/
/// Tanpa API key, format JSON, boleh diakses dari browser (CORS).
class BmkgEarthquakeRepository implements EarthquakeRepository {
  BmkgEarthquakeRepository(this._api);

  final ApiClient _api;

  static const _host = 'data.bmkg.go.id';

  @override
  Future<EarthquakeFeed> getFeed() async {
    final latestUri = Uri.https(_host, '/DataMKG/TEWS/autogempa.json');
    final recentUri = Uri.https(_host, '/DataMKG/TEWS/gempaterkini.json');

    // Dua request tidak saling bergantung -> jalankan BERSAMAAN dengan
    // Future.wait, bukan menunggu satu per satu (total waktu lebih singkat).
    final [latestJson, recentJson] = await Future.wait([
      _api.getJson(latestUri),
      _api.getJson(recentUri),
    ]);

    return parseOrThrow(uri: recentUri, () {
      // Struktur bersarang: {"Infogempa": {"gempa": {...}}}
      final latestInfo =
          (latestJson as Map<String, dynamic>)['Infogempa'] as Map<String, dynamic>;
      final latest = Earthquake.fromJson(latestInfo['gempa'] as Map<String, dynamic>);

      // Struktur bersarang dengan LIST: {"Infogempa": {"gempa": [ ... ]}}
      final recentInfo =
          (recentJson as Map<String, dynamic>)['Infogempa'] as Map<String, dynamic>;
      final list = recentInfo['gempa'] as List<dynamic>;
      final recent = [
        for (final item in list) Earthquake.fromJson(item as Map<String, dynamic>),
      ];
      return EarthquakeFeed(latest: latest, recent: recent);
    });
  }
}
