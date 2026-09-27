/// Unit tests για το SPoT `Debouncer` (core/utils/debouncer.dart) — §2.0.3.
///
/// Χρησιμοποιείται `FakeAsync` για ντετερμινιστικό έλεγχο του χρόνου:
/// ο Timer δεν εξαρτάται από πραγματικό ρολόι, οπότε τα cases είναι
/// σταθερά και δεν είναι flaky.
library;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    const delay = Duration(milliseconds: 250);

    // Case 1: το action εκτελείται ακριβώς μία φορά μετά το delay.
    test('εκτελεί το action μία φορά μετά το delay', () {
      fakeAsync((async) {
        var calls = 0;
        final debouncer = Debouncer(delay: delay);
        debouncer.run(() => calls++);

        async.elapse(delay);

        expect(calls, 1);
        debouncer.dispose();
      });
    });

    // Case 2: δεν εκτελεί πριν παρέλθει το delay.
    test('δεν εκτελεί πριν παρέλθει το delay', () {
      fakeAsync((async) {
        var calls = 0;
        final debouncer = Debouncer(delay: delay);
        debouncer.run(() => calls++);

        async.elapse(delay - const Duration(milliseconds: 1));

        expect(calls, 0);
        debouncer.dispose();
      });
    });

    // Case 3: πολλαπλά run() → μόνο το τελευταίο εκτελείται (restart).
    test('πολλαπλά run() εκτελούν μόνο το τελευταίο', () {
      fakeAsync((async) {
        var lastExecuted = -1;
        final debouncer = Debouncer(delay: delay);

        debouncer.run(() => lastExecuted = 1);
        debouncer.run(() => lastExecuted = 2);
        debouncer.run(() => lastExecuted = 3);

        async.elapse(delay);

        expect(lastExecuted, 3);
        debouncer.dispose();
      });
    });

    // Case 4: cancel() ματαιώνει την εκτέλεση (§2.0.3).
    test('cancel() ματαιώνει το pending action', () {
      fakeAsync((async) {
        var calls = 0;
        final debouncer = Debouncer(delay: delay);
        debouncer.run(() => calls++);
        debouncer.cancel();

        async.elapse(delay);

        expect(calls, 0);
        debouncer.dispose();
      });
    });

    // Case 5: dispose() ματαιώνει· μετά dispose το run() είναι no-op —
    // κανένα callback, κανένα exception, ακόμη και με νέο run().
    test('dispose() σκοτώνει pending και κάνει το run() no-op', () {
      fakeAsync((async) {
        var calls = 0;
        final debouncer = Debouncer(delay: delay);
        debouncer.run(() => calls++);
        debouncer.dispose();

        async.elapse(delay);

        expect(calls, 0);

        // Μετά το dispose το run() δεν «ξυπνά» ξανά τον timer.
        debouncer.run(() => calls++);
        async.elapse(delay);
        expect(calls, 0);
      });
    });

    // Case 6: το instance είναι reusable μετά την εκτέλεση ενός action.
    test('instance reusable μετά την εκτέλεση', () {
      fakeAsync((async) {
        var calls = 0;
        final debouncer = Debouncer(delay: delay);

        debouncer.run(() => calls++);
        async.elapse(delay);
        expect(calls, 1);

        debouncer.run(() => calls++);
        async.elapse(delay);
        expect(calls, 2);

        debouncer.dispose();
      });
    });
  });
}