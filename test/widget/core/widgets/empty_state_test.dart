import 'package:expense_tracker/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('EmptyState', () {
    testWidgets('μήνυμα χωρίς action', (tester) async {
      await pumpApp(tester, const EmptyState(message: 'Άδειο'));
      expect(find.text('Άδειο'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('action button + callback', (tester) async {
      var pressed = false;
      await pumpApp(
        tester,
        EmptyState(
          message: 'Άδειο',
          actionLabel: 'Πρόσθεσε',
          onAction: () => pressed = true,
        ),
      );
      await tester.tap(find.text('Πρόσθεσε'));
      await tester.pump();
      expect(pressed, isTrue);
    });
  });
}
