// UI LAYER - Halaman gempa: gempa terbaru + daftar 15 gempa M>=5 (BMKG).

import 'package:flutter/material.dart';

import '../../models/earthquake.dart';
import '../format.dart';
import '../ui_state.dart';
import '../widgets/error_view.dart';
import 'earthquake_view_model.dart';

class EarthquakeView extends StatefulWidget {
  const EarthquakeView({super.key, required this.viewModel});

  final EarthquakeViewModel viewModel;

  @override
  State<EarthquakeView> createState() => _EarthquakeViewState();
}

class _EarthquakeViewState extends State<EarthquakeView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Gempa Terkini · BMKG')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => switch (vm.state) {
          Idle() || Loading() => const Center(child: CircularProgressIndicator()),
          Failure(:final error) => ErrorView(error: error, onRetry: vm.load),
          Success(:final data) => RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Gempa terbaru',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _LatestCard(quake: data.latest),
                const SizedBox(height: 16),
                Text(
                  '15 gempa terakhir (M ≥ 5,0)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final q in data.recent) _QuakeTile(quake: q),
                const SizedBox(height: 8),
                Text(
                  'Sumber: data.bmkg.go.id (Badan Meteorologi, Klimatologi, dan Geofisika)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

class _MagnitudeBadge extends StatelessWidget {
  const _MagnitudeBadge({required this.magnitude, this.size = 56});

  final double magnitude;
  final double size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: magnitudeColor(magnitude),
    foregroundColor: Colors.white,
    child: Text(
      'M ${formatNumber(magnitude)}',
      style: TextStyle(fontWeight: .bold, fontSize: size / 4),
    ),
  );
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.quake});

  final Earthquake quake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            _MagnitudeBadge(magnitude: quake.magnitude, size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(quake.wilayah, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${quake.tanggal} · ${quake.jam}'),
                  Text(
                    'Kedalaman ${quake.kedalaman} · '
                    '${formatNumber(quake.latitude, decimals: 2)}, '
                    '${formatNumber(quake.longitude, decimals: 2)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quake.potensi,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  if (quake.dirasakan != null)
                    Text(
                      'Dirasakan (MMI): ${quake.dirasakan}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuakeTile extends StatelessWidget {
  const _QuakeTile({required this.quake});

  final Earthquake quake;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: .zero,
    leading: _MagnitudeBadge(magnitude: quake.magnitude, size: 48),
    title: Text(quake.wilayah, maxLines: 2, overflow: .ellipsis),
    subtitle: Text(
      '${quake.tanggal} ${quake.jam} · kedalaman ${quake.kedalaman}',
    ),
  );
}
