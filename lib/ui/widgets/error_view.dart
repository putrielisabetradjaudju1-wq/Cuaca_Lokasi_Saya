// UI LAYER - Tampilan error yang seragam: ikon, pesan pengguna, tombol coba lagi.
//
// Detail teknis (body dari server) ditampilkan kecil & abu-abu, hanya untuk
// membantu debugging di kelas. Di aplikasi produksi detail ini biasanya
// dikirim ke log, bukan ke layar.

import 'package:flutter/material.dart';

import '../../data/api_exception.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final ApiException error;
  final VoidCallback? onRetry;

  static IconData iconFor(ApiErrorKind kind) => switch (kind) {
    ApiErrorKind.noConnection => Icons.wifi_off,
    ApiErrorKind.timeout => Icons.hourglass_empty,
    ApiErrorKind.unauthorized || ApiErrorKind.forbidden => Icons.lock_outline,
    ApiErrorKind.notFound => Icons.search_off,
    ApiErrorKind.rateLimited => Icons.speed,
    ApiErrorKind.server => Icons.cloud_off,
    ApiErrorKind.invalidData => Icons.data_object,
    ApiErrorKind.badRequest || ApiErrorKind.unknown => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = error.detail;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(iconFor(error.kind), size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              error.userMessage,
              textAlign: .center,
              style: theme.textTheme.titleMedium,
            ),
            if (detail != null && detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail.length > 160 ? '${detail.substring(0, 160)}…' : detail,
                textAlign: .center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
