/// Widget tests — `CategoryEditDialog` (§2.3 / Φάση 4 Βήμα 4).
///
/// Τίτλος/prefill · inline validation (χωρίς pop) · submit trimmed ·
/// Ακύρωση/dismiss → null · καθαρισμός σφάλματος στην πληκτρολόγηση.
/// Responsive 320px (dialog max-width + scroll, §1.4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/core/constants/app_messages.dart';
import 'package:times/presentation/settings/widgets/category_edit_dialog.dart';

void main() {
  /// Αποτέλεσμα του τελευταίου dialog (null = Ακύρωση/dismiss/κλειστό).
  String? lastResult;

  /// Host με κουμπί που ανοίγει το dialog και καταγράφει το αποτέλεσμα.
  Future<void> pumpHost(
    WidgetTester tester, {
    String title = 'Τίτλος',
    String confirmLabel = 'ΟΚ',
    String initialName = '',
  }) async {
    lastResult = 'sentinel';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                lastResult = await showCategoryEditDialog(
                  context,
                  title: title,
                  confirmLabel: confirmLabel,
                  initialName: initialName,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('CategoryEditDialog', () {
    testWidgets('δείχνει τίτλο + prefill + κουμπιά', (tester) async {
      await pumpHost(tester, initialName: 'ΠΑΛΙΟ');
      expect(find.text('Τίτλος'), findsOneWidget);
      expect(find.text('ΠΑΛΙΟ'), findsOneWidget);
      expect(find.text(AppMessages.confirmDialogCancel), findsOneWidget);
      expect(find.text('ΟΚ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('κενό submit → inline nameRequired, χωρίς pop',
        (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('ΟΚ'));
      await tester.pumpAndSettle();
      expect(find.text(AppErrors.nameRequired), findsOneWidget);
      // Χωρίς pop — το dialog παραμένει ανοιχτό.
      expect(find.byType(CategoryEditDialog), findsOneWidget);
      expect(lastResult, 'sentinel');
      expect(tester.takeException(), isNull);
    });

    testWidgets('έγκυρο submit → pop με trimmed όνομα', (tester) async {
      await pumpHost(tester);
      await tester.enterText(find.byType(TextField), '  ΝΕΟ  ');
      await tester.tap(find.text('ΟΚ'));
      await tester.pumpAndSettle();
      expect(lastResult, 'ΝΕΟ');
      expect(find.byType(CategoryEditDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ακύρωση → null', (tester) async {
      await pumpHost(tester, initialName: 'Χ');
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(lastResult, isNull);
      expect(find.byType(CategoryEditDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('το σφάλμα σβήνει στην πληκτρολόγηση της διόρθωσης',
        (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('ΟΚ'));
      await tester.pumpAndSettle();
      expect(find.text(AppErrors.nameRequired), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ΝΕΟ');
      await tester.pump();
      expect(find.text(AppErrors.nameRequired), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile 320px — κανένα overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpHost(tester, initialName: 'Όνομα κατηγορίας δοκιμής');
      expect(tester.takeException(), isNull);
    });
  });
}
