// core/utils/date_formatter.dart
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
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;
    
    if (difference == 0) return 'Σήμερα';
    if (difference == 1) return 'Χθες';
    if (difference == 2) return 'Προχθές';
    if (difference < 7) return '$difference ημέρες πριν';
    return formatShort(date);
  }
  
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
