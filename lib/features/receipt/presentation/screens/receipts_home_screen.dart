// features/receipt/presentation/screens/receipts_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/receipt_bloc.dart';
import '../bloc/receipt_event.dart';
import 'receipt_detail_screen.dart';
import 'receipt_entry_screen.dart';
import 'receipt_list_screen.dart';

/// SPoT: Home της εφαρμογής (Phase 3 Fix-B — minimal wiring).
///
/// Ο μόνος τόπος που κάνει `Navigator.push` (τα screens του Receipt feature
/// παραμένουν χωρίς navigation — κανόνας §5.1.7). Κάνει επιπλέον το ΑΡΧΙΚΟ
/// `ReceiptsLoadRequested`: το [ReceiptListScreen] είναι Stateless και δεν
/// πυροδοτεί το πρώτο φόρτωμα μόνο του.
class ReceiptsHomeScreen extends StatefulWidget {
  const ReceiptsHomeScreen({super.key});

  @override
  State<ReceiptsHomeScreen> createState() => _ReceiptsHomeScreenState();
}

class _ReceiptsHomeScreenState extends State<ReceiptsHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReceiptBloc>().add(const ReceiptsLoadRequested());
    });
  }

  void _openEntry() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReceiptEntryScreen()),
    );
  }

  void _openDetail(int receiptId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptDetailScreen(receiptId: receiptId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReceiptListScreen(
      onCreateRequested: _openEntry,
      onReceiptSelected: _openDetail,
    );
  }
}