import '../../../../core/database/daos/daos.dart';
import '../../domain/repositories/budget_repository.dart';

/// SPO: Budget Repository implementation (pure delegate).
///
/// Route A-Συνεπές: κάθε μέθοδος προωθεί 1:1 στον [BudgetDao] — χωρίς
/// validation, χωρίς mapping, χωρίς StreamControllers. Ο DAO είναι ο μόνος
/// SPoT του data-access layer (Fix #1 _monthBounds: UTC ISO ISO8601 bounds).
/// Οι τύποι [BudgetWithSpent]/[CategorySpending] ορίζονται στο budget_dao.dart
/// και χρησιμοποιούνται αυτούσιοι (reuse — όχι αντίγραφα).
/// Instantiation: constructor injection (DI έρχεται σε επόμενη φάση).
class BudgetRepositoryImpl implements BudgetRepository {
  /// Ο μόνος dependency του repository — ο budget DAO.
  final BudgetDao _dao;

  const BudgetRepositoryImpl(this._dao);

  @override
  Stream<BudgetWithSpent?> watchBudget(int categoryId, int month, int year) =>
      _dao.watchBudget(categoryId, month, year);

  @override
  Stream<List<BudgetWithSpent>> watchBudgetsForMonth(int month, int year) =>
      _dao.watchBudgetsForMonth(month, year);

  @override
  Future<void> upsertBudget({
    required int categoryId,
    required int month,
    required int year,
    required double amount,
    String? notes,
  }) =>
      _dao.upsertBudget(
        categoryId: categoryId,
        month: month,
        year: year,
        amount: amount,
        notes: notes,
      );

  @override
  Stream<List<CategorySpending>> watchDashboardSpending(
          int month, int year) =>
      _dao.watchDashboardSpending(month, year);
}