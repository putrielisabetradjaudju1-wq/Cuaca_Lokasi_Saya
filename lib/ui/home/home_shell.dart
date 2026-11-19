// UI LAYER - Kerangka utama: NavigationBar (ponsel) / NavigationRail (lebar),
// pola yang sama dengan TugasKu P4.

import 'package:flutter/material.dart';

import '../api_test/api_test_view.dart';
import '../api_test/api_test_view_model.dart';
import '../earthquake/earthquake_view.dart';
import '../earthquake/earthquake_view_model.dart';
import '../weather/weather_view.dart';
import '../weather/weather_view_model.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.weatherViewModel,
    required this.earthquakeViewModel,
    required this.apiTestViewModel,
  });

  final WeatherViewModel weatherViewModel;
  final EarthquakeViewModel earthquakeViewModel;
  final ApiTestViewModel apiTestViewModel;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _items = [
    (icon: Icons.wb_sunny_outlined, selected: Icons.wb_sunny, label: 'Cuaca'),
    (icon: Icons.vibration, selected: Icons.vibration, label: 'Gempa'),
    (icon: Icons.science_outlined, selected: Icons.science, label: 'Uji API'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      WeatherView(viewModel: widget.weatherViewModel),
      EarthquakeView(viewModel: widget.earthquakeViewModel),
      ApiTestView(viewModel: widget.apiTestViewModel),
    ];
    final body = IndexedStack(index: _index, children: pages);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: .all,
                  destinations: [
                    for (final it in _items)
                      NavigationRailDestination(
                        icon: Icon(it.icon),
                        selectedIcon: Icon(it.selected),
                        label: Text(it.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final it in _items)
                NavigationDestination(
                  icon: Icon(it.icon),
                  selectedIcon: Icon(it.selected),
                  label: it.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
