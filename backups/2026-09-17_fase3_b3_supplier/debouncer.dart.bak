/// SPoT: Debouncer — καθυστερεί την εκτέλεση ενός callback μέχρι να
/// σταματήσει μια σειρά γρήγορων ενεργειών (π.χ. πληκτρολόγηση) (§2.0.3).
///
/// Κάθε `run()` ακυρώνει το προηγούμενο pending timer: μόνο η ΤΕΛΕΥΤΑΙΑ
/// ενεργοποίηση μετά από [delay] χωρίς νέα κλήση εκτελεί το callback.
///
/// Χρήση στη Φάση 3 (item_search, supplier search):
///   final debouncer = Debouncer(
///     delay: Duration(milliseconds: AppConstants.searchDebounceMillis),
///   );
///   debouncer.run(() => _performSearch(query));
///
/// Ο κάτοχος ΟΦΕΙΛΕΙ να καλεί `dispose()` στο lifecycle dispose του —
/// διαφορετικά ο pending timer επιβιώνει (leak) και μπορεί να εκτελέσει
/// query πάνω σε κατεστραμμένο widget (§2.2 edge case).
library;

import 'dart:async';

/// Δεν είναι singleton — κάθε πεδίο/query έχει δικό του instance
/// (ξεχωριστό lifecycle, βλ. item_search_controller §2.2).
final class Debouncer {
  Debouncer({required this.delay});

  /// Χρόνος αναμονής, από `AppConstants.searchDebounceMillis`.
  final Duration delay;

  Timer? _timer;
  bool _disposed = false;

  /// Προγραμματίζει [action] μετά από [delay]. Αν υπάρχει pending timer →
  /// ακυρώνεται και ξεκινά από την αρχή (μόνο η τελευταία ενεργοποίηση
  /// εκτελεί το callback). Αν κληθεί μετά [dispose] → no-op.
  void run(void Function() action) {
    _timer?.cancel();
    if (_disposed) return;
    _timer = Timer(delay, action);
  }

  /// Ακυρώνει τυχόν pending timer — το [action] δεν θα εκτελεστεί (§2.0.3).
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Απελευθέρωση πόρων (καλείται από τον κάτοχο). Μετά από αυτή την
  /// κλήση το [run] γίνεται no-op, ώστε να μην «ξυπνήσει» ξανά.
  void dispose() {
    cancel();
    _disposed = true;
  }
}