import 'package:expense_tracker/core/widgets/auto_suggest_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

const _items = ['μήλο', 'αχλάδι', 'μπανάνα'];

Future<List<String>> _search(String q) async =>
    _items.where((s) => s.contains(q)).toList();

Widget _field({
  ValueChanged<String>? onSelected,
  TextEditingController? controller,
  Future<List<String>> Function(String)? searchFn,
}) =>
    AutoSuggestField<String>(
      label: 'Είδος',
      hint: 'Γράψε…',
      searchFn: searchFn ?? _search,
      displayFn: (s) => s,
      itemBuilder: (s) => Text(s),
      onSelected: onSelected ?? (_) {},
      controller: controller,
    );

/// Debounce (300ms) + async searchFn → 400ms + extra pumps.
/// ΠΡΟΣΟΧΗ: το query πρέπει να ταιριάζει ακριβώς (το contains είναι
/// accent-sensitive: 'μήλ' με τόνο ≠ 'μηλ' χωρίς).
Future<void> _settleSearch(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  await tester.pump();
}

Future<void> _focusAndType(WidgetTester tester, String text) async {
  await tester.tap(find.byType(TextFormField));
  await tester.pump();
  await tester.enterText(find.byType(TextFormField), text);
}

void main() {
  group('AutoSuggestField', () {
    testWidgets('εμφανίζει προτάσεις μετά το debounce', (tester) async {
      await pumpApp(tester, _field());
      await _focusAndType(tester, 'μήλ');
      await _settleSearch(tester);
      expect(find.text('μήλο'), findsOneWidget);
      expect(find.text('αχλάδι'), findsNothing);
    });

    testWidgets('tap επιλέγει + onSelected + controller', (tester) async {
      String? selected;
      final controller = TextEditingController();
      await pumpApp(
        tester,
        _field(onSelected: (s) => selected = s, controller: controller),
      );
      await _focusAndType(tester, 'μήλ');
      await _settleSearch(tester);
      await tester.tap(find.text('μήλο'));
      await tester.pump();
      expect(selected, 'μήλο');
      expect(controller.text, 'μήλο');
    });

    testWidgets('κενό query καθαρίζει', (tester) async {
      await pumpApp(tester, _field());
      await _focusAndType(tester, 'μήλ');
      await _settleSearch(tester);
      expect(find.text('μήλο'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '');
      await _settleSearch(tester);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('searchFn που πετάει → κανένα crash', (tester) async {
      await pumpApp(
        tester,
        _field(searchFn: (_) async => throw Exception('db down')),
      );
      await _focusAndType(tester, 'μήλ');
      await _settleSearch(tester);
      expect(find.byType(ListTile), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
