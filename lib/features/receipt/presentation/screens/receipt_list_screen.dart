// features/receipt/presentation/screens/receipt_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../bloc/receipt_bloc.dart';
import '../bloc/receipt_event.dart';
import '../bloc/receipt_state.dart';
import '../widgets/receipt_card.dart';

/// SPoT: Λίστα αποδείξεων (Βήμα 7, DESIGN §5.1.7).
///
/// [BlocProvider] του [ReceiptBloc] πρέπει να υπάρχει πάνω στο δέντρο
/// (wiring: entry screen / router). Το screen δέχεται callbacks για
/// navigation (onCreateRequested, onReceiptSelected) — δεν κάνει ο ίδιος
/// Navigator.push (αποφυγή tight coupling).
///
/// States: initial/loading → [LoadingIndicator], error → [AppErrorWidget]
/// (retry dispatches [ReceiptsLoadRequested]), empty → [EmptyState] (με
/// action button), loaded → [ListView] με [ReceiptCard]. Snackbar
/// μηνύματα προωθούνται μέσω listener + [ReceiptMessageShown] (Βήμα 7
/// bridge pattern fix).
class ReceiptListScreen extends StatelessWidget {
  final VoidCallback onCreateRequested;
  final ValueChanged<int> onReceiptSelected;

  const ReceiptListScreen({
    super.key,
    required this.onCreateRequested,
    required this.onReceiptSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.receiptsTitle),
      ),
      body: BlocConsumer<ReceiptBloc, ReceiptsState>(
        listenWhen: (prev, curr) =>
            curr.message != null && curr.message != prev.message,
        listener: _showMessage,
        builder: (context, state) => _buildBody(context, state),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: AppStrings.addReceiptTitle,
        onPressed: onCreateRequested,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showMessage(BuildContext context, ReceiptsState state) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(state.message!),
          duration: AppConstants.snackBarDuration,
        ),
      );
    context.read<ReceiptBloc>().add(const ReceiptMessageShown());
  }

  Widget _buildBody(BuildContext context, ReceiptsState state) {
    if (state.status == ReceiptsStatus.initial ||
        state.status == ReceiptsStatus.loading) {
      return const LoadingIndicator();
    }
    if (state.status == ReceiptsStatus.error) {
      return AppErrorWidget(
        message: state.error ?? AppStrings.genericError,
        onRetry: () => context
            .read<ReceiptBloc>()
            .add(const ReceiptsLoadRequested()),
      );
    }
    if (state.receipts.isEmpty) {
      return EmptyState(
        message: AppStrings.noReceipts,
        actionLabel: AppStrings.add,
        onAction: onCreateRequested,
      );
    }
    return ListView.builder(
      itemCount: state.receipts.length,
      itemBuilder: (context, index) {
        final receipt = state.receipts[index];
        return ReceiptCard(
          receipt: receipt,
          onTap: () => onReceiptSelected(receipt.id),
        );
      },
    );
  }
}