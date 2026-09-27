/// Unit tests για το `BaseDao` (Φάση 1, Βήμα 2).
///
/// Επαληθεύει τους guards (log + raw rethrow) και την εγγύηση ότι τα DAOs
/// ποτέ δεν πετούν AppException (η σύμβαση: το mapping γίνεται στο Repository,
/// Φάση 2 — app_exceptions.dart). Χρησιμοποιεί ένα μίνι-DAO με σκόπιμα
/// errors, ώστε να μην εξαρτάται από το σχήμα των πινάκων.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/debug/debug_config.dart';
import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/logging/app_logger.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/base_dao.dart';

import '../helpers/in_memory_db.dart';

// Ελάχιστο DAO: εκθέτει guard/guardStream με ελεγχόμενες αποτυχίες.
class _TestDao extends BaseDao {
  _TestDao(super.db);

  Future<int> awaitOk(int value) => guard('Δοκιμή επιτυχίας', () async => value);

  Future<int> awaitFail() => guard(
        'Δοκιμή αποτυχίας',
        () async => throw StateError('boom'),
      );

  Stream<int> streamOk() => guardStream(
        'Δοκιμή stream επιτυχίας',
        () => Stream.fromIterable(const [1, 2, 3]),
      );

  Stream<int> streamFail() => guardStream(
        'Δοκιμή stream αποτυχίας',
        () => Stream<int>.error(StateError('boom')),
      );
}

void main() {
  late AppDatabase db;
  late _TestDao dao;

  setUp(() async {
    db = inMemoryDb();
    dao = _TestDao(db);
  });

  tearDown(() async {
    await db.close();
    AppLogger.resetTestSink();
    DebugConfig.reset();
  });

  group('guard (async op)', () {
    test('επιτυχία: επιστρέφει το αποτέλεσμα χωρίς log error', () async {
      final lines = <String>[];
      AppLogger.testSink = lines.add;

      expect(await dao.awaitOk(42), 42);

      expect(lines, isEmpty);
    });

    test('αποτυχία: log (tag DB) + raw rethrow, ΠΟΤΕ AppException', () async {
      final lines = <String>[];
      AppLogger.testSink = lines.add;

      // Το raw σφάλμα περνάει ανέπαφο (StateError) — όχι app_exceptions.
      await expectLater(
        dao.awaitFail(),
        throwsA(isNot(isA<AppException>())),
      );
      // …και καταγράφεται με tag DB.
      expect(lines, isNotEmpty);
      expect(
        lines.any((l) => l.contains('[DB][ERROR]') && l.contains('Δοκιμή αποτυχίας')),
        isTrue,
      );
    });
  });

  group('guardStream (stream)', () {
    test('επιτυχία: εκπέμπει όλες τις τιμές', () async {
      expect(await dao.streamOk().toList(), [1, 2, 3]);
    });

    test('αποτυχία: log (tag DB) + raw rethrow, ΠΟΤΕ AppException', () async {
      final lines = <String>[];
      AppLogger.testSink = lines.add;

      await expectLater(
        dao.streamFail(),
        emitsError(isNot(isA<AppException>())),
      );

      expect(lines, isNotEmpty);
      expect(
        lines.any((l) =>
            l.contains('[DB][ERROR]') && l.contains('Δοκιμή stream αποτυχίας')),
        isTrue,
      );
    });
  });
}