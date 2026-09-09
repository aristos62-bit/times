/// SPO: Database table and column names
class DatabaseConstants {
  DatabaseConstants._();
  
  // Tables
  static const String categoriesTable = 'categories';
  static const String suppliersTable = 'suppliers';
  static const String itemsTable = 'items';
  static const String receiptsTable = 'receipts';
  static const String receiptItemsTable = 'receipt_items';
  static const String paymentsTable = 'payments';
  static const String priceHistoryTable = 'price_history';
  static const String budgetsTable = 'budgets';
  static const String tagsTable = 'tags';
  static const String receiptTagsTable = 'receipt_tags';
  static const String userSettingsTable = 'user_settings';
  
  // Common Columns
  static const String idColumn = 'id';
  static const String createdAtColumn = 'created_at';
  static const String updatedAtColumn = 'updated_at';
  static const String isActiveColumn = 'is_active';
}
