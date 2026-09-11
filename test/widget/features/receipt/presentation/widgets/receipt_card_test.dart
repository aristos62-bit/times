import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/receipt/presentation/widgets/receipt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/pump_app.dart';

/// SPoT: Builder για δοκιμαστικό [Receipt] (DataClass) — εύκολη κατασκευή.
Receipt buildReceipt({
  int id = 1,
  int receiptNumber = 42,
  DateTime? date,
  double totalAmount = 100.0,
  double vatTotal = 24.0,
  String paymentStatus = 'paid',
}) {
  final now = DateTime(2026, 9, 11, 12, 0);
  return Receipt(
    id: id,
    uuid: 'uuid-$id',
    receiptNumber: receiptNumber,
    receiptDate: date ?? now,
    supplierId: 1,
    invoiceNumber: null,
    invoiceSeries: null,
    paymentMethod: 'Μετρητά',
    totalAmount: totalAmount,
    vatTotal: vatTotal,
    discountTotal: 0,
    paidAmount: totalAmount + vatTotal,
    remainingAmount: 0,
    paymentStatus: paymentStatus,
    notes: null,
    attachmentPath: null,
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ReceiptCard', () {
    testWidgets('εμφανίζει αριθμό, ημερομηνία, gross σύνολο και status',
        (tester) async {
      await pumpApp(tester, ReceiptCard(receipt: buildReceipt()));
      expect(
        find.text('${AppStrings.receiptPreviewPrefix}42'),
        findsOneWidget,
      );
      expect(
        find.text(DateFormatter.formatShort(DateTime(2026, 9, 11, 12, 0))),
        findsOneWidget,
      );
      expect(find.text(CurrencyFormatter.format(124.0)), findsOneWidget);
      expect(find.text(AppStrings.receiptStatusPaid), findsOneWidget);
    });

    testWidgets('gross = totalAmount + vatTotal (χωρίς προϋπολογισμένο)',
        (tester) async {
      await pumpApp(
        tester,
        ReceiptCard(
          receipt: buildReceipt(totalAmount: 50, vatTotal: 8),
        ),
      );
      expect(find.text(CurrencyFormatter.format(58.0)), findsOneWidget);
    });

    testWidgets('status partial → warning label + χρώμα', (tester) async {
      await pumpApp(
        tester,
        ReceiptCard(receipt: buildReceipt(paymentStatus: 'partial')),
      );
      expect(find.text(AppStrings.receiptStatusPartial), findsOneWidget);
      final color = (tester.widget<Container>(find
              .descendant(
                of: find.byType(ReceiptCard),
                matching: find.byType(Container),
              )
              .first)
          .decoration as BoxDecoration)
          .color;
      expect(color, AppColors.warning.withValues(alpha: 0.12));
    });

    testWidgets('status pending → pending label', (tester) async {
      await pumpApp(
        tester,
        ReceiptCard(receipt: buildReceipt(paymentStatus: 'pending')),
      );
      expect(find.text(AppStrings.receiptStatusPending), findsOneWidget);
    });

    testWidgets('onTap κλήση', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        ReceiptCard(receipt: buildReceipt(), onTap: () => tapped = true),
      );
      await tester.tap(find.byType(ReceiptCard));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}