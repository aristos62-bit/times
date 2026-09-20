/// Tests για το SPoT `CurrencyTextField` (presentation/shared) — Φάση 3 Βήμα 5
/// (DESIGN §2.4). Unit tests για parse/format + widget tests (typing rules).
///
/// Test IDs: B5α-CSF1..N.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:times/presentation/shared/currency_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CurrencyTextField.parseCents', () {
    test('CSF1: null / κενό / whitespace → null', () {
      expect(CurrencyTextField.parseCents(null), isNull);
      expect(CurrencyTextField.parseCents(''), isNull);
      expect(CurrencyTextField.parseCents('   '), isNull);
    });

    test('CSF2: ακέραιος και δεκαδικά με "." ή "," → cents', () {
      expect(CurrencyTextField.parseCents('2'), 200);
      expect(CurrencyTextField.parseCents('2,5'), 250);
      expect(CurrencyTextField.parseCents('2.5'), 250);
      expect(CurrencyTextField.parseCents('2,50'), 250);
      expect(CurrencyTextField.parseCents('0,05'), 5);
      // €99.999,99 = 9.999.999 cents = maxPriceCents (ακριβώς στο όριο).
      expect(CurrencyTextField.parseCents('99999,99'), 9999999);
    });

    test('CSF3: μη-έγκυρο κείμενο → null (γράμματα, σύμβολα, κενό)', () {
      expect(CurrencyTextField.parseCents('abc'), isNull);
      expect(CurrencyTextField.parseCents('2,5 €'), isNull);
      expect(CurrencyTextField.parseCents('2ä5'), isNull);
      expect(CurrencyTextField.parseCents('-2,5'), isNull);
      expect(CurrencyTextField.parseCents('2..5'), isNull);
      expect(CurrencyTextField.parseCents('2,'), isNull); // κενό κλάσμα
    });

    test('CSF4: πάνω από maxPriceCents → null (όριο εισόδου)', () {
      expect(CurrencyTextField.parseCents('100000'), isNull); // > €99.999,99
      expect(CurrencyTextField.parseCents('100000,00'), isNull);
      expect(CurrencyTextField.parseCents('99999,99'), 9999999); // ακμή OK
      expect(CurrencyTextField.parseCents('100000,01'), isNull);
    });

    test('CSF5: >2 δεκαδικά ψηφία → null', () {
      expect(CurrencyTextField.parseCents('2,555'), isNull);
      expect(CurrencyTextField.parseCents('2,5555'), isNull);
    });
  });

  group('CurrencyTextField.formatCents', () {
    test('CSF6: cents → κείμενο με κόμμα και 2 δεκαδικά', () {
      expect(CurrencyTextField.formatCents(250), '2,50');
      expect(CurrencyTextField.formatCents(5), '0,05');
      expect(CurrencyTextField.formatCents(10000), '100,00');
      expect(CurrencyTextField.formatCents(999999999), '9999999,99');
      expect(CurrencyTextField.formatCents(0), '0,00');
    });
  });

  group('CurrencyTextField (widget)', () {
    testWidgets('CSF7: label, hint και suffix εμφανίζονται', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_wrap(CurrencyTextField(
        controller: controller,
        labelText: 'Τιμή (*)',
        hintText: 'π.χ. 2,50',
        suffixText: '€',
      )));

      expect(find.text('Τιμή (*)'), findsOneWidget);
      expect(find.text('π.χ. 2,50'), findsOneWidget);
      expect(find.text('€'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('CSF8: typing καθαρίζεται (γράμματα και 3ο δεκαδικό κόβονται)',
        (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_wrap(CurrencyTextField(
        controller: controller,
        labelText: 'Τιμή (*)',
      )));

      await tester.enterText(find.byType(TextField), '2,555a');
      await tester.pump();

      // Formatter: γράμμα κόπηκε και το 3ο δεκαδικό περικόπηκε → «2,55».
      expect(controller.text, '2,55');
      expect(CurrencyTextField.parseCents(controller.text), 255);
      controller.dispose();
    });

    testWidgets('CSF9: onChanged καλείται με το καθαρισμένο κείμενο',
        (tester) async {
      final controller = TextEditingController();
      String? lastChanged;
      await tester.pumpWidget(_wrap(CurrencyTextField(
        controller: controller,
        labelText: 'Τιμή (*)',
        onChanged: (value) => lastChanged = value,
      )));

      await tester.enterText(find.byType(TextField), '2,5');
      await tester.pump();

      expect(lastChanged, '2,5');
      controller.dispose();
    });
  });
}