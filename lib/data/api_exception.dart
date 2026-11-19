// DATA LAYER - Satu jenis error untuk semua kegagalan API.
//
// Tujuannya: lapisan UI tidak perlu tahu detail package http / dart:io.
// Cukup memeriksa `kind` untuk memilih pesan & tindakan (indikator e:
// menganalisis error response dan menentukan solusinya).

enum ApiErrorKind {
  noConnection, // tidak ada internet / host tidak ditemukan / CORS ditolak (web)
  timeout, // server tidak menjawab dalam batas waktu
  badRequest, // 400: parameter salah
  unauthorized, // 401: API key tidak ada / salah
  forbidden, // 403: key benar tetapi tidak punya izin / paket
  notFound, // 404: endpoint atau data tidak ada
  rateLimited, // 429: terlalu sering memanggil
  server, // 5xx: masalah di sisi server
  invalidData, // 200 tetapi isinya bukan JSON / struktur tidak sesuai model
  unknown, // status lain yang tidak dikenali
}

class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode, this.detail, this.uri});

  final ApiErrorKind kind;
  final int? statusCode;

  /// Isi body / pesan asli dari server. Untuk DEBUGGING, bukan untuk pengguna.
  final String? detail;
  final Uri? uri;

  /// Memetakan status code HTTP ke jenis error.
  factory ApiException.fromStatusCode(
    int statusCode, {
    String? body,
    Uri? uri,
  }) {
    final kind = switch (statusCode) {
      400 => ApiErrorKind.badRequest,
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      429 => ApiErrorKind.rateLimited,
      >= 500 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    };
    return ApiException(kind, statusCode: statusCode, detail: body, uri: uri);
  }

  /// Pesan ramah untuk PENGGUNA (bahasa manusia, bisa ditindaklanjuti).
  String get userMessage => switch (kind) {
    ApiErrorKind.noConnection =>
      'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.',
    ApiErrorKind.timeout =>
      'Server lama tidak merespons. Coba lagi beberapa saat.',
    ApiErrorKind.badRequest => 'Permintaan tidak valid (400).',
    ApiErrorKind.unauthorized =>
      'Akses ditolak (401): API key tidak ada atau salah.',
    ApiErrorKind.forbidden =>
      'Akses dilarang (403): API key tidak memiliki izin.',
    ApiErrorKind.notFound => 'Data tidak ditemukan (404).',
    ApiErrorKind.rateLimited =>
      'Terlalu banyak permintaan (429). Tunggu sebentar.',
    ApiErrorKind.server =>
      'Server sedang bermasalah (${statusCode ?? '5xx'}). Coba lagi nanti.',
    ApiErrorKind.invalidData => 'Format data dari server tidak dikenali.',
    ApiErrorKind.unknown => 'Terjadi kesalahan (${statusCode ?? '-'}).',
  };

  /// Petunjuk untuk PENGEMBANG: siapa/apa yang harus diperbaiki?
  String get developerHint => switch (kind) {
    ApiErrorKind.noConnection =>
      'Periksa koneksi, nama host, HTTPS, izin INTERNET (Android) dan CORS (web).',
    ApiErrorKind.timeout =>
      'Sediakan tombol coba lagi; pertimbangkan batas waktu lebih longgar atau cache.',
    ApiErrorKind.badRequest =>
      'Kesalahan di KODE KITA: cocokkan nama & format parameter dengan dokumentasi API.',
    ApiErrorKind.unauthorized =>
      'Pasang API key yang benar (header/query sesuai dokumentasi). Jangan hardcode di kode.',
    ApiErrorKind.forbidden =>
      'Key benar tetapi tidak berhak: periksa paket/kuota atau pembatasan key.',
    ApiErrorKind.notFound =>
      'Periksa path endpoint & versi API; untuk data, tampilkan "tidak ditemukan".',
    ApiErrorKind.rateLimited =>
      'Kurangi frekuensi panggilan: debounce pencarian, cache, atau tunggu sesuai Retry-After.',
    ApiErrorKind.server =>
      'Bukan salah aplikasi. Tampilkan pesan + coba lagi; laporkan bila berulang.',
    ApiErrorKind.invalidData =>
      'API berubah atau URL salah. Cocokkan model fromJson dengan respons terbaru.',
    ApiErrorKind.unknown =>
      'Catat status code & body, lalu periksa dokumentasi API.',
  };

  @override
  String toString() =>
      'ApiException(${kind.name}, status: $statusCode, uri: $uri)';
}

/// Menjalankan [parse]. Bila struktur JSON tidak sesuai dugaan model
/// (field hilang atau tipe berbeda), ubah menjadi ApiException.invalidData
/// agar aplikasi menampilkan pesan, bukan crash.
T parseOrThrow<T>(T Function() parse, {Uri? uri}) {
  try {
    return parse();
  } on TypeError catch (e) {
    // mis. null di-cast ke String, atau int di-cast ke String
    throw ApiException(
      ApiErrorKind.invalidData,
      detail: 'Struktur JSON tidak sesuai model: $e',
      uri: uri,
    );
  } on FormatException catch (e) {
    // mis. DateTime.parse / double.parse gagal
    throw ApiException(
      ApiErrorKind.invalidData,
      detail: 'Nilai tidak bisa diubah: ${e.message}',
      uri: uri,
    );
  }
}
