// UI LAYER - Tab "Uji API": menjalankan kasus error & menampilkan analisisnya.

import 'package:flutter/material.dart';

import '../widgets/error_view.dart';
import 'api_test_view_model.dart';

class ApiTestView extends StatelessWidget {
  const ApiTestView({super.key, required this.viewModel});

  final ApiTestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uji API'),
        actions: [
          ListenableBuilder(
            listenable: vm,
            builder: (context, _) => TextButton.icon(
              onPressed: vm.cases.any((c) => vm.isRunning(c.id))
                  ? null
                  : vm.runAll,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Jalankan semua'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Setiap kasus memanggil API sungguhan. Perhatikan status code, '
              'jenis error, pesan untuk pengguna, dan petunjuk perbaikannya.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            for (final c in vm.cases)
              _CaseCard(
                testCase: c,
                running: vm.isRunning(c.id),
                result: vm.resultOf(c.id),
                onRun: () => vm.run(c),
              ),
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.testCase,
    required this.running,
    required this.result,
    required this.onRun,
  });

  final ApiTestCase testCase;
  final bool running;
  final ApiTestResult? result;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(testCase.title, style: theme.textTheme.titleMedium),
                      Text(testCase.request, style: mono),
                      Text(
                        'Harapan: ${testCase.expected}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (running)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton.tonal(
                    onPressed: onRun,
                    child: const Text('Jalankan'),
                  ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 10),
              _ResultBox(result: result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.result});

  final ApiTestResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = result.error;
    final ms = '${result.elapsed.inMilliseconds} ms';
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');

    if (error == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('${result.summary} · $ms')),
          ],
        ),
      );
    }

    final detail = error.detail;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Icon(ErrorView.iconFor(error.kind), color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${error.kind.name}'
                  '${error.statusCode != null ? ' · HTTP ${error.statusCode}' : ''}'
                  ' · $ms',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Pengguna melihat: ${error.userMessage}'),
          Text('Pengembang: ${error.developerHint}'),
          if (detail != null && detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Body/pesan asli: ${detail.length > 220 ? '${detail.substring(0, 220)}…' : detail}',
              style: mono,
            ),
          ],
        ],
      ),
    );
  }
}
