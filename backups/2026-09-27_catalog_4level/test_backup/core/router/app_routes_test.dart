/// Unit tests για το SPoT `AppRoutes` (core/router/app_routes.dart) — §1.1:33.
///
/// Καθαρές σταθερές → plain `test()`. Το GoRouter config είναι ξεχωριστό
/// αρχείο (route definitions, §1.2:42) — εδώ μόνο εγκυρότητα των SPoT.
/// Σύμβαση: paths ξεκινούν με '/', χωρίς trailing slash · names μοναδικά
/// (απαίτηση GoRouter) · '/home' → initial home.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/router/app_routes.dart';

void main() {
  group('AppRoutes', () {
    // ─── Exact name/path pairs ────────────────────────────────────────────────
    test('home — name+path (§2.1 · initial route)', () {
      expect(AppRoutes.homePath, '/');
      expect(AppRoutes.home, 'home');
    });

    test('priceEntry — name+path (§2.2)', () {
      expect(AppRoutes.priceEntryPath, '/price-entry');
      expect(AppRoutes.priceEntry, 'priceEntry');
    });

    test('settings — name+path (§2.3)', () {
      expect(AppRoutes.settingsPath, '/settings');
      expect(AppRoutes.settings, 'settings');
    });

    // ─── Μορφή paths ──────────────────────────────────────────────────────────
    test('κάθε path ξεκινάει με "/" και δεν έχει trailing slash (εκτός root)', () {
      for (final path in _allPaths) {
        expect(path.startsWith('/'), isTrue, reason: path);
        // Μόνη εξαίρεση: η root route '/' (homePath) — δεν έχει «trailing».
        if (path != '/') {
          expect(path.endsWith('/'), isFalse, reason: path);
        }
      }
    });

    // ─── Μοναδικότητα (απαίτηση GoRouter) ────────────────────────────────────
    test('names μοναδικά + paths μοναδικά', () {
      final distinctNames = _allNames.toSet();
      final distinctPaths = _allPaths.toSet();
      expect(distinctNames.length, _allNames.length);
      expect(distinctPaths.length, _allPaths.length);
    });

    test('homePath είναι η initial route ("/")', () {
      expect(AppRoutes.homePath, '/');
    });
  });
}

/// Χειροκίνητα συντηρούμενη λίστα — προστίθεται κάθε νέο route.
const List<String> _allNames = [
  AppRoutes.home,
  AppRoutes.priceEntry,
  AppRoutes.settings,
];

const List<String> _allPaths = [
  AppRoutes.homePath,
  AppRoutes.priceEntryPath,
  AppRoutes.settingsPath,
];