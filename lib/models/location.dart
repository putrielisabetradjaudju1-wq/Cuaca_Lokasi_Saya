// MODEL - Hasil pencarian kota dari Open-Meteo Geocoding API.
//
// Contoh SATU objek JSON dari server:
// {"id":1645528,"name":"Kota Denpasar","latitude":-8.65,"longitude":115.21667,
//  "country":"Indonesia","admin1":"Provinsi Bali","timezone":"Asia/Makassar", ...}
//
// Field yang tidak kita butuhkan (elevation, population, dll.) cukup diabaikan:
// model hanya mengambil yang dipakai aplikasi.

class Location {
  const Location({
    required this.id,
    required this.name,
    this.admin1,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String? admin1; // provinsi; TIDAK SELALU ADA di JSON -> nullable
  final String country;
  final double latitude;
  final double longitude;

  /// JSON (Map) -> objek Dart. Dipanggil repository setelah jsonDecode.
  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json['id'] as int,
    name: json['name'] as String,
    admin1: json['admin1'] as String?, // null bila key tidak ada
    country: json['country'] as String? ?? '', // nilai cadangan bila tidak ada
    // Angka JSON bisa datang sebagai int (-8) atau double (-8.65):
    // cast ke num dulu, lalu toDouble() agar selalu double.
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  /// Objek Dart -> JSON (dipakai bila ingin menyimpan/mengirim ke server).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'admin1': admin1,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
  };

  /// "Kota Denpasar, Provinsi Bali, Indonesia" (admin1 dilewati bila null).
  String get label =>
      [name, ?admin1, country].where((s) => s.isNotEmpty).join(', ');

  /// P7: lokasi dari GPS. Tidak ada nama kota, jadi tampilkan koordinatnya.
  factory Location.fromCoordinates(double latitude, double longitude) =>
      Location(
        id: 0,
        name:
            'Lokasi saya (${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)})',
        country: '',
        latitude: latitude,
        longitude: longitude,
      );

  /// Lokasi awal saat aplikasi dibuka.
  static const denpasar = Location(
    id: 1645528,
    name: 'Kota Denpasar',
    admin1: 'Provinsi Bali',
    country: 'Indonesia',
    latitude: -8.65,
    longitude: 115.21667,
  );
}
