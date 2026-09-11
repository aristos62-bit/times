// features/receipt/presentation/widgets/receipt_form.dart
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/receipt_input.dart';
import 'receipt_form_lines.dart';

/// SPoT: Φόρμα απόδειξης (Βήμα 7, DESIGN §5.1.7) — controlled από πάνω.
///
/// Πεδία: ημερομηνία (date picker), supplierId (αριθμητικό — το Supplier UI
/// έρχεται στο Phase 5· ο [ReceiptFormLines] το ενημερώνει μέσω [onChanged]),
/// paymentMethod (dropdown από [AppConstants.paymentMethods]), notes +
/// γραμμές ([ReceiptFormLines]). Κάθε αλλαγή προωθεί πλήρες [ReceiptInput]
/// μέσω [onChanged] — κανένα κρατικό state εδώ (BLoC/entry screen κρατούν).
///
/// Edge cases: ημερομηνία χωρίς επιλογή → [AppStrings.receiptDateRequired]
/// εμφανίζεται inline (εμφάνιση μόνο — ο Validators.validateReceipt μπλοκάρει
/// στο submit). Payment method: προεπιλογή η πρώτη του AppConstants.
class ReceiptForm extends StatefulWidget {
  final ReceiptInput initial;
  final ValueChanged<ReceiptInput> onChanged;

  const ReceiptForm({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<ReceiptForm> {
  late final TextEditingController _supplierController;
  late final TextEditingController _notesController;
  late final TextEditingController _dateController;
  late DateTime _date;
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _date = widget.initial.date;
    _supplierController = TextEditingController(
      text: widget.initial.supplierId > 0 ? '${widget.initial.supplierId}' : '',
    );
    _notesController = TextEditingController(text: widget.initial.notes ?? '');
    _dateController = TextEditingController(
      text: DateFormatter.formatShort(widget.initial.date),
    );
    _paymentMethod = _initialPaymentMethod();
    _pendingItems = List.of(widget.initial.items);
    _supplierController.addListener(_notify);
    _notesController.addListener(_notify);
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _initialPaymentMethod() {
    if (AppConstants.paymentMethods.contains(widget.initial.paymentMethod)) {
      return widget.initial.paymentMethod;
    }
    return AppConstants.paymentMethods.first;
  }

  void _notify() {
    widget.onChanged(_buildInput());
  }

  ReceiptInput _buildInput() => ReceiptInput(
        date: _date,
        supplierId: int.tryParse(_supplierController.text) ?? 0,
        paymentMethod: _paymentMethod,
        items: _pendingItems,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

  List<ReceiptItemInput> _pendingItems = const [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      children: [
        TextField(
          controller: _dateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: AppStrings.receiptDate,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          onTap: _pickDate,
        ),
        const SizedBox(height: AppDimensions.md),
        TextField(
          controller: _supplierController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: AppStrings.supplier,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        DropdownButtonFormField<String>(
          initialValue: _paymentMethod,
          decoration: const InputDecoration(
            labelText: AppStrings.paymentMethod,
          ),
          items: [
            for (final method in AppConstants.paymentMethods)
              DropdownMenuItem(value: method, child: Text(method)),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _paymentMethod = value);
            _notify();
          },
        ),
        const SizedBox(height: AppDimensions.md),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: AppStrings.receiptNotes,
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        ReceiptFormLines(
          items: _pendingItems,
          onChanged: (items) {
            _pendingItems = items;
            _notify();
          },
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: AppConstants.minReceiptDate,
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _dateController.text = DateFormatter.formatShort(picked);
    });
    _notify();
  }
}