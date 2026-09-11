// features/receipt/presentation/screens/receipt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../bloc/receipt_bloc.dart';
import '../bloc/receipt_event.dart';
import '../bloc/receipt_state.dart';
import '../widgets/receipt_item_list.dart';

/// SPoT: Οθόνη λεπτομερειών απόδειξης (Βήμα 7, DESIGN §5.1.7).
///
/// [BlocProvider] του [ReceiptBloc] πρέπει να υπάρχει πάνω. Το screen
/// dispatch [ReceiptDetailLoadRequested] και δείχνει:
/// - Header: "#N", ημερομηνία, payment status chip,
/// - notes (αν υπάρχουν),
/// - γραμμές ([ReceiptItemList]) από state.items,
/// - totals footer: Καθαρό, ΦΠΑ, Σύνολο με ΦΠΑ, Πληρωμένο, Υπόλοιπο.
///
/// States: awaiting/loading → [LoadingIndicator], error → [AppErrorWidget]
/// (retry re-dispatches detail load), null receipt → [LoadingIndicator]
/// (reactive stream συνήθως αργεί ένα tick — see _onDetailLoad layout),
/// loaded → content.
class ReceiptDetailScreen extends StatefulWidget {
  final int receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<ReceiptBloc>()
          .add(ReceiptDetailLoadRequested(id: widget.receiptId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.receiptNumber)),
      body: BlocConsumer<ReceiptBloc, ReceiptsState>(
        listenWhen: (prev, curr) =>
            curr.message != null && curr.message != prev.message,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.message!),
            ));
          context.read<ReceiptBloc>().add(const ReceiptMessageShown());
        },
        builder: (context, state) {
          if (state.status == ReceiptsStatus.initial ||
              state.status == ReceiptsStatus.loading) {
            return const LoadingIndicator();
          }
          if (state.status == ReceiptsStatus.error &&
              state.error != null &&
              state.error != AppStrings.noReceipts) {
            return AppErrorWidget(
              message: state.error!,
              onRetry: () => context
                  .read<ReceiptBloc>()
                  .add(ReceiptDetailLoadRequested(id: widget.receiptId)),
            );
          }
          final receipt = state.selectedReceipt;
          if (receipt == null) {
            return const LoadingIndicator();
          }
          return _DetailBody(receipt: receipt, items: state.items);
        },
      ),
    );
  }
}

/// Περιεχόμενο detail — χωρίς BLoC (δεν αλλάζει ως προς τα visible fields).
class _DetailBody extends StatelessWidget {
  final Receipt receipt;
  final List<ReceiptItem> items;

  const _DetailBody({required this.receipt, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      children: [
        _Header(receipt: receipt),
        if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.lg),
          Text(AppStrings.receiptNotes, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          Text(receipt.notes!, style: AppTextStyles.bodyMedium),
        ],
        const SizedBox(height: AppDimensions.lg),
        Text(
          AppStrings.itemsTitle,
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppDimensions.sm),
        ReceiptItemList(items: items),
        const SizedBox(height: AppDimensions.lg),
        _TotalsFooter(receipt: receipt),
      ],
    );
  }
}

/// Header: "#N" (receiptNumber), ημερομηνία, notes. Χρησιμοποιεί το preview
/// prefix (Απόδειξη #N) ακολουθούμενο από short date.
class _Header extends StatelessWidget {
  final Receipt receipt;

  const _Header({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.receiptPreviewPrefix}${receipt.receiptNumber}',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          DateFormatter.formatShort(receipt.receiptDate),
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Footer ποσών: Καθαρό, ΦΠΑ, Σύνολο με ΦΠΑ, Πληρωμένο, Υπόλοιπο.
class _TotalsFooter extends StatelessWidget {
  final Receipt receipt;

  const _TotalsFooter({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final gross = receipt.totalAmount + receipt.vatTotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            _TotalRow(
              label: AppStrings.total,
              value: CurrencyFormatter.format(receipt.totalAmount),
            ),
            _TotalRow(
              label: AppStrings.totalVat,
              value: CurrencyFormatter.format(receipt.vatTotal),
            ),
            _TotalRow(
              label: AppStrings.totalWithVat,
              value: CurrencyFormatter.format(gross),
              isEmphasized: true,
            ),
            _TotalRow(
              label: AppStrings.paidAmount,
              value: CurrencyFormatter.format(receipt.paidAmount),
            ),
            _TotalRow(
              label: AppStrings.remainingAmount,
              value: CurrencyFormatter.format(receipt.remainingAmount),
            ),
          ],
        ),
      ),
    );
  }
}

/// Μία γραμμή συνόλου — label αριστερά, ποσό δεξιά.
class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasized;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isEmphasized
                ? AppTextStyles.labelLarge
                : AppTextStyles.bodyMedium
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: isEmphasized
                ? AppTextStyles.currency
                : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}