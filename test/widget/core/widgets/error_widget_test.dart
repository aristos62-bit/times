import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/core/widgets/error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppErrorWidget', () {
    testWidgets('generic + retry callback', (tester) async {
      var retried = false;
      await pumpApp(
        tester,
        AppErrorWidget.generic(onRetry: () => retried = true),
      );
      expect(find.text(AppStrings.genericError), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('database factory', (tester) async {
      await pumpApp(tester, AppErrorWidget.database());
      expect(find.text(AppStrings.databaseError), findsOneWidget);
      expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
    });

    testWidgets('χωρίς onRetry → κανένα κουμπί', (tester) async {
      await pumpApp(tester, const AppErrorWidget(message: 'Ωχ'));
      expect(find.text('Ωχ'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
