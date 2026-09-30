/// Dumb switch κλειδώματος (§2.3 · 30-09-2026).
///
/// Ακριβές σχήμα `SwitchListTile` (precedent `home_customization_section`
/// — `dense` + zero padding + title + subtitle, built-in semantics/
/// theme/responsive δωρεάν). Consumer (§2.0): support-status (`Q4` — κρυφό
/// όταν unsupported) + enabled state + callbacks στον controller· ΚΑΝΕΝΑ
/// business logic εδώ (auth/persist στον `AppLockController`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/providers/app_lock_providers.dart';

/// Switch «Κλείδωμα εφαρμογής» για την κάρτα «Ασφάλεια».
class AppLockSection extends ConsumerWidget {
  const AppLockSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = ref.watch(appLockSupportProvider);
    final lock = ref.watch(appLockProvider);
    // Q4: χωρίς υποστήριξη η κάρτα κρύβεται (όχι disabled — δεν υπάρχει
    // καν η δυνατότητα, pattern desktop-scan). Loading/error → επίσης
    // κρυφό (fail-safe UI· το σφάλμα πάει μόνο στο log).
    return support.when(
      data: (supported) {
        if (!supported) return const SizedBox.shrink();
        return SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.appLockEnableLabel),
          subtitle: const Text(AppStrings.appLockEnableSubtitle),
          value: lock.enabled,
          onChanged: (value) {
            final notifier = ref.read(appLockProvider.notifier);
            if (value) {
              notifier.requestEnable(AppStrings.appLockReason);
            } else {
              notifier.requestDisable(AppStrings.appLockReason);
            }
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) {
        AppLogger.error(
          LogTag.ui,
          'Έλεγχος υποστήριξης κλειδώματος απέτυχε',
          e,
          s,
        );
        return const SizedBox.shrink();
      },
    );
  }
}
