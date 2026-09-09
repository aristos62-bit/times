import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// SPoT: κοινό pumping για widget tests — ΜΟΝΟ εδώ ορίζεται το test MaterialApp.
/// Όλα τα widget tests το reuse-άρουν (όχι duplicate MaterialApp/Scaffold).
Future<void> pumpApp(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

/// SPoT: pumping με συγκεκριμένο πλάτος οθόνης (για responsive tests).
/// Χρησιμοποιεί surface size (όχι SizedBox — το SizedBox κόβεται στα 800px).
Future<void> pumpAppWithWidth(
  WidgetTester tester,
  Widget child, {
  double width = 400,
  double height = 800,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await pumpApp(tester, child);
  await tester.pump();
}
