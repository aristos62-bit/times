/// Widget tests για το SPoT `AppFeedback` (core/utils/app_feedback.dart) — §2.0.6.
///
/// Καλύπτει: εμφάνιση success/error, error χρώματα από ColorScheme, no-op
/// χωρίς ScaffoldMessenger, clear στο error, queue στο success, auto-dismiss
/// (AppConstants.snackBarDurationSeconds), overflow safety σε στενή οθόνη και
/// guard μετά από unmount (context.mounted).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/core/utils/app_feedback.dart';

/// Δημιουργεί MaterialApp με Scaffold και κουμπί «tap» που καλεί [onPressed]
/// με το context του Builder (ενεργό, mounted, με ScaffoldMessenger).
Future<void> _pumpApp(
  WidgetTester tester, {
  required void Function(BuildContext context) onPressed,
  ColorScheme? scheme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: scheme == null ? null : ThemeData(colorScheme: scheme),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => onPressed(context),
              child: const Text('tap'),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Μετακινεί το ρολόι ώστε το τρέχον snackbar να ζήσει ολόκληρη τη ζωή του:
/// (1) ολοκλήρωση entry animation → (2) ενεργοποίηση του auto-hide timer
/// (AppConstants.snackBarDurationSeconds) → (3) ολοκλήρωση exit animation.
Future<void> _elapseSnackBarLife(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(
    const Duration(seconds: AppConstants.snackBarDurationSeconds),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppFeedback', () {
    testWidgets('showSuccess εμφανίζει το μήνυμα με default χρώματα',
        (tester) async {
      await _pumpApp(tester, onPressed: (context) {
        AppFeedback.showSuccess(context, 'Αποθηκεύτηκε');
      });

      await tester.tap(find.text('tap'));
      await tester.pump();

      expect(find.text('Αποθηκεύτηκε'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      // Success: Material default — κανένα custom background.
      expect(snackBar.backgroundColor, isNull);
    });

    testWidgets('showError εμφανίζεται με errorContainer/onErrorContainer',
        (tester) async {
      final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF00897B));

      await _pumpApp(
        tester,
        scheme: scheme,
        onPressed: (context) {
          AppFeedback.showError(context, 'Αποτυχία αποθήκευσης');
        },
      );

      await tester.tap(find.text('tap'));
      await tester.pump();

      expect(find.text('Αποτυχία αποθήκευσης'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, scheme.errorContainer);
      final text = tester.widget<Text>(find.text('Αποτυχία αποθήκευσης'));
      expect(text.style?.color, scheme.onErrorContainer);
    });

    testWidgets('χωρίς ScaffoldMessenger → no-op, καμία exception',
        (tester) async {
      BuildContext? ctx;
      await tester.pumpWidget(
        Builder(builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        }),
      );

      // maybeOf → null · δεν κάνει throw, τίποτα δεν εμφανίζεται.
      AppFeedback.showError(ctx!, 'Σφάλμα');

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('showError αντικαθιστά προηγούμενο snackbar (clear)',
        (tester) async {
      await _pumpApp(tester, onPressed: (context) {
        AppFeedback.showSuccess(context, 'Πρώτο μήνυμα');
        AppFeedback.showError(context, 'Σφάλμα');
      });

      await tester.tap(find.text('tap'));
      await tester.pump();

      // Το error διακόπτει το success — δεν περιμένει στην ουρά.
      expect(find.text('Σφάλμα'), findsOneWidget);
      expect(find.text('Πρώτο μήνυμα'), findsNothing);
    });

    testWidgets('showSuccess ΔΕΝ καθαρίζει προηγούμενο (μπαίνει στην ουρά)',
        (tester) async {
      await _pumpApp(tester, onPressed: (context) {
        AppFeedback.showSuccess(context, 'Πρώτο μήνυμα');
        AppFeedback.showSuccess(context, 'Δεύτερο μήνυμα');
      });

      await tester.tap(find.text('tap'));
      await tester.pump();

      // Και τα δύο παραμένουν στην ουρά του messenger· τρέχον = πρώτο.
      expect(find.text('Πρώτο μήνυμα'), findsOneWidget);
      expect(find.text('Δεύτερο μήνυμα'), findsNothing);

      // Μετά τη λήξη του πρώτου εμφανίζεται αυτόματα το δεύτερο.
      await _elapseSnackBarLife(tester);

      expect(find.text('Δεύτερο μήνυμα'), findsOneWidget);
      expect(find.text('Πρώτο μήνυμα'), findsNothing);
    });

    testWidgets('auto-dismiss μετά το snackBarDurationSeconds', (tester) async {
      await _pumpApp(tester, onPressed: (context) {
        AppFeedback.showSuccess(context, 'Προσωρινό μήνυμα');
      });

      await tester.tap(find.text('tap'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);

      // Ο entry animation ολοκληρώνεται πριν ξεκινήσει ο auto-hide timer.
      await _elapseSnackBarLife(tester);

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('μακρύ μήνυμα σε στενή οθόνη → κανένα overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // ~270 χαρακτήρες: πολύ περισσότερο από κάθε γραμμή των 320px.
      final longMessage = 'Αποθηκεύτηκε η απόδειξη με επιτυχία. ' * 6;

      await _pumpApp(tester, onPressed: (context) {
        AppFeedback.showError(context, longMessage);
      });

      await tester.tap(find.text('tap'));
      await tester.pump();

      // maxLines + ellipsis → κανένα RenderFlex/overflow exception.
      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('κλήση μετά από unmount → no-op, καμία exception',
        (tester) async {
      BuildContext? ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            ctx = context;
            return const Scaffold(body: Text('page'));
          }),
        ),
      );

      // Unmount ολόκληρου του δέντρου — το context παύει να είναι mounted.
      await tester.pumpWidget(const SizedBox.shrink());

      // context.mounted guard → return χωρίς exception.
      AppFeedback.showSuccess(ctx!, 'Μήνυμα');

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('showError με logger hooked: snackbar εμφανίζεται ΚΑΙ log [UI]',
        (tester) async {
      final loggedLines = <String>[];
      AppLogger.testSink = loggedLines.add;
      addTearDown(AppLogger.resetTestSink);

      await _pumpApp(tester, onPressed: (context) {
        AppFeedback.showError(context, 'Αποτυχία αποθήκευσης');
      });

      await tester.tap(find.text('tap'));
      await tester.pump();

      // Η ροή εμφάνισης παραμένει ανέπαφη με το logging hooked.
      expect(find.text('Αποτυχία αποθήκευσης'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Το hook logάρει (tag UI) το γεγονός — dev-facing, tag UI (§1.7).
      expect(loggedLines, ['[UI][ERROR] Snackbar σφάλματος εμφανίστηκε']);
    });
  });
}