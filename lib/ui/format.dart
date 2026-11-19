// UI LAYER - Fungsi bantu format tampilan (tanpa package tambahan).

import 'package:flutter/material.dart';

const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// "Rab, 7 Okt"
String formatDay(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]}';

/// "22:15"
String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// 25.7 -> "25,7" (desimal gaya Indonesia)
String formatNumber(double v, {int decimals = 1}) =>
    v.toStringAsFixed(decimals).replaceAll('.', ',');

/// 25.7 -> "25,7°"
String formatTemp(double v) => '${formatNumber(v)}°';

/// Keterangan + ikon cuaca dari kode WMO yang dipakai Open-Meteo.
/// Daftar lengkap ada di dokumentasi Open-Meteo ("WMO Weather interpretation codes").
({String label, IconData icon}) describeWeather(int code) => switch (code) {
  0 => (label: 'Cerah', icon: Icons.wb_sunny_outlined),
  1 => (label: 'Cerah berawan', icon: Icons.wb_cloudy_outlined),
  2 => (label: 'Berawan sebagian', icon: Icons.cloud_outlined),
  3 => (label: 'Berawan', icon: Icons.cloud),
  45 || 48 => (label: 'Berkabut', icon: Icons.foggy),
  51 || 53 || 55 => (label: 'Gerimis', icon: Icons.grain),
  56 || 57 => (label: 'Gerimis beku', icon: Icons.grain),
  61 || 63 || 65 => (label: 'Hujan', icon: Icons.umbrella_outlined),
  66 || 67 => (label: 'Hujan beku', icon: Icons.umbrella_outlined),
  71 || 73 || 75 || 77 => (label: 'Salju', icon: Icons.ac_unit),
  80 || 81 || 82 => (label: 'Hujan lokal', icon: Icons.umbrella),
  85 || 86 => (label: 'Salju lokal', icon: Icons.ac_unit),
  95 => (label: 'Badai petir', icon: Icons.thunderstorm_outlined),
  96 || 99 => (label: 'Badai petir + hujan es', icon: Icons.thunderstorm),
  _ => (label: 'Kode $code', icon: Icons.help_outline),
};

/// Warna magnitudo gempa: hijau (<4), oranye (4-5,9), merah (>=6).
Color magnitudeColor(double m) {
  if (m < 4) return Colors.green.shade600;
  if (m < 6) return Colors.orange.shade700;
  return Colors.red.shade700;
}
