import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/receipt/presentation/widgets/receipt_item_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/pump_app.dart';

/// SPoT: Builder για δοκιμαστικό [ReceiptItem] (DataClass).
ReceiptItem buildItem({
  int id = 1,
  int itemId = 7,
  double quantity = 2,
  double unitPrice = 10,
  double vatRate = 24,
  double vatAmount = 4.8,
  double discount = 0,
  double totalPrice = 20,
  double totalWithVat = 24.8,
}) {
  return ReceiptItem(
    id: id,
    uuid: 'item-uuid-$id',
    receiptId: 1,
    itemId: itemId,
    quantity: quantity,
    unitPrice: unitPrice,
    vatRate: vatRate,
    vatAmount: vatAmount,
    discount: discount,
    totalPrice: totalPrice,
    totalWithVat: totalWithVat,
    notes: null,
    createdAt: DateTime(2026, 9, 11, 12, 0),
  );
}

void main() {
  group('ReceiptItemList', () {
    testWidgets('κενή λίστα → μήνυμα χωρίς rows', (tester) async {
      await pumpApp(tester, const ReceiptItemList(items: []));
      expect(find.text(AppStrings.noItemsInReceipt), findsOneWidget);
    });

    testWidgets('εμφανίζει item id, gross γραμμής και σύνοψη', (tester) async {
      await pumpApp(
        tester,
        ReceiptItemList(items: [buildItem()]),
      );
      expect(find.text('${AppStrings.item} #7'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(24.8)), findsOneWidget);
      expect(find.textContaining('2 ×'), findsOneWidget);
      expect(find.textContaining(AppStrings.vatRate), findsOneWidget);
    });

    testWidgets('πολλαπλές γραμμές → ένα row ανά item', (tester) async {
      await pumpApp(
        tester,
        ReceiptItemList(items: [
          buildItem(id: 1, itemId: 7),
          buildItem(id: 2, itemId: 8, totalWithVat: 13.0),
        ]),
      );
      expect(find.text('${AppStrings.item} #7'), findsOneWidget);
      expect(find.text('${AppStrings.item} #8'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(13.0)), findsOneWidget);
    });

    testWidgets('δεκαδική ποσότητα → εμφανίζεται με δεκαδικά', (tester) async {
      await pumpApp(
        tester,
        ReceiptItemList(
          items: [buildItem(quantity: 1.5, unitPrice: 3, totalWithVat: 5.58)],
        ),
      );
      expect(find.textContaining('1.5 ×'), findsOneWidget);
    });
  });
}