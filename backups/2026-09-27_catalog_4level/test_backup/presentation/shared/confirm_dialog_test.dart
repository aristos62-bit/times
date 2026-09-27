/// Widget tests — `ConfirmDialog` (shared §2.4 / exit-confirm §2.2).
///
/// Επαληθεύει:
///   * SPoT defaults (§1.3) — τίτλος/κουμπιά από το `AppMessages`.
///   * Custom title/message/labels από παραμέτρους.
///   * Τις τρεις εκβάσεις του `showConfirmDialog`: `true` («Ναι»),
///     `false` («Ακύρωση»), `null` (dismiss μέσω barrier).
///   * `isDestructive` — το κουμπί επιβεβαίωσης αποκτά error styling.
///   * Responsive §1.4 — μακρύ μήνυμα σε στενή οθόνη, κανένα overflow.
/// Hermetic: κανένα provider/DB (§2.0.1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_messages.dart';
import 'package:times/presentation/shared/confirm_dialog.dart';

void main() {
  /// Επιστρέφει `open`: pump-άρει MaterialApp + ανοίγει το dialog μέσω
  /// `showConfirmDialog` (trigger button) και `value`: το αποτέλεσμα του
  /// dialog (true/false/null). Οι παράμετροι περνούν αυτούσιες στο dialog.
  ({Future<void> Function() open, bool? Function() value}) launch(
    WidgetTester tester, {
    String message = 'Μήνυμα δοκιμής',
    String? title,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
  }) {
    bool? result;
    return (
      open: () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showConfirmDialog(
                      context,
                      message: message,
                      title: title,
                      confirmLabel: confirmLabel,
                      cancelLabel: cancelLabel,
                      isDestructive: isDestructive,
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
      },
      value: () => result,
    );
  }

  group('ConfirmDialog', () {
    testWidgets('defaults: SPoT τίτλος/μήνυμα/κουμπιά (§2.4)', (tester) async {
      final dlg = launch(tester);
      await dlg.open();
      expect(find.text(AppMessages.confirmDialogTitle), findsOneWidget);
      expect(find.text('Μήνυμα δοκιμής'), findsOneWidget);
      expect(find.text(AppMessages.confirmDialogConfirm), findsOneWidget);
      expect(find.text(AppMessages.confirmDialogCancel), findsOneWidget);
    });

    testWidgets('custom title/message/labels render σωστά', (tester) async {
      final dlg = launch(
        tester,
        message: 'Σίγουρα θέλετε διαγραφή;',
        title: 'Προσοχή',
        confirmLabel: 'Διαγραφή',
        cancelLabel: 'Όχι',
      );
      await dlg.open();
      expect(find.text('Προσοχή'), findsOneWidget);
      expect(find.text('Σίγουρα θέλετε διαγραφή;'), findsOneWidget);
      expect(find.text('Διαγραφή'), findsOneWidget);
      expect(find.text('Όχι'), findsOneWidget);
      expect(find.text(AppMessages.confirmDialogConfirm), findsNothing);
    });

    testWidgets('«Ναι» → true και το dialog κλείνει', (tester) async {
      final dlg = launch(tester);
      await dlg.open();
      await tester.tap(find.text(AppMessages.confirmDialogConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmDialog), findsNothing);
      expect(dlg.value(), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('«Ακύρωση» → false και το dialog κλείνει', (tester) async {
      final dlg = launch(tester);
      await dlg.open();
      await tester.tap(find.text(AppMessages.confirmDialogCancel));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmDialog), findsNothing);
      expect(dlg.value(), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dismiss (barrier tap) → null — ο καλών το μετρά ως ακύρωση',
        (tester) async {
      final dlg = launch(tester);
      await dlg.open();
      // Tap έξω από το dialog (πάνω αριστερά = barrier) → dismiss.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmDialog), findsNothing);
      expect(dlg.value(), isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('isDestructive → κουμπί με error styling', (tester) async {
      final dlg = launch(tester, isDestructive: true);
      await dlg.open();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AppMessages.confirmDialogConfirm),
      );
      expect(button.style, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('μη-destructive → προεπιλεγμένο styling (style null)',
        (tester) async {
      final dlg = launch(tester);
      await dlg.open();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AppMessages.confirmDialogConfirm),
      );
      expect(button.style, isNull);
    });

    testWidgets('responsive §1.4: μακρύ μήνυμα σε στενή οθόνη — κανένα overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dlg = launch(tester, message: 'Ένας πολύ μακρύς τίτλος ' * 20);
      await dlg.open();
      expect(tester.takeException(), isNull);
      expect(find.byType(ConfirmDialog), findsOneWidget);
    });
  });
}