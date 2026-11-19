# Cuaca Lokasi Saya

## Identitas Aplikasi

Nama Aplikasi: Cuaca Lokasi Saya

Platform: Flutter (Android)

Tema: Informasi Cuaca Berdasarkan Lokasi Pengguna

## Deskripsi Aplikasi

Cuaca Lokasi Saya merupakan aplikasi Flutter yang memanfaatkan API Open\-Meteo dan fitur GPS perangkat untuk menampilkan informasi cuaca berdasarkan lokasi pengguna. Selain informasi cuaca, aplikasi juga menyediakan informasi gempa bumi terkini dari BMKG dan fitur pengujian API untuk mengevaluasi berbagai kondisi error yang mungkin terjadi saat proses integrasi API.

## Kondisi Awal

Aplikasi dikembangkan dari project referensi InfoCuaca yang diberikan pada praktikum Pertemuan 6 dan Pertemuan 7 mata kuliah Aplikasi Berbasis Platform.

Project awal telah menyediakan contoh penggunaan:

- HTTP Client
- Open\-Meteo API
- BMKG API
- GPS menggunakan Geolocator
- MVVM Pattern
- Repository Pattern

## Perubahan yang Dilakukan

Pengembangan yang dilakukan pada project awal meliputi:

- Mengubah identitas aplikasi menjadi "Cuaca Lokasi Saya".
- Mengintegrasikan fitur GPS untuk memperoleh lokasi pengguna.
- Menampilkan informasi cuaca berdasarkan lokasi pengguna.
- Menambahkan penanganan error GPS dan API.
- Menambahkan unit test untuk parsing WeatherReport.
- Melakukan pengujian API menggunakan halaman Uji API.
- Menyesuaikan konfigurasi Android Manifest untuk permission lokasi.

## Arsitektur Aplikasi

View ↓ ViewModel ↓ Repository / Service ↓ Open\-Meteo API / GPS Device

Implementasi utama:

- WeatherView
- WeatherViewModel
- WeatherRepository
- LocationService

## API yang Digunakan

### Open\-Meteo API

Dokumentasi:

[https://open\-meteo.com](https://open-meteo.com)

Fungsi:

- Data cuaca saat ini
- Prakiraan cuaca harian

### BMKG API

Dokumentasi:

[https://data.bmkg.go.id](https://data.bmkg.go.id)

Fungsi:

- Informasi gempa bumi terkini

## Fitur Device

Aplikasi menggunakan GPS perangkat melalui package:

geolocator

Fitur GPS digunakan untuk memperoleh koordinat latitude dan longitude pengguna yang kemudian digunakan untuk memanggil Open\-Meteo API.

## Permission Android

File:

android/app/src/main/AndroidManifest.xml

Permission yang digunakan:

<uses\-permission android:name="android.permission.ACCESS\_FINE\_LOCATION"/>

## <uses\-permission android:name="android.permission.ACCESS\_COARSE\_LOCATION"/>Cara Menjalankan Project

### 1\. Clone Repository

git clone [https://github.com/putrielisabetradjaudju1\-wq/Cuaca\_Lokasi\_Saya.git](https://github.com/putrielisabetradjaudju1-wq/Cuaca_Lokasi_Saya.git)

### 2\. Masuk ke Folder Project

cd Cuaca\_Lokasi\_Saya

### 3\. Install Dependency

flutter pub get

### 4\. Jalankan Emulator Android

Gunakan Android Emulator API 35 atau perangkat Android fisik.

### 5\. Jalankan Aplikasi

flutter run

## Menjalankan Test

flutter test

## Analisis Kode

flutter analyze

Hasil terakhir:

- flutter analyze → No issues found
- flutter test → All tests passed

## Kendala

Pada pengujian menggunakan Android Emulator, GPS tidak berhasil memperoleh koordinat lokasi meskipun permission lokasi telah diberikan dan lokasi emulator telah diatur.

Aplikasi menangani kondisi tersebut dengan menampilkan pesan yang ramah kepada pengguna dan menyediakan alternatif pencarian kota secara manual sehingga aplikasi tetap dapat digunakan tanpa mengalami crash.

## Referensi

- Flutter Documentation
- Open\-Meteo API Documentation
- BMKG Data API
- Geolocator Package Documentation
- Microsoft Copilot (digunakan sebagai alat bantu debugging, dokumentasi, dan penjelasan implementasi)



















<!-- # info_cuaca

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference. -->
