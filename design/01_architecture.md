## 1. Αρχιτεκτονική Εφαρμογής

### 1.1 Architecture Pattern: Clean Architecture + BLoC/Cubit

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
│  │ Screens │  │ Widgets │  │  BLoC   │  │ States  │       │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                    │
│  │Entities │  │UseCases │  │Repositories│                  │
│  │ (Models)│  │         │  │ (abstract) │                  │
│  └─────────┘  └─────────┘  └─────────┘                    │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│  │ DAOs    │  │  Drift  │  │Repositories│ │  Mappers│     │
│  │(Drift)  │  │  Tables │  │  (impl)   │  │         │     │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 State Management: flutter_bloc + Drift Streams

**Αιτιολογία:**
- Testable (εύκολο unit testing)
- Predictable state changes
- Separation of UI ↔ Business Logic
- Υποστήριξη complex state flows
- Drift `.watch()` streams δίνουν αυτόματη reactive UI ενημέρωση

### 1.3 Database: Drift (αντί sqflite/floor)

**Γιατί Drift:**
- **Type-safe** queries (compile-time errors αντί runtime)
- **Reactive** streams (αυτόματη ενημέρωση UI)
- **Better testing** (in-memory database)
- **Type-safe migrations**
- **No SQL triggers** - λογική σε Dart transactions (λύση reactivity issues)

### 1.4 Γλώσσα & Strings

**Κανόνας:** Η εφαρμογή είναι **αποκλειστικά στα Ελληνικά**. Όλα τα μηνύματα (validation errors, UI labels, success/error messages, dialogues) είναι στα ελληνικά.

- **Κεντρικό αρχείο strings:** `core/strings/app_strings.dart`
  - **SPoT** — ΜΟΝΟ αυτό το αρχείο περιέχει τα μηνύματα προς τον χρήστη
  - **Κανένα** string δεν εμφανίζεται inline σε screens/widgets/DAOs
  - Κάθε widget/screen κάνει import το `AppStrings` και διαβάζει το αντίστοιχο field
  - Αν χρειαστεί ποτέ μετάφραση σε άλλη γλώσσα, αλλάζει **μόνο** αυτό το αρχείο
  - Include: validation messages, button labels, screen titles, dialog text, error messages, empty state messages, snackbar messages

### 1.5 Debug Config & Logging

**Κανόνας:** Δεν χρησιμοποιούμε `print()` ή `debugPrint()` οπουδήποτε. Όλα τα logs γίνονται μέσω κεντρικού `DebugConfig` + `AppLogger`.

- **`core/debug/debug_config.dart`** — SPO: διαχείριση debug flags
  - `static const bool isDebug = kDebugMode` (αυτόματα true σε debug, false σε release)
  - Ομαδοποιημένα flags: `showDbLogs`, `showBlocLogs`, `showNetworkLogs`, `showPerformanceLogs`
  - Flags ρυθμίζονται **μόνο** εδώ (όχι scattered booleans)

- **`core/debug/app_logger.dart`** — SPO: κεντρικός logger
  - `AppLogger.db(msg)` — database operations (queries, inserts, migrations)
  - `AppLogger.bloc(msg)` — BLoC state changes, events
  - `AppLogger.network(msg)` — HTTP calls (αν υπάρξει)
  - `AppLogger.performance(msg)` — slow queries, rebuilds
  - `AppLogger.info(msg)` — general info
  - `AppLogger.error(msg, [stackTrace])` — errors
  - Κάθε log line έχει **prefix tag** (π.χ. `[DB]`, `[BLOC]`, `[NET]`)
  - Σε release mode τίποτε δεν τυπώνεται (αυτόματο)
---

