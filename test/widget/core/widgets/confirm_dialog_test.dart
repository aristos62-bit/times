import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/core/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

Future<BuildContext> _host(WidgetTester tester) async {
  late BuildContext ctx;
  await pumpApp(
    tester,
    Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }),
  );
  return ctx;
}

void main() {
  group('ConfirmDialog', () {
    testWidgets('confirm → true', (tester) async {
      final ctx = await _host(tester);
      bool? result;
      ConfirmDialog.show(ctx, title: 'T', message: 'M')
          .then((v) => result = v);
      await tester.pump();
      await tester.tap(find.text(AppStrings.confirm));
      await tester.pump();
      expect(result, isTrue);
    });

    testWidgets('cancel → false', (tester) async {
      final ctx = await _host(tester);
      bool? result;
      ConfirmDialog.show(ctx, title: 'T', message: 'M')
          .then((v) => result = v);
      await tester.pump();
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pump();
      expect(result, isFalse);
    });

    testWidgets('showDelete → delete label', (tester) async {
      final ctx = await _host(tester);
      bool? result;
      ConfirmDialog.showDelete(ctx).then((v) => result = v);
      await tester.pump();
      expect(find.text(AppStrings.deleteConfirmTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.delete));
      await tester.pump();
      expect(result, isTrue);
    });
  });
}
