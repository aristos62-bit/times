/// Unit tests για το `SupplierRepositoryImpl` (Φάση 2, Βήμα 2) — CRUD,
/// mapping, `searchByNormalizedName` (LIKE, ίδιο μοτίβο με το Item).
///
/// Search contract: input ήδη-normalized, escape `%`/`_`, default limit,
/// ordering normalizedName, κενό query → άμεσα `[]`.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/repositories/supplier_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double — raw σφάλμα στο watchAll για δοκιμή stream mapping.
/// (Η αναζήτηση χρησιμοποιεί το ίδιο `.handleError`.)
class _FailingStreamSupplierDao extends SupplierDao {
  _FailingStreamSupplierDao(super.db);

  @override
  Stream<List<Supplier>> watchAll() =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late dynamic db;
  late SupplierRepositoryImpl repo;
  late ReceiptDao receiptDao;

  setUp(() {
    db = inMemoryDb();
    repo = SupplierRepositoryImpl(SupplierDao(db));
    receiptDao = ReceiptDao(db);
  });

  tearDown(() async => await db.close());

  group('SupplierRepositoryImpl.insert/getById/getByNormalizedName', () {
    test('insert + getById (normalizedName auto §3)', () async {
      final id = await repo.insert(name: 'ΜΆΡΚΟΣ');
      final row = await repo.getById(id);

      expect(row, isNotNull);
      expect(row!.name, 'ΜΆΡΚΟΣ');
      expect(row.normalizedName, GreekTextNormalizer.normalize('ΜΆΡΚΟΣ'));
    });

    test('getByNormalizedName: exact-match (§2.2)', () async {
      final id = await repo.insert(name: 'Μάρκος');
      expect((await repo.getByNormalizedName('μαρκοσ'))!.id, id);
      expect(await repo.getByNormalizedName('μαρκο'), isNull);
    });

    test('getById ανύπαρκτο id → null', () async {
      expect(await repo.getById(999), isNull);
    });

    test('UNIQUE normalizedName: «Μάρκος» vs «μαρκοσ» → DataLoadException',
        () async {
      await repo.insert(name: 'Μάρκος');

      await expectLater(
        repo.insert(name: 'μαρκοσ'),
        throwsA(isA<DataLoadException>()),
      );
    });
  });

  group('SupplierRepositoryImpl.searchByNormalizedName', () {
    Future<void> seedTypical() async {
      await repo.insert(name: 'Μάρκος');
      await repo.insert(name: 'Μαρκοπούλου');
      await repo.insert(name: 'Καφενείο');
    }

    test('partial match από normalized input', () async {
      await seedTypical();
      final results = await repo
          .searchByNormalizedName(GreekTextNormalizer.normalize('ΜΆΡΚΟ'))
          .first;

      expect(
        results.map((s) => s.name).toList(),
        // normalizedName asc (SQLite BINARY): «μαρκοπουλου» < «μαρκοσ».
        ['Μαρκοπούλου', 'Μάρκος'],
      );
    });

    test('καμία αντιστοίχιση → [] (όχι error)', () async {
      await seedTypical();
      expect(await repo.searchByNormalizedName('κανενασ').first, isEmpty);
    });

    test('κενό query → άμεσα []', () async {
      expect(await repo.searchByNormalizedName('').first, isEmpty);
    });

    test('escape `%`: literal % δεν γίνεται wildcard', () async {
      await repo.insert(name: '50% OFF');
      await repo.insert(name: '50x');

      final results = await repo.searchByNormalizedName('50%').first;
      expect(results.map((s) => s.name), ['50% OFF']);
    });

    test('default limit AppConstants.searchResultsLimit (15)', () async {
      for (var i = 1; i <= 20; i++) {
        await repo.insert(name: 'Μ αρ $i');
      }
      expect((await repo.searchByNormalizedName('μ αρ').first).length, 15);
    });

    test('limit ≤ 0 → default (15)', () async {
      for (var i = 1; i <= 20; i++) {
        await repo.insert(name: 'Μ αρ $i');
      }
      expect((await repo.searchByNormalizedName('μ αρ', limit: 0).first).length, 15);
    });

    test('ordering: normalizedName asc', () async {
      await repo.insert(name: 'Μ ωμέγα');
      await repo.insert(name: 'Μ άλφα');
      await repo.insert(name: 'Μ βήτα');

      final results = await repo.searchByNormalizedName('μ ').first;
      expect(
        results.map((s) => s.name).toList(),
        ['Μ άλφα', 'Μ βήτα', 'Μ ωμέγα'],
      );
    });

    test('raw stream σφάλμα → DataLoadException', () async {
      final failing = SupplierRepositoryImpl(_FailingStreamSupplierDao(db));
      await expectLater(
        failing.watchAll(),
        emitsError(isA<DataLoadException>()),
      );
    });
  });

  group('SupplierRepositoryImpl.updateById', () {
    test('αλλάζει name και ξανα-κανονικοποιεί', () async {
      final id = await repo.insert(name: 'Μάρκος');
      expect(await repo.updateById(id, name: 'Μάρκος ΑΕ'), isTrue);

      final row = await repo.getById(id);
      expect(row!.name, 'Μάρκος ΑΕ');
      expect(row.normalizedName, GreekTextNormalizer.normalize('Μάρκος ΑΕ'));
    });

    test('ανύπαρκτο id → false', () async {
      expect(await repo.updateById(999, name: 'Χ'), isFalse);
    });
  });

  group('SupplierRepositoryImpl.deleteById', () {
    test('διαγράφει ελεύθερο προμηθευτή', () async {
      final id = await repo.insert(name: 'Μάρκος');
      expect(await repo.deleteById(id), isTrue);
      expect(await repo.getById(id), isNull);
    });

    test('RESTRICT: με αποδείξεις → DataLoadException', () async {
      final id = await repo.insert(name: 'Μάρκος');
      await receiptDao.insert(date: DateTime(2026, 1, 1), supplierId: id);

      await expectLater(
        repo.deleteById(id),
        throwsA(isA<DataLoadException>()),
      );
      expect(await repo.getById(id), isNotNull);
    });
  });

  group('SupplierRepositoryImpl.watchAll', () {
    test('ordering: normalizedName', () async {
      final id2 = await repo.insert(name: 'Βήτα');
      final id1 = await repo.insert(name: 'Άλφα');
      final id3 = await repo.insert(name: 'Ωμέγα');

      final rows = await repo.watchAll().first;
      expect(rows.map((s) => s.id), [id1, id2, id3]);
    });

    test('raw stream σφάλμα → DataLoadException (δοκιμή mapping)', () async {
      final failing = SupplierRepositoryImpl(_FailingStreamSupplierDao(db));
      await expectLater(
        failing.watchAll(),
        emitsError(isA<DataLoadException>()),
      );
    });
  });
}