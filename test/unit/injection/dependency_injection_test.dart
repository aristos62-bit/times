// test/unit/injection/dependency_injection_test.dart
//
// Επαληθεύει το DependencyInjection (service locator):
// - σωστή κατασκευή του object graph (AppDatabase → DAOs → repos → ThemeProvider)
// - singleton identity (ίδιες instances σε επαναλαμβανόμενες get)
// - override database (AppDatabase.test()) που χρησιμοποιείται από ΟΛΑ
// - guards: double configure (no-op), get πριν configure (StateError),
//   reset (clean + db close + re-configure δουλεύει).
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:expense_tracker/features/item/data/repositories/item_repository_impl.dart';
import 'package:expense_tracker/features/item/domain/repositories/item_repository.dart';
import 'package:expense_tracker/injection/dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DependencyInjection', () {
    late AppDatabase db;

    setUp(() async {
      await DependencyInjection.reset();
      db = AppDatabase.test();
    });

    tearDown(() async {
      await DependencyInjection.reset();
    });

    test('πρέπει κάθε test να ξεκινά με όχι-configured', () {
      expect(DependencyInjection.isConfigured, isFalse);
    });

    test('configure(default): εγγράφει και επιλύει το graph', () async {
      await DependencyInjection.configure();

      expect(DependencyInjection.isConfigured, isTrue);
      expect(DependencyInjection.get<AppDatabase>(), isA<AppDatabase>());
      expect(
        DependencyInjection.get<ItemRepository>(),
        isA<ItemRepositoryImpl>(),
      );
      expect(DependencyInjection.get<ThemeProvider>(),
          isA<ThemeProvider>());
    });

    test('configure(test db): override χρησιμοποιείται από το repo', () async {
      await DependencyInjection.configure(database: db);

      final repo = DependencyInjection.get<ItemRepository>();
      final categories = await db.select(db.categories).get();
      expect(categories, isNotEmpty);

      // Ένα item γραμμένο μέσω του repo πρέπει να γίνει ορατό (test db + repo
      // δείχνουν στο ίδιο graph) και να ξαναδιαβάζεται μέσω του container.
      final id = await repo.create(
        ItemsCompanion.insert(
          name: 'Δοκιμή DI',
          categoryId: categories.first.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final fromRepo = await repo.getById(id);
      expect(fromRepo?.name, 'Δοκιμή DI');
    });

    test('singleton identity: ίδια instance σε επαναλαμβανόμενες get', () async {
      await DependencyInjection.configure(database: db);

      final dao1 = DependencyInjection.get<ItemDao>();
      final dao2 = DependencyInjection.get<ItemDao>();
      expect(identical(dao1, dao2), isTrue);

      final repo1 = DependencyInjection.get<ItemRepository>();
      final repo2 = DependencyInjection.get<ItemRepository>();
      expect(identical(repo1, repo2), isTrue);
    });

    test('get πριν το configure → StateError', () {
      expect(
        () => DependencyInjection.get<ItemRepository>(),
        throwsA(isA<StateError>()),
      );
    });

    test('duplicate configure → no-op + isConfigured παραμένει true', () async {
      await DependencyInjection.configure(database: db);
      final first = DependencyInjection.get<ItemRepository>();

      await DependencyInjection.configure(database: db); // 2η κλήση

      expect(DependencyInjection.isConfigured, isTrue);
      expect(
        identical(DependencyInjection.get<ItemRepository>(), first),
        isTrue,
      );
    });

    test('reset: καθαρίζει graph + κλείνει db + επιτρέπει νέο configure',
        () async {
      await DependencyInjection.configure(database: db);
      expect(DependencyInjection.isConfigured, isTrue);

      await DependencyInjection.reset();
      expect(DependencyInjection.isConfigured, isFalse);
      expect(
        () => DependencyInjection.get<ItemRepository>(),
        throwsA(isA<StateError>()),
      );

      // Νέο configure με νέα test db δουλεύει κανονικά.
      final db2 = AppDatabase.test();
      await DependencyInjection.configure(database: db2);
      expect(DependencyInjection.isConfigured, isTrue);
    });

    test('ThemeProvider συνδεδεμένο με το SettingDao της εγγεγραμμένης db',
        () async {
      await DependencyInjection.configure(database: db);

      final provider = DependencyInjection.get<ThemeProvider>();

      // Ο provider πρέπει να διαβάζει/γράφει την TEST db (όχι το global).
      await provider.initialize();
      expect(provider.themeMode, ThemeMode.system);

      await provider.setThemeMode(ThemeMode.dark);
      final settingDao = DependencyInjection.get<SettingDao>();
      expect(await settingDao.getThemeMode(), ThemeMode.dark);
    });

    test('get<T> μη εγγεγραμμένου τύπου → StateError', () async {
      await DependencyInjection.configure(database: db);
      expect(
        () => DependencyInjection.get<int>(),
        throwsA(isA<StateError>()),
      );
    });
  });
}