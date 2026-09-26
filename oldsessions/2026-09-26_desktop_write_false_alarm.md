# False alarm: ισχυρισμός «το export δεν γράφει σε desktop» (26-09-2026)

> Κατάσταση: **Κλειστό — revert από τον χρήστη, επαληθευμένο.**
> Χωρίς backup ανάγκης (το αρχείο επανήλθε byte-identical στο committed).

---

## 1. Ισχυρισμός (μη επιβεβαιωμένος)

Report: το `file_picker` (^12.3.0) σε desktop αγνοεί το `bytes:` του
`saveFile` (δήθεν μόνο mobile) → μήνυμα επιτυχίας με άδειο φάκελο.
Προτάθηκε διπλή εγγραφή (`File.fromUri(uri).writeAsBytes`) + citas
«επίσημη τεκμηρίωση» χωρίς παραπομπή. Εφαρμόστηκε σε άλλο session ΜΟΝΟ
στο `backup_file_picker.dart` (controller/service/tests ανεπηρέαστα —
επαληθεύτηκε: συμβόλαιο `Future<bool>` ίδιο, fakes ίδια, suite πράσινη).

## 2. Έλεγχος με evidence (locked versions, pub cache)

- Windows 1.3.0 / Linux 1.1.0: `await file.writeAsBytes(bytes);
  return Uri.file(...)` — γράφουν μόνα τους.
- macOS 1.2.0: σχόλιο *«the plugin writes the bytes to that path itself»*.
- CHANGELOG 12.3.0: `bytes` required **across all platforms** + file saving
  σε background isolate (federated rewrite — η «επιστροφή path χωρίς
  εγγραφή» είναι προ-12.x συμπεριφορά).
- Συμπέρασμα: η διπλή εγγραφή ήταν αποδεδειγμένα περιττή + οριακό νέο
  failure mode + ψευδές docstring → **revert ορθό**.
- Web conditional-import concern: moot (`dart:io` ήδη σε backup_service +
  drift/native/sqlite3/path_provider — web ήδη αδύνατο).
- Σύμπτωμα μη αναπαραγώγιμο σε locked versions· υποψήφιοι ένοχοι αν όντως
  εμφανίστηκε: unpinned δοκιμή, λάθος φάκελος (ο χρήστης διαλέγει πού
  σώζεται), παλιά έκδοση app.
- Μάθημα: vague «επίσημη τεκμηρίωση» χωρίς version+link ≠ evidence·
  πηγαίος κώδικας locked versions > μνήμη API.

## 3. Docs

DESIGN.md: ΚΑΜΙΑ αλλαγή (η συμπεριφορά δεν άλλαξε ποτέ — τίποτα προς
τεκμηρίωση). Καταγραφή μόνο εδώ.
