/// Unit tests για το SPoT `NameValidator` (domain/validators) — §2.2:214-218.
///
/// Plain `test()` χωρίς widget pump — καθαρή λογική. Καλύπτει validate
/// (empty/whitespace/max length/OK) και isDuplicate (case/tone/ς→σ/μη-dup).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_errors.dart';
import 'package:times/domain/validators/name_validator.dart';

void main() {
  group('NameValidator.validate', () {
    test('κενό → nameRequired', () {
      expect(NameValidator.validate(''), AppErrors.nameRequired);
    });

    test('μόνο whitespace → nameRequired', () {
      expect(NameValidator.validate('   '), AppErrors.nameRequired);
      expect(NameValidator.validate('\t\n '), AppErrors.nameRequired);
    });

    test('valid name → null', () {
      expect(NameValidator.validate('Γάλα'), isNull);
      expect(NameValidator.validate('  Γάλα  '), isNull);
    });

    test('1 χαρακτήρας OK → null (edge case)', () {
      expect(NameValidator.validate('α'), isNull);
    });

    test('ακριβώς maxItemNameLength → null (όριο αποδεκτό)', () {
      final exactly =
          List.filled(AppConstants.maxItemNameLength, 'α').join();
      expect(NameValidator.validate(exactly), isNull);
    });

    test('maxItemNameLength + 1 → nameTooLong', () {
      final tooLong =
          List.filled(AppConstants.maxItemNameLength + 1, 'α').join();
      expect(NameValidator.validate(tooLong), AppErrors.nameTooLong);
    });
  });

  group('NameValidator.isDuplicate', () {
    test('ακριβές ταίριασμα → true', () {
      expect(NameValidator.isDuplicate('Γάλα', ['Γάλα', 'Ψωμί']), isTrue);
    });

    test('case-insensitive (ΓΑΛΑ) → true', () {
      expect(NameValidator.isDuplicate('ΓΑΛΑ', ['γάλα']), isTrue);
    });

    test('tone-insensitive (γαλα vs γάλα) → true', () {
      expect(NameValidator.isDuplicate('γαλα', ['Γάλα']), isTrue);
    });

    test('τελικό ς/σ εξομοίωση → true', () {
      expect(NameValidator.isDuplicate('γας', ['γασ']), isTrue);
    });

    test('μη-ταίριασμα → false', () {
      expect(NameValidator.isDuplicate('Γάλα', ['Ψωμί']), isFalse);
      expect(NameValidator.isDuplicate('Γάλα', []), isFalse);
    });

    test('κενή λίστα existing → false', () {
      expect(NameValidator.isDuplicate('Γάλα', []), isFalse);
    });
  });
}