// features/receipt/presentation/screens/receipt_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/receipt_input.dart';
import '../bloc/receipt_bloc.dart';
import '../bloc/receipt_event.dart';
import '../bloc/receipt_state.dart';
import '../widgets/receipt_form.dart';

/// SPoT: Οθόνη εισαγωγής απόδειξης (Βήμα 7, DESIGN §5.1.7).
///
/// [BlocProvider] του [ReceiptBloc] πρέπει να υπάρχει πάνω. Το screen:
/// 1) dispatch [ReceiptNextNumberRequested] (preview "Επόμενος αριθμός: #N"
///    στο header),
/// 2) τρέχει [ReceiptForm] — controlled: το input προωθείται στο
///    [onInputChanged] (καμία κρατική λογική εδώ),
/// 3) submit → [ReceiptCreateRequested], Snackbar με message.
///
/// Validation errors: ο BLoC τα θέτει (F8 — πριν καλέσει repository) και το
/// screen τα εμφανίζει ως SnackBar (join newline). Το listenWhen ελέγχει το
/// joined text ώστε να μη ξαναδείχνει το ίδιο σύνολο σε κάθε stream tick.
class ReceiptEntryScreen extends StatefulWidget {
  final ValueChanged<ReceiptInput>? onInputChanged;

  const ReceiptEntryScreen({super.key, this.onInputChanged});

  @override
  State<ReceiptEntryScreen> createState() => _ReceiptEntryScreenState();
}

class _ReceiptEntryScreenState extends State<ReceiptEntryScreen> {
  ReceiptInput _input = ReceiptInput(
    date: DateTime.now(),
    supplierId: 0,
    paymentMethod: AppConstants.paymentMethods.first,
    items: const [],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReceiptBloc>().add(const ReceiptNextNumberRequested());
    });
  }

  void _onInputChanged(ReceiptInput input) {
    _input = input;
    widget.onInputChanged?.call(input);
  }

  void _submit(ReceiptBloc bloc) {
    bloc.add(ReceiptCreateRequested(input: _input));
  }

  String? _errorsJoined(ReceiptsState state) {
    if (state.validationErrors.isEmpty) return null;
    return state.validationErrors.join('|');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addReceiptTitle)),
      body: BlocConsumer<ReceiptBloc, ReceiptsState>(
        listenWhen: (prev, curr) =>
            (curr.message != null && curr.message != prev.message) ||
            (curr.validationErrors.isNotEmpty &&
                _errorsJoined(prev) != _errorsJoined(curr)),
        listener: (context, state) {
          final bloc = context.read<ReceiptBloc>();
          if (state.message != null) {
            _showSnack(context, state.message!);
            bloc.add(const ReceiptMessageShown());
          } else if (state.validationErrors.isNotEmpty) {
            _showSnack(context, state.validationErrors.join('\n'));
            bloc.add(const ReceiptMessageShown());
          }
        },
        builder: (context, state) {
          if (state.isSubmitting) {
            return const LoadingIndicator();
          }
          if (state.status == ReceiptsStatus.error &&
              state.error != null &&
              state.error != AppStrings.noReceipts) {
            return AppErrorWidget(
              message: state.error!,
              onRetry: () => context
                  .read<ReceiptBloc>()
                  .add(const ReceiptNextNumberRequested()),
            );
          }
          return _buildForm(context, state);
        },
      ),
    );
  }

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        duration: AppConstants.snackBarDuration,
      ));
  }

  Widget _buildForm(BuildContext context, ReceiptsState state) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      children: [
        if (state.nextNumber != null) ...[
          Text(
            '${AppStrings.receiptNextNumber}: #${state.nextNumber}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
        ],
        ReceiptForm(initial: _input, onChanged: _onInputChanged),
        const SizedBox(height: AppDimensions.lg),
        FilledButton.icon(
          onPressed: () => _submit(context.read<ReceiptBloc>()),
          icon: const Icon(Icons.save_outlined),
          label: const Text(AppStrings.save),
        ),
      ],
    );
  }
}