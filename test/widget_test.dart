// test/widget_test.dart
//
// Smoke test του Entry Point (Phase 3 Fix-B): το ExpenseTrackerApp ξεκινάει
// με mocked ReceiptRepository (reactive empty stream) και δείχνει τη λίστα
// αποδείξεων, όχι το παλιό counter template.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/core/strings/app_strings.dart';
import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:expense_tracker/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:expense_tracker/features/receipt/presentation/screens/receipt_list_screen.dart';
import 'package:expense_tracker/core/widgets/empty_state.dart';

class _MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  late AppDatabase db;
  late ThemeProvider themeProvider;
  late _MockReceiptRepository repo;

  setUp(() async {
    db = AppDatabase.test();
    themeProvider = ThemeProvider(settingsDao: SettingDao(db));
    repo = _MockReceiptRepository();
    when(() => repo.watchAll(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          supplierId: any(named: 'supplierId'),
          paymentStatus: any(named: 'paymentStatus'),
        )).thenAnswer((_) => Stream.value(<Receipt>[]));
  });

  tearDown(() async {
    themeProvider.dispose();
    await db.close();
  });

  testWidgets('ExpenseTrackerApp ξεκινά και δείχνει τη λίστα αποδείξεων',
      (WidgetTester tester) async {
    await tester.pumpWidget(ExpenseTrackerApp(
      themeProvider: themeProvider,
      receiptRepository: repo,
    ));
    // Προσπάθεια πρώτων frames: postFrame add → load → reactive empty stream.
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(ExpenseTrackerApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(ReceiptListScreen), findsOneWidget);
    expect(find.text(AppStrings.receiptsTitle), findsOneWidget);
    // Κενή ροή → EmptyState (όχι το παλιό counter).
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);

    // Καθαρισμός δέντρου (κλείνει το BlocProvider/ReceiptBloc).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}