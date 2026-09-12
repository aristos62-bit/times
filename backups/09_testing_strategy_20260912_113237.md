## 8. Testing Strategy

### 8.1 Unit Tests

| Component | Test File | Coverage |
|---|---|---|
| CurrencyFormatter | `test/unit/core/utils/currency_formatter_test.dart` | 100% |
| DateFormatter | `test/unit/core/utils/date_formatter_test.dart` | 100% |
| Validators | `test/unit/core/utils/validators_test.dart` | 43 tests ✅ 11/09/2026 |
| ReceiptRepository | `test/unit/features/receipt/data/repositories/receipt_repository_impl_test.dart` | 12 tests ✅ 11/09/2026 |
| Receipt UseCases | `test/unit/features/receipt/domain/usecases/` | 90% |
| ReceiptInput models | `test/unit/features/receipt/domain/models/receipt_input_test.dart` | 12 tests ✅ 11/09/2026 |
| ReceiptDao CRUD | `test/unit/core/database/daos/receipt_dao_test.dart` | 33 tests ✅ 11/09/2026 |
| ReceiptDao aggregates | `test/unit/core/database/daos/receipt_dao_aggregates_test.dart` | 4 tests ✅ 11/09/2026 |
| ItemRepository | `test/unit/features/item/data/repositories/item_repository_test.dart` | 90% |
| BudgetService | `test/unit/features/budget/domain/usecases/` | 90% |
| MigrationHelper | `test/unit/core/database/migrations/migration_test.dart` | 95% |
| BackupService | `test/unit/core/database/backup/backup_service_test.dart` | 90% |
| ItemRepositoryImpl | `test/unit/features/item/data/repositories/item_repository_impl_test.dart` | 90% |
| CategoryRepositoryImpl | `test/unit/features/category/data/repositories/category_repository_impl_test.dart` | 90% |
| SupplierRepositoryImpl | `test/unit/features/supplier/data/repositories/supplier_repository_impl_test.dart` | 90% |
| BudgetRepositoryImpl | `test/unit/features/budget/data/repositories/budget_repository_impl_test.dart` | 90% |
| ThemeProvider (SettingDao-backed) | `test/unit/core/theme/theme_provider_test.dart` | 95% |
| DependencyInjection | `test/unit/injection/dependency_injection_test.dart` | 100% |

### 8.2 Widget Tests

| Widget | Test File | Coverage |
|---|---|---|
| ResponsiveLayout | `test/widget/core/widgets/responsive_layout_test.dart` | 100% |
| AutoSuggestField | `test/widget/core/widgets/auto_suggest_field_test.dart` | 90% |
| ReceiptForm | `test/widget/features/receipt/presentation/widgets/receipt_form_test.dart` | 85% |
| ReceiptCard | `test/widget/features/receipt/presentation/widgets/receipt_card_test.dart` | 85% |
| CategoryChart | `test/widget/features/reports/presentation/widgets/category_chart_test.dart` | 80% |
| BudgetProgress | `test/widget/features/budget/presentation/widgets/budget_progress_test.dart` | 80% |

### 8.3 Integration Tests

| Flow | Test File | Steps |
|---|---|---|
| Receipt Entry | `test/integration/receipt_entry_flow_test.dart` | Create → Add Items → Save → Verify |
| Budget Tracking | `test/integration/budget_tracking_flow_test.dart` | Set Budget → Add Receipt → Check Spent |
| Report Generation | `test/integration/report_generation_flow_test.dart` | Select Date → Generate → Export |

### 8.4 Edge Case Tests

```dart
// Test File: test/unit/core/utils/validators_edge_cases_test.dart
void main() {
  group('Validators Edge Cases', () {
    test('validateQuantity should reject zero', () {
      expect(Validators.validateQuantity('0'), isNotNull);
    });
    
    test('validateQuantity should reject negative', () {
      expect(Validators.validateQuantity('-5'), isNotNull);
    });
    
    test('validateQuantity should reject very large numbers', () {
      expect(Validators.validateQuantity('999999'), isNotNull);
    });
    
    test('validatePrice should accept zero', () {
      expect(Validators.validatePrice('0'), isNull);
    });
    
    test('validatePrice should reject negative', () {
      expect(Validators.validatePrice('-10'), isNotNull);
    });
    
    test('validateItemName should handle special characters', () {
      expect(Validators.validateItemName('Test@#$%'), isNull);
    });
    
    test('validateItemName should handle very long strings', () {
      expect(Validators.validateItemName('A' * 101), isNotNull);
    });
  });
}
```
---

