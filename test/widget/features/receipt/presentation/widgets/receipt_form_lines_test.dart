import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/features/receipt/domain/models/receipt_input.dart';
import 'package:expense_tracker/features/receipt/presentation/widgets/receipt_form_lines.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('ReceiptFormLines', () {
    testWidgets('σχεδιάζει γραμμές από items + κουμπί προσθήκης',
        (tester) async {
      await pumpApp(
        tester,
        ReceiptFormLines(
          items: const [
            ReceiptItemInput(itemId: 5, quantity: 2, unitPrice: 10),
          ],
          onChanged: (_) {},
        ),
      );
      expect(find.text(AppStrings.addLine), findsOneWidget);
      expect(find.widgetWithText(TextField, '5'), findsOneWidget);
      expect(find.widgetWithText(TextField, '10'), findsOneWidget);
      // Labels όλων των πεδίων γραμμής:
      expect(find.text(AppStrings.item), findsOneWidget);
      expect(find.text(AppStrings.quantity), findsOneWidget);
      expect(find.text(AppStrings.unitPrice), findsOneWidget);
      expect(find.text(AppStrings.vatRate), findsOneWidget);
      expect(find.text(AppStrings.discount), findsOneWidget);
    });

    testWidgets('προσθήκη γραμμής → onChanged με 2η γραμμή (default vatRate)',
        (tester) async {
      List<ReceiptItemInput>? result;
      await pumpApp(
        tester,
        ReceiptFormLines(
          items: const [
            ReceiptItemInput(itemId: 5, quantity: 2, unitPrice: 10),
          ],
          onChanged: (items) => result = items,
        ),
      );
      await tester.tap(find.text(AppStrings.addLine));
      await tester.pump();
      expect(result, hasLength(2));
      expect(result!.last.vatRate, AppConstants.defaultVatRate);
    });

    testWidgets('επεξεργασία quantity → onChanged με νέα τιμή', (tester) async {
      List<ReceiptItemInput>? result;
      await pumpApp(
        tester,
        ReceiptFormLines(
          items: const [
            ReceiptItemInput(itemId: 5, quantity: 2, unitPrice: 10),
          ],
          onChanged: (items) => result = items,
        ),
      );
      await tester.enterText(find.widgetWithText(TextField, '2'), '7');
      await tester.pump();
      expect(result!.single.quantity, 7);
    });

    testWidgets('επεξεργασία με ελληνικό κόμμα unitPrice', (tester) async {
      List<ReceiptItemInput>? result;
      await pumpApp(
        tester,
        ReceiptFormLines(
          items: const [
            ReceiptItemInput(itemId: 5, quantity: 2, unitPrice: 10),
          ],
          onChanged: (items) => result = items,
        ),
      );
      await tester.enterText(find.widgetWithText(TextField, '10'), '12,50');
      await tester.pump();
      expect(result!.single.unitPrice, 12.5);
    });

    testWidgets('διαγραφή γραμμής → onChanged με 0 γραμμές', (tester) async {
      List<ReceiptItemInput>? result = const [];
      await pumpApp(
        tester,
        ReceiptFormLines(
          items: const [
            ReceiptItemInput(itemId: 5, quantity: 2, unitPrice: 10),
          ],
          onChanged: (items) => result = items,
        ),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      expect(result, isEmpty);
    });

    testWidgets('κείμενο στο itemId χωρίς crash → itemId 0', (tester) async {
      List<ReceiptItemInput>? result;
      await pumpApp(
        tester,
        ReceiptFormLines(
          items: const [
            ReceiptItemInput(itemId: 5, quantity: 2, unitPrice: 10),
          ],
          onChanged: (items) => result = items,
        ),
      );
      await tester.enterText(find.widgetWithText(TextField, '5'), 'abc');
      await tester.pump();
      expect(result!.single.itemId, 0);
    });
  });
}