// features/receipt/presentation/widgets/receipt_form_lines.dart
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/receipt_input.dart';

/// SPoT: Editor γραμμών απόδειξης (Βήμα 7, DESIGN §5.1.7).
///
/// Φόρμα για [ReceiptItemInput] γραμμές: itemId, quantity, unitPrice, vatRate
/// (bonus — default [AppConstants.defaultVatRate]), discount. Κάθε αλλαγή/
/// προσθήκη/αφαίρεση προωθεί τη νέα λίστα μέσω [onChanged] (controlled από
/// πάνω — χωρίς εσωτερικό κρατικό state, ο BLoC κρατά τη λίστα).
///
/// Edge cases: μη νούμερο στοιχείο → κρατάμε το τελευταίο έγκυρο (χωρίς crash),
/// κενό itemId → 0 (θα το μπλοκάρει ο Validators.validateReceipt). Labels:
/// ΜΟΝΟ AppStrings (SPoT).
class ReceiptFormLines extends StatefulWidget {
  final List<ReceiptItemInput> items;
  final ValueChanged<List<ReceiptItemInput>> onChanged;

  const ReceiptFormLines({
    super.key,
    required this.items,
    required this.onChanged,
  });

  @override
  State<ReceiptFormLines> createState() => _ReceiptFormLinesState();
}

class _ReceiptFormLinesState extends State<ReceiptFormLines> {
  late final List<_LineEditorState> _lines;

  @override
  void initState() {
    super.initState();
    _lines = List.generate(
      widget.items.length,
      (i) => _LineEditorState(_copyInput(widget.items[i])),
      growable: true,
    );
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  ReceiptItemInput _copyInput(ReceiptItemInput input) => ReceiptItemInput(
        itemId: input.itemId,
        quantity: input.quantity,
        unitPrice: input.unitPrice,
        vatRate: input.vatRate,
        discount: input.discount,
      );

  List<ReceiptItemInput> _collect() =>
      _lines.map((l) => l.toInput()).toList();

  void _notify() => widget.onChanged(_collect());

  void _addLine() {
    setState(() {
      _lines.add(_LineEditorState(const ReceiptItemInput(
        itemId: 1,
        quantity: 1,
        unitPrice: 0,
      )));
    });
    _notify();
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index).dispose();
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _lines.length; i++) ...[
          _buildLineCard(i),
          const SizedBox(height: AppDimensions.sm),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addLine),
          ),
        ),
      ],
    );
  }

  Widget _buildLineCard(int index) {
    final line = _lines[index];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: line.itemId,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: AppStrings.item,
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                IconButton(
                  tooltip: AppStrings.delete,
                  onPressed: () => _removeLine(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: line.quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: AppStrings.quantity,
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: TextField(
                    controller: line.unitPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: AppStrings.unitPrice,
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: line.vatRate,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: AppStrings.vatRate,
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: TextField(
                    controller: line.discount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: AppStrings.discount,
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Εσωτερικό state μιας γραμμής: 5 TextEditingControllers + parse σε input.
class _LineEditorState {
  final TextEditingController itemId;
  final TextEditingController quantity;
  final TextEditingController unitPrice;
  final TextEditingController vatRate;
  final TextEditingController discount;

  _LineEditorState(ReceiptItemInput input)
      : itemId = TextEditingController(text: '${input.itemId}'),
        quantity = TextEditingController(text: _fmt(input.quantity)),
        unitPrice = TextEditingController(text: _fmt(input.unitPrice)),
        vatRate = TextEditingController(text: _fmt(input.vatRate)),
        discount = TextEditingController(text: _fmt(input.discount));

  ReceiptItemInput toInput() => ReceiptItemInput(
        itemId: int.tryParse(itemId.text) ?? 0,
        quantity:
            CurrencyFormatter.tryParse(quantity.text) ?? 0,
        unitPrice: CurrencyFormatter.tryParse(unitPrice.text) ?? 0,
        vatRate: CurrencyFormatter.tryParse(vatRate.text) ?? 0,
        discount: CurrencyFormatter.tryParse(discount.text) ?? 0,
      );

  void dispose() {
    itemId.dispose();
    quantity.dispose();
    unitPrice.dispose();
    vatRate.dispose();
    discount.dispose();
  }

  /// Φιλική εμφάνιση: 24.0 → "24", 1.5 → "1.5" (χωρίς trailing zeros).
  static String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}