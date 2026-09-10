import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TagDao', () {
    late AppDatabase db;
    late TagDao dao;

    setUp(() async {
      db = AppDatabase.test();
      dao = TagDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> createSupplier() async {
      return db.into(db.suppliers).insert(SuppliersCompanion.insert(
            name: 'Tag Test Supplier',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
    }

    Future<int> createReceipt() async {
      final supplierId = await createSupplier();
      final now = DateTime.now();
      return db.into(db.receipts).insert(ReceiptsCompanion.insert(
            receiptNumber: 1,
            receiptDate: now,
            supplierId: supplierId,
            createdAt: now,
            updatedAt: now,
          ));
    }

    test('watchAllTags: αρχικά κενό', () async {
      expect(await dao.watchAllTags().first, isEmpty);
    });

    test('createTag + getTagById', () async {
      final tag = await dao.createTag('Επείγον', color: '#FF0000');
      expect(tag, isNotNull);
      expect(tag!.name, 'Επείγον');
      expect(tag.color, '#FF0000');
      expect(tag.createdAt, isA<DateTime>());
    });

    test('createTag: duplicate name → null (insertOrIgnore)', () async {
      await dao.createTag('Επείγον');
      final duplicate = await dao.createTag('Επείγον');
      expect(duplicate, isNull);
      expect((await dao.watchAllTags().first).length, 1);
    });

    test('searchTagsByName: case-insensitive LIKE', () async {
      await dao.createTag('MIN Market');
      await dao.createTag('Γωνία');

      final results = await dao.searchTagsByName('min').first;
      expect(results.length, 1);
      expect(results.single.name, 'MIN Market');
    });

    test('updateTag: rename', () async {
      final tag = (await dao.createTag('Παλιό'))!;
      final ok = await dao.updateTag(
        tag.toCompanion(true).copyWith(name: const Value('Νέο')),
      );
      expect(ok, isTrue);
      expect((await dao.getTagById(tag.id))?.name, 'Νέο');
    });

    test('watchTagsByReceiptId: JOIN tags → receipt_tags', () async {
      final receiptId = await createReceipt();
      final tagA = (await dao.createTag('Fresh'))!;
      final tagB = (await dao.createTag('Στα ράφια'))!;

      final tags = await dao.watchTagsByReceiptId(receiptId).first;
      expect(tags, isEmpty);

      await dao.addTagToReceipt(receiptId, tagA.id);
      await dao.addTagToReceipt(receiptId, tagB.id);

      final after = await dao.watchTagsByReceiptId(receiptId).first;
      expect(after.map((t) => t.id).toSet(), {tagA.id, tagB.id});
    });

    test('addTagToReceipt: idempotent', () async {
      final receiptId = await createReceipt();
      final tag = (await dao.createTag('Διπλό'))!;

      await dao.addTagToReceipt(receiptId, tag.id);
      await dao.addTagToReceipt(receiptId, tag.id);

      final rows = await db.select(db.receiptTags).get();
      expect(rows.length, 1);
    });

    test('removeTagFromReceipt/removeAllTagsFromReceipt', () async {
      final receiptId = await createReceipt();
      final tagA = (await dao.createTag('Α'))!;
      final tagB = (await dao.createTag('Β'))!;
      await dao.addTagToReceipt(receiptId, tagA.id);
      await dao.addTagToReceipt(receiptId, tagB.id);

      await dao.removeTagFromReceipt(receiptId, tagA.id);
      expect(await dao.watchTagsByReceiptId(receiptId).first, hasLength(1));

      await dao.removeAllTagsFromReceipt(receiptId);
      expect(await dao.watchTagsByReceiptId(receiptId).first, isEmpty);
    });

    test('deleteTag: καθαρίζει και το junction', () async {
      final receiptId = await createReceipt();
      final tag = (await dao.createTag('Προς Διαγραφή'))!;
      await dao.addTagToReceipt(receiptId, tag.id);

      await dao.deleteTag(tag.id);

      expect(await dao.getTagById(tag.id), isNull);
      expect((await db.select(db.receiptTags).get()), isEmpty);
    });
  });
}