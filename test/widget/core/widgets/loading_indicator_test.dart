import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/theme/app_dimensions.dart';
import 'package:expense_tracker/core/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('LoadingIndicator', () {
    testWidgets('progress + μήνυμα', (tester) async {
      await pumpApp(tester, const LoadingIndicator(message: 'Φόρτωση'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Φόρτωση'), findsOneWidget);
    });

    testWidgets('default size = buttonHeightSm', (tester) async {
      await pumpApp(tester, const LoadingIndicator());
      final indicator =
          tester.widget<LoadingIndicator>(find.byType(LoadingIndicator));
      expect(indicator.size, AppDimensions.buttonHeightSm);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('scrim AppColors.overlay + iconXl', (tester) async {
      await pumpApp(tester, const LoadingOverlay());
      final container =
          tester.widget<Container>(find.byType(Container).first);
      expect(container.color, AppColors.overlay);
      final indicator =
          tester.widget<LoadingIndicator>(find.byType(LoadingIndicator));
      expect(indicator.size, AppDimensions.iconXl);
    });
  });
}
