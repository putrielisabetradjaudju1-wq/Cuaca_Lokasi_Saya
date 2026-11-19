// UI LAYER - Empat keadaan yang selalu ada saat memuat data dari jaringan.
//
// `sealed` + `switch` membuat compiler MEMAKSA View menangani semua keadaan.
// Lupa menangani "Failure"? Kode tidak akan dikompilasi. Ini mencegah
// aplikasi yang hanya menampilkan spinner selamanya saat API gagal.

import '../data/api_exception.dart';

sealed class UiState<T> {
  const UiState();
}

/// Belum memuat apa pun.
class Idle<T> extends UiState<T> {
  const Idle();
}

/// Sedang menunggu jawaban server -> tampilkan indikator memuat.
class Loading<T> extends UiState<T> {
  const Loading();
}

/// Berhasil, data siap ditampilkan.
class Success<T> extends UiState<T> {
  const Success(this.data);
  final T data;
}

/// Gagal; simpan error-nya agar View bisa menampilkan pesan + tombol coba lagi.
class Failure<T> extends UiState<T> {
  const Failure(this.error);
  final ApiException error;
}
