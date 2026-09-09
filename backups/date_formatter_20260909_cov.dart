// core/utils/date_formatter.dart
import '../strings/app_strings.dart';
import 'extensions.dart';

/// SPO: Date formatting - single source of truth
class DateFormatter {
  DateFormatter._();
  
  /// Short format: 15/01/2026
  static String formatShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
  
  /// Full Greek format: 15 Ιανουαρίου 2026
  static String formatFull(DateTime date) {
    return '${date.day} ${_greekMonth(date.month)} ${date.year}';
  }
  
  /// Month/Year: Ιανουάριος 2026
  static String formatMonthYear(DateTime date) {
    return '${_greekMonthFull(date.month)} ${date.year}';
  }
  
  /// Time: 14:30
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
  
  /// Relative: "Σήμερα", "Χθες", "2 ημέρες πριν"
  /// Edge: μελλοντική ημερομηνία → formatShort (όχι αρνητικές "ημέρες πριν").
  /// Reuse: startOfDay από DateTimeExtensions (ένα DateTime.now() call).
  static String formatRelative(DateTime date) {
    final today = DateTime.now().startOfDay;
    final dateOnly = date.startOfDay;
    final difference = today.difference(dateOnly).inDays;

    if (difference < 0) return formatShort(date);
    if (difference == 0) return AppStrings.today;
    if (difference == 1) return AppStrings.yesterday;
    if (difference == 2) return AppStrings.dayBeforeYesterday;
    if (difference < 7) return '$difference ${AppStrings.daysAgoSuffix}';
    return formatShort(date);
  }

  // WIP: οι λίστες μηνών θα μεταφερθούν στο AppStrings (ή intl) όταν
  // χρειαστεί l10n — προς το παρόν SPoT εδώ για το formatting.
  
  static String _greekMonth(int month) {
    const months = [
      'Ιανουαρίου', 'Φεβρουαρίου', 'Μαρτίου', 'Απριλίου',
      'Μαΐου', 'Ιουνίου', 'Ιουλίου', 'Αυγούστου',
      'Σεπτεμβρίου', 'Οκτωβρίου', 'Νοεμβρίου', 'Δεκεμβρίου'
    ];
    return months[month - 1];
  }
  
  static String _greekMonthFull(int month) {
    const months = [
      'Ιανουάριος', 'Φεβρουάριος', 'Μάρτιος', 'Απρίλιος',
      'Μάιος', 'Ιούνιος', 'Ιούλιος', 'Αύγουστος',
      'Σεπτέμβριος', 'Οκτώβριος', 'Νοέμβριος', 'Δεκέμβριος'
    ];
    return months[month - 1];
  }
}
