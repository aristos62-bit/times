import '../../../../core/database/daos/budget_dao.dart';

/// SPO: Budget Repository — abstract contract (Phase 2 Step 4).
///
/// Route A-Συνεπές: καθαρός delegate πάνω στον BudgetDao. Τύποι: τα drift
/// DataClasses (`Budget`/`BudgetsCompanion`) + τα έτοιμα μοντέλα του DAO
/// [BudgetWithSpent] / [CategorySpending] (defined στο budget_dao.dart) ως
/// current SPoT entities — reuse, όχι νέα αντίγραφα.
///
/// Reactive (Stream) για live aggregates, Future για single-shot.
abstract class BudgetRepository {
  /// Watch budget κατηγορίας με live spent για τον μήνα (reactive)
  Stream<BudgetWithSpent?> watchBudget(int categoryId, int month, int year);

  /// Watch όλα τα budgets του μήνα με live spent (reactive)
  Stream<List<BudgetWithSpent>> watchBudgetsForMonth(int month, int year);

  /// Create ή update budget (upsert με βάση το UNIQUE category+month+year).
  /// Το createdAt μένει ως έχει σε conflict, μόνο updatedAt αλλάζει.
  Future<void> upsertBudget({
    required int categoryId,
    required int month,
    required int year,
    required double amount,
    String? notes,
  });

  /// Top κατηγορίες με spending για τον μήνα (για Dashboard) — reactive
  Stream<List<CategorySpending>> watchDashboardSpending(int month, int year);
}