// MODEL - Gempa dari BMKG (https://data.bmkg.go.id/DataMKG/TEWS/).
//
// Pelajaran penting dari JSON BMKG:
// 1. Bersarang : {"Infogempa": {"gempa": {...}}}   (autogempa.json)
//                {"Infogempa": {"gempa": [ ... ]}}  (gempaterkini.json = daftar)
// 2. Angka dikirim sebagai STRING: "Magnitude":"4.2" -> perlu double.parse
// 3. Dua nilai digabung dalam satu string: "Coordinates":"-8.35,121.44"
// 4. Beberapa field hanya ada di autogempa.json (Dirasakan, Shakemap) -> nullable
//
// Tidak semua API "rapi". Model yang baik menyesuaikan diri dengan data
// apa adanya, lalu menyajikan tipe yang nyaman bagi UI (double, DateTime).

class Earthquake {
  const Earthquake({
    required this.tanggal,
    required this.jam,
    required this.dateTime,
    required this.magnitude,
    required this.kedalaman,
    required this.wilayah,
    required this.potensi,
    required this.latitude,
    required this.longitude,
    this.dirasakan,
    this.shakemap,
  });

  final String tanggal; // "07 Okt 2026" (sudah diformat BMKG)
  final String jam; // "19:03:42 WIB"
  final DateTime dateTime; // versi mesin (UTC), untuk mengurutkan/menghitung
  final double magnitude;
  final String kedalaman; // "10 km"
  final String wilayah;
  final String potensi;
  final double latitude;
  final double longitude;
  final String? dirasakan; // skala MMI, hanya gempa dirasakan
  final String? shakemap; // nama file gambar peta guncangan

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    final coords = (json['Coordinates'] as String).split(',');
    return Earthquake(
      tanggal: json['Tanggal'] as String,
      jam: json['Jam'] as String,
      dateTime: DateTime.parse(json['DateTime'] as String),
      magnitude: double.parse(json['Magnitude'] as String), // STRING -> double
      kedalaman: json['Kedalaman'] as String,
      wilayah: json['Wilayah'] as String,
      potensi: json['Potensi'] as String,
      latitude: double.parse(coords[0]),
      longitude: double.parse(coords[1]),
      dirasakan: json['Dirasakan'] as String?,
      shakemap: json['Shakemap'] as String?,
    );
  }

  /// Alamat gambar peta guncangan (hanya untuk gempa yang dirasakan).
  Uri? get shakemapUrl => shakemap == null
      ? null
      : Uri.https('data.bmkg.go.id', '/DataMKG/TEWS/$shakemap');
}

/// Gabungan dua endpoint BMKG: gempa terbaru + 15 gempa M>=5 terakhir.
class EarthquakeFeed {
  const EarthquakeFeed({required this.latest, required this.recent});

  final Earthquake latest;
  final List<Earthquake> recent;
}
