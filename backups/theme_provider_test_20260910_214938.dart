import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeProvider (WIP in-memory)', () {
    test('αρχικό system', () {
      expect(ThemeProvider().themeMode, ThemeMode.system);
    });

    test('initialize → system + notify', () async {
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.initialize();
      expect(provider.themeMode, ThemeMode.system);
      expect(notified, isTrue);
    });

    test('setThemeMode αλλάζει + notify + stream', () async {
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      final future = provider.themeStream.first;
      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(notified, isTrue);
      expect(await future, ThemeMode.dark);
    });

    test('dispose δεν πετάει', () async {
      final provider = ThemeProvider();
      await provider.initialize();
      expect(() => provider.dispose(), returnsNormally);
    });

    test('toggleTheme light ↔ dark', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.light);
      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);
    });
  });
}
