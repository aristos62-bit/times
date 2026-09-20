/// Tests για το SPoT `QuantityTextField` (presentation/shared) — Φάση 3 Βήμα 5
/// (DESIGN §2.4). Unit tests για parse/format + widget tests (typing rules,
/// συμπεριλαμβανομένου του `allowsDecimal=false`).
///
/// Test IDs: B5α-QTF1..N.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:times/presentation/shared/quantity_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('QuantityTextField.parseQuantity', () {
    test('QTF1: null / κενό / whitespace → null', () {
      expect(
        QuantityTextField.parseQuantity(null, allowsDecimal: true),
        isNull,
      );
      expect(
        QuantityTextField.parseQuantity('', allowsDecimal: true),
        isNull,
      );
      expect(
        QuantityTextField.parseQuantity('   ', allowsDecimal: true),
        isNull,
      );
    });

    test('QTF2: δεκαδικά με "." ή "," → double (REAL) χωρίς float artifacts',
        () {
      expect(
        QuantityTextField.parseQuantity('1,5', allowsDecimal: true),
        1.5,
      );
      expect(
        QuantityTextField.parseQuantity('1.5', allowsDecimal: true),
        1.5,
      );
      expect(
        QuantityTextField.parseQuantity('1', allowsDecimal: true),
        1.0,
      );
      expect(
        QuantityTextField.parseQuantity('1,555', allowsDecimal: true),
        1.555,
      );
      expect(
        QuantityTextField.parseQuantity('0,5', allowsDecimal: true),
        0.5,
      );
    });

    test('QTF3: integer-only mode (allowsDecimal=false) → μόνο ψηφία', () {
      expect(
        QuantityTextField.parseQuantity('12', allowsDecimal: false),
        12.0,
      );
      expect(
        QuantityTextField.parseQuantity('1,5', allowsDecimal: false),
        isNull, // δεν χωράει στο regex μόνο-ψηφίων
      );
      expect(
        QuantityTextField.parseQuantity('abc', allowsDecimal: false),
        isNull,
      );
    });

    test('QTF4: μη-έγκυρο κείμενο → null', () {
      expect(
        QuantityTextField.parseQuantity('1,5555', allowsDecimal: true),
        isNull, // >3 δεκαδικά
      );
      expect(
        QuantityTextField.parseQuantity('-5', allowsDecimal: true),
        isNull,
      );
      expect(
        QuantityTextField.parseQuantity('1..5', allowsDecimal: true),
        isNull,
      );
    });

    test('QTF5: πάνω από maxQuantity → null (όριο εισόδου)', () {
      expect(
        QuantityTextField.parseQuantity('1000000,001', allowsDecimal: true),
        isNull, // > 1000000.0
      );
      expect(
        QuantityTextField.parseQuantity('1000000', allowsDecimal: true),
        1000000.0, // ακριβώς στο όριο → OK
      );
      expect(
        QuantityTextField.parseQuantity('999999,999', allowsDecimal: true),
        999999.999, // κάτω από όριο → OK
      );
    });
  });

  group('QuantityTextField.formatQuantity', () {
    test('QTF6: χωρίς trailing μηδενικά, κόμμα ως διαχωριστής', () {
      expect(QuantityTextField.formatQuantity(2.5), '2,5');
      expect(QuantityTextField.formatQuantity(2.0), '2');
      expect(QuantityTextField.formatQuantity(2.505), '2,505');
      expect(QuantityTextField.formatQuantity(1.0), '1');
      expect(QuantityTextField.formatQuantity(0.5), '0,5');
      expect(QuantityTextField.formatQuantity(10.0), '10');
    });
  });

  group('QuantityTextField (widget)', () {
    testWidgets('QTF7: label, hint και suffix (μονάδα) εμφανίζονται',
        (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_wrap(QuantityTextField(
        controller: controller,
        labelText: 'Ποσότητα (*)',
        hintText: 'π.χ. 1,5',
        suffixText: 'κιλ',
      )));

      expect(find.text('Ποσότητα (*)'), findsOneWidget);
      expect(find.text('π.χ. 1,5'), findsOneWidget);
      expect(find.text('κιλ'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('QTF8: decimal mode — typing καθαρίζεται (3ο δεκαδικό κόβεται)',
        (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_wrap(QuantityTextField(
        controller: controller,
        labelText: 'Ποσότητα (*)',
        allowsDecimal: true,
      )));

      await tester.enterText(find.byType(TextField), '1,5555');
      await tester.pump();

      // Formatter: >3 δεκαδικά περικόπηκαν → «1,555».
      expect(controller.text, '1,555');
      expect(
        QuantityTextField.parseQuantity(controller.text, allowsDecimal: true),
        1.555,
      );
      controller.dispose();
    });

    testWidgets('QTF9: integer-only mode — κόβει τον διαχωριστή',
        (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_wrap(QuantityTextField(
        controller: controller,
        labelText: 'Ποσότητα (*)',
        allowsDecimal: false,
      )));

      await tester.enterText(find.byType(TextField), '12,5');
      await tester.pump();

      // Formatter: integer-only πετάει το κόμμα → «125» (μόνο ψηφία)· το
      // parseQuantity (integer-only) ισχύει μόνο για έγκυρο ψηφιο-κείμενο.
      expect(controller.text, '125');
      expect(
        QuantityTextField.parseQuantity(controller.text, allowsDecimal: false),
        125.0,
      );
      controller.dispose();
    });

    testWidgets('QTF10: onChanged καλείται με το καθαρισμένο κείμενο',
        (tester) async {
      final controller = TextEditingController();
      String? lastChanged;
      await tester.pumpWidget(_wrap(QuantityTextField(
        controller: controller,
        labelText: 'Ποσότητα (*)',
        allowsDecimal: true,
        onChanged: (value) => lastChanged = value,
      )));

      await tester.enterText(find.byType(TextField), '1,5');
      await tester.pump();

      expect(lastChanged, '1,5');
      controller.dispose();
    });
  });
}