/// Unit test απόδειξης disposal των chart families (§2.1 · 27-09-2026).
///
/// Οι 5 chart families είναι `autoDispose`: query που παύει να
/// παρακολουθείται αποδεσμεύει το DB watch του (όχι leak). Έλεγχος μέσω
/// build-counter override μίας family (αντιπροσωπευτικά): mount watcher →
/// unmount → re-mount ξαναχτίζει (builds 1→2). Widget pump (όχι
/// `container.listen` — επιστρέφει void, δεν ακυρώνεται).
/// Fallback: αν φανεί flaky, απόσυρση (αποδοχή με suite-green).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/providers/stream_providers.dart';

void main() {
  testWidgets('chart family: unmount + re-mount ξαναχτίζει (autoDispose)',
      (tester) async {
    var builds = 0;
    final query = (from: DateTime(2026, 1, 1), to: DateTime(2026, 2, 1));

    Widget scope({required bool watch}) => ProviderScope(
          overrides: [
            categoryTotalsProvider.overrideWith((ref, q) {
              builds++;
              return Stream.value(const <ChartSlice>[]);
            }),
          ],
          child: MaterialApp(home: watch ? _Watcher(query: query) : const SizedBox()),
        );

    await tester.pumpWidget(scope(watch: true));
    await tester.pumpAndSettle();
    expect(builds, 1);

    await tester.pumpWidget(scope(watch: false));
    await tester.pumpAndSettle();

    await tester.pumpWidget(scope(watch: true));
    await tester.pumpAndSettle();
    expect(builds, 2);
    expect(tester.takeException(), isNull);
  });
}

/// Ελάχιστος watcher family instance (lifecycle κάρτας, §2.1).
class _Watcher extends ConsumerWidget {
  const _Watcher({required this.query});

  final ChartQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryTotalsProvider(query));
    return const Text('watcher');
  }
}
