# Τιμές

Εφαρμογή καταγραφής και διαχείρισης αγορών, παρόμοια με τις λίστες τιμολόγησης/τιμών.

## Λειτουργίες

- Καταγραφή παραστατικών αγορών (τιμολόγια, αποδείξεις)
- Διαχείριση αποθέματος και τιμών προϊόντων
- Ιστορικό τιμών ανά είδος
- Διαχείριση προμηθευτών
- Budgets ανά κατηγορία
- Αναφορές & στατιστικά εξόδων

## Τεχνολογίες

- Flutter (Clean Architecture + BLoC/Cubit)
- Drift (SQLite, reactive streams)
- Υποστήριξη Desktop / Tablet / Mobile
- Dark / Light mode

## Ανάπτυξη

```bash
flutter pub get
flutter analyze
flutter test
```

Η αυτόματη CI εκτελεί `analyze` και `test` σε κάθε push.