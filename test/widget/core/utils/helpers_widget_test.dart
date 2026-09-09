import 'package:expense_tracker/core/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

Future<BuildContext> _host(WidgetTester tester, [Widget body = const Text('σελίδα')]) async {
  late BuildContext ctx;
  await pumpApp(
    tester,
    Builder(builder: (c) {
      ctx = c;
      return body;
    }),
  );
  return ctx;
}

void main() {
  group('Helpers dialogs/snackbar', () {
    testWidgets('showSnackBar εμφανίζει μήνυμα', (tester) async {
      final ctx = await _host(tester);
      Helpers.showSnackBar(ctx, 'Γεια', isError: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Γεια'), findsOneWidget);
    });

    testWidgets('showLoadingDialog + hideDialog', (tester) async {
      final ctx = await _host(tester);
      Helpers.showLoadingDialog(ctx);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      Helpers.hideDialog(ctx);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('σελίδα'), findsOneWidget);
    });

    testWidgets('hideDialog χωρίς dialog → σελίδα μένει', (tester) async {
      final ctx = await _host(tester);
      Helpers.hideDialog(ctx);
      await tester.pump();
      expect(find.text('σελίδα'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
