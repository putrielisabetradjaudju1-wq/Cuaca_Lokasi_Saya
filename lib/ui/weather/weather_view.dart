// UI LAYER - Halaman cuaca: cari kota -> pilih -> cuaca saat ini + prakiraan.
// P7: tombol "Cuaca di lokasi saya" (GPS) di AppBar + kotak pesan izin lokasi.

import 'package:flutter/material.dart';

import '../../models/location.dart';
import '../../models/weather.dart';
import '../format.dart';
import '../ui_state.dart';
import '../widgets/error_view.dart';
import 'weather_view_model.dart';

class WeatherView extends StatefulWidget {
  const WeatherView({super.key, required this.viewModel});

  final WeatherViewModel viewModel;

  @override
  State<WeatherView> createState() => _WeatherViewState();
}

class _WeatherViewState extends State<WeatherView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadInitial();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    // ListenableBuilder membungkus Scaffold agar AppBar (tombol lokasi) ikut diperbarui.
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Cuaca Lokasi Saya'),
          actions: [
            if (vm.canUseLocation)
              IconButton(
                tooltip: 'Cuaca di lokasi saya',
                icon: const Icon(Icons.my_location),
                onPressed: vm.isLocating ? null : vm.useMyLocation,
              ),
          ],
        ),
        body: Column(
          children: [
            if (vm.isLocating) const LinearProgressIndicator(),
            if (vm.locationMessage != null)
              _LocationMessage(
                message: vm.locationMessage!,
                deniedForever: vm.locationDeniedForever,
                serviceDisabled: vm.locationServiceDisabled,
                onOpenAppSettings: vm.openAppSettings,
                onOpenLocationSettings: vm.openLocationSettings,
                onDismiss: vm.dismissLocationMessage,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _controller,
                textInputAction: .search,
                decoration: InputDecoration(
                  hintText: 'Cari kota, mis. Singaraja',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Bersihkan',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      vm.clearSearch();
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: vm.search,
              ),
            ),
            _SearchResults(
              state: vm.searchState,
              onSelect: (loc) {
                _controller.clear();
                FocusScope.of(context).unfocus();
                vm.select(loc);
              },
              onRetry: () => vm.search(_controller.text),
            ),
            Expanded(
              child: _WeatherBody(
                location: vm.location,
                state: vm.weatherState,
                onRetry: vm.loadWeather,
                onRefresh: vm.refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// P7: pesan bila lokasi tidak bisa dipakai, dengan tindakan yang sesuai.
class _LocationMessage extends StatelessWidget {
  const _LocationMessage({
    required this.message,
    required this.deniedForever,
    required this.serviceDisabled,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
    required this.onDismiss,
  });

  final String message;
  final bool deniedForever;
  final bool serviceDisabled;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            crossAxisAlignment: .start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(Icons.location_off, color: scheme.error),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(message),
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
              ),
            ],
          ),
          if (deniedForever)
            Align(
              alignment: .centerRight,
              child: TextButton(
                onPressed: onOpenAppSettings,
                child: const Text('Buka pengaturan'),
              ),
            ),
          if (serviceDisabled)
            Align(
              alignment: .centerRight,
              child: TextButton(
                onPressed: onOpenLocationSettings,
                child: const Text('Nyalakan lokasi'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.state,
    required this.onSelect,
    required this.onRetry,
  });

  final UiState<List<Location>> state;
  final ValueChanged<Location> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // switch pada sealed class: semua keadaan WAJIB ditangani.
    return switch (state) {
      Idle() => const SizedBox.shrink(),
      Loading() => const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: LinearProgressIndicator(),
      ),
      Failure(:final error) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                error.userMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
      Success(:final data) when data.isEmpty => const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Align(
          alignment: .centerLeft,
          child: Text('Kota tidak ditemukan. Coba ejaan lain.'),
        ),
      ),
      Success(:final data) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Card(
          margin: .zero,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final loc in data)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(loc.label),
                    onTap: () => onSelect(loc),
                  ),
              ],
            ),
          ),
        ),
      ),
    };
  }
}

class _WeatherBody extends StatelessWidget {
  const _WeatherBody({
    required this.location,
    required this.state,
    required this.onRetry,
    required this.onRefresh,
  });

  final Location location;
  final UiState<WeatherReport> state;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      Idle() || Loading() => const Center(child: CircularProgressIndicator()),
      Failure(:final error) => ErrorView(error: error, onRetry: onRetry),
      Success(:final data) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(location.label, style: Theme.of(context).textTheme.titleLarge),
            Text(
              'Diperbarui ${formatTime(data.current.time)} · ${data.timezone}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _CurrentCard(current: data.current, today: data.daily.firstOrNull),
            const SizedBox(height: 16),
            Text(
              'Prakiraan harian',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final (i, day) in data.daily.indexed)
              _DailyTile(day: day, isToday: i == 0),
            const SizedBox(height: 8),
            Text(
              'Sumber: Open-Meteo (open-meteo.com), tanpa API key',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    };
  }
}

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.current, this.today});

  final CurrentWeather current;
  final DailyForecast? today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = describeWeather(current.weatherCode);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Icon(info.icon, size: 64, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        formatTemp(current.temperature),
                        style: theme.textTheme.displayMedium,
                      ),
                      Text(info.label, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.water_drop_outlined,
                  text: 'Kelembapan ${current.humidity}%',
                ),
                _InfoChip(
                  icon: Icons.air,
                  text: 'Angin ${formatNumber(current.windSpeed)} km/j',
                ),
                if (today != null)
                  _InfoChip(
                    icon: Icons.thermostat,
                    text:
                        'Maks ${formatTemp(today!.tempMax)} · Min ${formatTemp(today!.tempMin)}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 18), label: Text(text));
}

class _DailyTile extends StatelessWidget {
  const _DailyTile({required this.day, required this.isToday});

  final DailyForecast day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final info = describeWeather(day.weatherCode);
    final rain = day.precipitationProbability;
    return ListTile(
      contentPadding: .zero,
      leading: Icon(info.icon, size: 32),
      title: Text(isToday ? 'Hari ini' : formatDay(day.date)),
      subtitle: Text(rain == null ? info.label : '${info.label} · hujan $rain%'),
      trailing: Text(
        '${formatTemp(day.tempMax)} / ${formatTemp(day.tempMin)}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
