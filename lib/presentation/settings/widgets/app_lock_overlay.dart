/// Fullscreen overlay κλειδωμένης εφαρμογής (§2.3 · 30-09-2026).
///
/// Dumb + busy guard (pattern `_isCreating` §2.4): διπλό tap στο
/// «Ξεκλείδωμα» = ένα native dialog. `PopScope(canPop: false)` (reuse
/// exit-confirm) — το system back δεν παρακάμπτει το κλείδωμα.
/// Responsive §1.4 (Center + min, κανένα fixed ύψος) · χρώματα από
/// `ColorScheme` (§1.5) · icon `semanticLabel` (§1.6).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../data/providers/app_lock_providers.dart';

/// Πύλη overlay: κλειδωμένη → `AppLockOverlay`, αλλιώς κενό.
/// Καταναλώνεται στο `builder` του `MaterialApp.router` (σκεπάζει
/// NavigationBar + dialogs — τίποτα ορατό πριν το unlock).
class AppLockGate extends ConsumerWidget {
  const AppLockGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(appLockProvider).locked;
    if (!locked) return const SizedBox.shrink();
    return const AppLockOverlay();
  }
}

/// Φόντο πίσω από το overlay: όταν κλειδωμένα, το περιεχόμενο βγαίνει από
/// το semantics tree (screen reader — F2 01-10, αλλιώς διαβάζει κρυφά
/// οικονομικά δεδομένα) και από το keyboard traversal/focus (Tab desktop).
/// Τίποτα δεν ξεμοντάρεται — state (drafts) άθικτο.
class AppLockBackground extends ConsumerWidget {
  const AppLockBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(appLockProvider.select((s) => s.locked));
    if (!locked) return child;
    return ExcludeSemantics(
      excluding: true,
      child: FocusScope(
        canRequestFocus: false,
        skipTraversal: true,
        descendantsAreFocusable: false,
        descendantsAreTraversable: false,
        child: child,
      ),
    );
  }
}

/// Οθόνη ξεκλειδώματος — ορατή ΜΟΝΟ όταν `locked`.
class AppLockOverlay extends ConsumerStatefulWidget {
  const AppLockOverlay({super.key});

  @override
  ConsumerState<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<AppLockOverlay> {
  /// Τοπικό busy-flag (pattern `_isCreating` §2.4): όσο τρέχει auth,
  /// το κουμπί είναι ανενεργό — ένα native dialog ανά tap.
  bool _unlocking = false;

  /// Auto-prompt μία φορά ανά κλείδωμα (standard lock-screen UX — το
  /// δακτυλικό δεν καλείται στο build, μόνο post-frame). Το flag
  /// αποτρέπει βρόχο dialogs σε αποτυχία (retry μόνο από το κουμπί).
  bool _autoFired = false;

  /// Η πρώτη προσπάθεια ολοκληρώθηκε και είμαστε ακόμα κλειδωμένοι —
  /// ΜΟΝΟ τότε φαίνεται το κουμπί (retry). Μέχρι τότε η περιοχή μένει
  /// ΑΔΕΙΑ: το OS dialog είναι ημιδιάφανο και ό,τι ζωγραφίζουμε από πίσω
  /// (κουμπί ή spinner) φαίνεται — θέλουμε ΜΟΝΟ το δακτυλικό (fix 30-09).
  /// Σταθερό ύψος (§1.4 — όχι layout jump).
  bool _autoDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoFired) return;
      _autoFired = true;
      _unlock();
    });
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    try {
      final result = await ref
          .read(appLockProvider.notifier)
          .unlock(AppStrings.appLockReason);
      if (!mounted) return;
      // Επιτυχία → το overlay φεύγει μόνο του (καμία snackbar — θόρυβος)·
      // σφάλμα πλατφόρμας → ορατό (fix 30-09)· ακύρωση → σιωπή.
      if (!result.ok && result.error != null) {
        AppFeedback.showError(context, result.error!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _unlocking = false;
          _autoDone = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Material(
        // Πάντα αδιαφανής επιφάνεια (ποτέ τα δεδομένα από πίσω).
        color: theme.colorScheme.surface,
        child: SafeArea(
          // Πριν την 1η ολοκλήρωση: ΤΙΠΟΤΑ ορατό — μόνο το system dialog
          // (fix 30-09). Η οθόνη κλειδώματος (icon + κείμενο + retry)
          // εμφανίζεται ΜΟΝΟ μετά από αποτυχία/ακύρωση.
          child: _autoDone
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outlined,
                          size: AppConstants.appLockIconSize,
                          color: theme.colorScheme.primary,
                          semanticLabel: AppStrings.appLockEnableLabel,
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Text(
                          AppStrings.appLockReason,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.spacingL),
                        // Σταθερό ύψος (§1.4 — όχι layout jump).
                        SizedBox(
                          height: AppConstants.appLockButtonHeight,
                          child: Center(
                            child: _unlocking
                                ? const SizedBox.shrink()
                                : FilledButton.icon(
                                    onPressed: _unlock,
                                    icon: const Icon(
                                      Icons.fingerprint_outlined,
                                    ),
                                    label: const Text(
                                      AppStrings.appLockUnlockAction,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
