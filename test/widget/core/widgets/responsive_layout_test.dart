import 'package:expense_tracker/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

const _mobile = Text('m');
const _tablet = Text('t');
const _desktop = Text('d');

Widget _layout() => const ResponsiveLayout(
      mobile: _mobile,
      tablet: _tablet,
      desktop: _desktop,
    );

void main() {
  group('ResponsiveLayout', () {
    testWidgets('400 → mobile', (tester) async {
      await pumpAppWithWidth(tester, _layout(), width: 400);
      expect(find.text('m'), findsOneWidget);
      expect(find.text('d'), findsNothing);
    });

    testWidgets('800 → tablet', (tester) async {
      await pumpAppWithWidth(tester, _layout(), width: 800);
      expect(find.text('t'), findsOneWidget);
    });

    testWidgets('tablet null → πέφτει σε mobile', (tester) async {
      await pumpAppWithWidth(
        tester,
        const ResponsiveLayout(mobile: _mobile, desktop: _desktop),
        width: 800,
      );
      expect(find.text('m'), findsOneWidget);
    });

    testWidgets('1300 → desktop', (tester) async {
      await pumpAppWithWidth(tester, _layout(), width: 1300);
      expect(find.text('d'), findsOneWidget);
    });
  });

  group('Breakpoints', () {
    testWidgets('400 → mobile + 1 στήλη', (tester) async {
      bool? mobile;
      int? cols;
      await pumpAppWithWidth(
        tester,
        Builder(builder: (c) {
          mobile = Breakpoints.isMobile(c);
          cols = Breakpoints.gridColumns(c);
          return const SizedBox();
        }),
        width: 400,
      );
      expect(mobile, isTrue);
      expect(cols, 1);
    });

    testWidgets('800 → tablet + 2 στήλες', (tester) async {
      bool? tablet;
      int? cols;
      await pumpAppWithWidth(
        tester,
        Builder(builder: (c) {
          tablet = Breakpoints.isTablet(c);
          cols = Breakpoints.gridColumns(c);
          return const SizedBox();
        }),
        width: 800,
      );
      expect(tablet, isTrue);
      expect(cols, 2);
    });

    testWidgets('1300 → desktop + 3 στήλες', (tester) async {
      bool? desktop;
      int? cols;
      await pumpAppWithWidth(
        tester,
        Builder(builder: (c) {
          desktop = Breakpoints.isDesktop(c);
          cols = Breakpoints.gridColumns(c);
          return const SizedBox();
        }),
        width: 1300,
      );
      expect(desktop, isTrue);
      expect(cols, 3);
    });

    testWidgets('1700 → 4 στήλες', (tester) async {
      int? cols;
      await pumpAppWithWidth(
        tester,
        Builder(builder: (c) {
          cols = Breakpoints.gridColumns(c);
          return const SizedBox();
        }),
        width: 1700,
      );
      expect(cols, 4);
    });
  });
}
