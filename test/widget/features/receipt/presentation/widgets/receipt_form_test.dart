import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';
import 'package:expense_tracker/features/receipt/presentation/widgets/receipt_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/pump_app.dart';

ReceiptInput buildInput({int supplierId = 1, String paymentMethod = 'Μετρητά'}) {
  return ReceiptInput(
    date: DateTime(2026, 9, 11),
    supplierId: supplierId,
    paymentMethod: paymentMethod,
    items: const [
      ReceiptItemInput(itemId: 5, quantity: 2, unitPrice: 10),
    ],
  );
}

void main() {
  group('ReceiptForm', () {
    testWidgets('σχεδιάζει όλα τα πεδία', (tester) async {
      await pumpApp(
        tester,
        ReceiptForm(initial: buildInput(), onChanged: (_) {}),
      );
      expect(find.text(AppStrings.receiptDate), findsOneWidget);
      expect(find.text(AppStrings.supplier), findsOneWidget);
      expect(find.text(AppStrings.paymentMethod), findsOneWidget);
      expect(find.text(AppStrings.receiptNotes), findsOneWidget);
      expect(find.text(AppStrings.addLine), findsOneWidget);
    });

    testWidgets('αρχικό onChanged με items από initial (seed)', (tester) async {
      ReceiptInput? result;
      final initial = buildInput();
      await pumpApp(
        tester,
        ReceiptForm(initial: initial, onChanged: (input) => result = input),
      );
      // Αν υπάρχει έστω ένα listener, το notify τρέχει στο initState — αλλά
      // το onChanged καλείται μόνο μετά το build (no call στο init). Γι' αυτό
      // ερεθίζουμε αλλαγή:
      await tester.enterText(find.widgetWithText(TextField, '1'), '2');
      await tester.pump();
      expect(result, isNotNull);
      expect(result!.supplierId, 2);
      expect(result!.items, hasLength(1));
    });

    testWidgets('προσθήκη γραμμής → onChanged με 2 γραμμές', (tester) async {
      List<ReceiptItemInput>? captured;
      ReceiptInput? result;
      await pumpApp(
        tester,
        ReceiptForm(
          initial: buildInput(),
          onChanged: (input) {
            result = input;
            captured = input.items;
          },
        ),
      );
      await tester.enterText(find.widgetWithText(TextField, '1'), '2');
      await tester.tap(find.text(AppStrings.addLine));
      await tester.pump();
      expect(captured, hasLength(2));
      expect(result!.items.last.vatRate, AppConstants.defaultVatRate);
    });

    testWidgets('notes προωθούνται (trimmed)', (tester) async {
      ReceiptInput? result;
      await pumpApp(
        tester,
        ReceiptForm(initial: buildInput(), onChanged: (input) => result = input),
      );
      await tester.enterText(
          find.widgetWithText(TextField, '1'), '2'); // trigger κάποιο notify
      await tester.enterText(
          find.widgetWithText(TextField, AppStrings.receiptNotes), '  σημείωση  ');
      await tester.pump();
      expect(result!.notes, 'σημείωση');
    });

    testWidgets('επεξεργασία supplier → onChanged με νέο supplierId',
        (tester) async {
      ReceiptInput? result;
      await pumpApp(
        tester,
        ReceiptForm(initial: buildInput(), onChanged: (input) => result = input),
      );
      await tester.enterText(find.widgetWithText(TextField, '1'), '9');
      await tester.pump();
      expect(result!.supplierId, 9);
    });

    testWidgets('αρχικές γραμμές εμφανίζονται', (tester) async {
      await pumpApp(
        tester,
        ReceiptForm(
          initial: buildInput(
            supplierId: 3,
            paymentMethod: AppConstants.paymentMethods.first,
          ),
          onChanged: (_) {},
        ),
      );
      expect(find.widgetWithText(TextField, '3'), findsOneWidget);
      expect(find.widgetWithText(TextField, '2'), findsOneWidget);
    });
  });
}