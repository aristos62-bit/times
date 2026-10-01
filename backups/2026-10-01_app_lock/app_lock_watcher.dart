/// Watcher lifecycle για το κλείδωμα (§2.3 · 30-09-2026).
///
/// `ConsumerStatefulWidget` που τυλίγει το [child] (TimesApp μένει
/// ConsumerWidget): `AppLifecycleListener` με `onPause`/`onResume`.
/// Ο watcher ΜΟΝΟ κλειδώνει, ποτέ ξεκλειδώνει (safe by construction —
/// το launch-resume με `lastPaused == null` δεν κάνει τίποτα, το build
/// έχει ήδη κλειδώσει σύγχρονα). `lastPaused` ΜΟΝΟ μνήμη (όχι persist).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/app_lock_providers.dart';

/// Φυλάει το [child] κλειδωμένο μετά από background πέραν της χάριτος.
class AppLockWatcher extends ConsumerStatefulWidget {
  const AppLockWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockWatcher> createState() => _AppLockWatcherState();
}

class _AppLockWatcherState extends ConsumerState<AppLockWatcher> {
  AppLifecycleListener? _listener;

  /// Στιγμή background — null = ποτέ (launch).
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onPause: () => _pausedAt = DateTime.now(),
      onResume: () {
        final pausedAt = _pausedAt;
        _pausedAt = null;
        if (pausedAt == null || !mounted) return;
        if (shouldRelock(pausedAt: pausedAt, now: DateTime.now())) {
          ref.read(appLockProvider.notifier).lock();
        }
      },
    );
  }

  @override
  void dispose() {
    _listener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
