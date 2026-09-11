// core/strings/app_strings.dart
/// SPO: Κεντρικός φάκελος μηνυμάτων εφαρμογής (Ελληνικά)
/// ΚΑΝΕΝΑ string δεν εμφανίζεται inline σε screens/widgets.
/// Κάθε widget κάνει import το AppStrings και διαβάζει το αντίστοιχο field.
/// l10n: προαιρετικά, το SPoT παραμένει σωστό και χωρίς αυτό.
class AppStrings {
  AppStrings._(); // coverage:ignore-line
  
  // --- Screen Titles ---
  static const String homeTitle = 'Αρχική';
  static const String receiptsTitle = 'Αποδείξεις';
  static const String addReceiptTitle = 'Νέα Απόδειξη';
  static const String editReceiptTitle = 'Επεξεργασία Απόδειξης';
  static const String categoriesTitle = 'Κατηγορίες';
  static const String suppliersTitle = 'Προμηθευτές';
  static const String itemsTitle = 'Είδη';
  static const String budgetsTitle = 'Προϋπολογισμοί';
  static const String reportsTitle = 'Αναφορές';
  static const String settingsTitle = 'Ρυθμίσεις';
  
  // --- Validation Messages ---
  static const String requiredField = 'Υποχρεωτικό πεδίο';
  static const String invalidNumber = 'Μη έγκυρος αριθμός';
  static const String invalidVatNumber = 'Μη έγκυρος ΑΦΜ';
  static const String invalidIban = 'Μη έγκυρος IBAN';
  static const String invalidEmail = 'Μη έγκυρο email';
  static const String invalidPhone = 'Μη έγκυρο τηλέφωνο';
  static const String invalidDate = 'Μη έγκυρη ημερομηνία';
  static const String invalidTime = 'Μη έγκυρη ώρα';
  static const String priceMustBePositive = 'Η τιμή πρέπει να είναι θετική';
  static const String quantityMustBePositive = 'Η ποσότητα πρέπει να είναι θετική';
  static const String quantityExceedsStock = 'Η ποσότητα υπερβαίνει το απόθεμα';
  static const String categoryRequired = 'Επιλέξτε κατηγορία';
  static const String supplierRequired = 'Επιλέξτε προμηθευτή';
  static const String receiptDateRequired = 'Επιλέξτε ημερομηνία';
  static const String receiptDateInFuture = 'Η ημερομηνία δεν μπορεί να είναι στο μέλλον';
  static const String paymentMethodRequired = 'Επιλέξτε τρόπο πληρωμής';
  static const String itemNameRequired = 'Εισάγετε όνομα είδους';
  static const String nameTooShort = 'Το όνομα πρέπει να έχει τουλάχιστον 2 χαρακτήρες';
  static const String itemNameTooLong = 'Το όνομα δεν μπορεί να υπερβαίνει τους 100 χαρακτήρες';
  static const String categoryNameTooLong = 'Το όνομα δεν μπορεί να υπερβαίνει τους 50 χαρακτήρες';
  static const String quantityRequired = 'Εισάγετε ποσότητα';
  static const String quantityTooLarge = 'Η ποσότητα είναι πολύ μεγάλη';
  static const String priceRequired = 'Εισάγετε τιμή';
  static const String priceNegative = 'Η τιμή δεν μπορεί να είναι αρνητική';
  static const String priceTooLarge = 'Η τιμή είναι πολύ μεγάλη';
  static const String vatRateRequired = 'Επιλέξτε συντελεστή ΦΠΑ';
  static const String invalidVatRate = 'Μη έγκυρος συντελεστής';
  static const String invalidVatRateValue = 'Μη έγκυρος συντελεστής ΦΠΑ';
  static const String categoryNameRequired = 'Εισάγετε όνομα κατηγορίας';
  static const String supplierNameRequired = 'Εισάγετε όνομα προμηθευτή';
  static const String invalidPhoneNumber = 'Μη έγκυρος αριθμός τηλεφώνου';
  static const String budgetAmountRequired = 'Εισάγετε ποσό budget';
  static const String budgetAmountMustBePositive = 'Το ποσό πρέπει να είναι θετικός αριθμός';
  static const String receiptMustHaveItems = 'Η απόδειξη πρέπει να έχει τουλάχιστον ένα είδος';
  static const String receiptItemInvalidQuantity = 'Μη έγκυρη ποσότητα';
  static const String receiptItemNegativePrice = 'Αρνητική τιμή';
  static const String receiptItemPrefix = 'Είδος';
  static const String receiptItemRequired = 'Επιλέξτε είδος';
  static const String receiptItemInvalidVatRate = 'Μη έγκυρος συντελεστής ΦΠΑ γραμμής';
  static const String receiptItemInvalidDiscount = 'Μη έγκυρη έκπτωση';
  
  // --- Button Labels ---
  static const String save = 'Αποθήκευση';
  static const String cancel = 'Ακύρωση';
  static const String delete = 'Διαγραφή';
  static const String edit = 'Επεξεργασία';
  static const String add = 'Προσθήκη';
  static const String confirm = 'Επιβεβαίωση';
  static const String back = 'Πίσω';
  static const String next = 'Επόμενο';
  static const String search = 'Αναζήτηση';
  static const String filter = 'Φίλτρο';
  static const String clear = 'Καθαρισμός';
  static const String retry = 'Επανάληψη';
  
  // --- Dialog Messages ---
  static const String deleteConfirmTitle = 'Διαγραφή;';
  static const String deleteConfirmMessage = 'Είστε σίγουροι ότι θέλετε να διαγράψετε αυτό το στοιχείο; Αυτή η ενέργεια δεν μπορεί να αναιρεθεί.';
  static const String unsavedChangesTitle = 'Μη αποθηκευμένες αλλαγές';
  static const String unsavedChangesMessage = 'Υπάρχουν μη αποθηκευμένες αλλαγές. Θέλετε να τις απορρίψετε;';
  
  // --- Success Messages ---
  static const String savedSuccessfully = 'Αποθηκεύτηκε επιτυχώς';
  static const String deletedSuccessfully = 'Διαγράφηκε επιτυχώς';
  static const String receiptAdded = 'Η απόδειξη καταχωρήθηκε επιτυχώς';
  static const String receiptUpdated = 'Η απόδειξη ενημερώθηκε επιτυχώς';
  static const String receiptDeleted = 'Η απόδειξη διαγράφηκε επιτυχώς';
  
  // --- Error Messages ---
  static const String genericError = 'Κάτι πήγε στραβά. Προσπαθήστε ξανά.';
  static const String databaseError = 'Σφάλμα βάσης δεδομένων';
  static const String notFound = 'Δεν βρέθηκε';
  static const String noReceipts = 'Δεν υπάρχουν αποδείξεις';
  static const String noItems = 'Δεν υπάρχουν είδη';
  static const String noCategories = 'Δεν υπάρχουν κατηγορίες';
  static const String noSuppliers = 'Δεν υπάρχουν προμηθευτές';
  static const String noBudgets = 'Δεν υπάρχουν budgets';
  static const String noDataForReport = 'Δεν υπάρχουν δεδομένα για αυτή την περίοδο';
  
  // --- Settings Labels ---
  static const String darkMode = 'Σκοτεινό θέμα';
  static const String lightMode = 'Φωτεινό θέμα';
  static const String systemDefault = 'Προεπιλογή συστήματος';
  static const String currency = 'Νόμισμα';
  static const String language = 'Γλώσσα';
  
  // --- Date Labels (SPoT — reuse από DateFormatter) ---
  static const String today = 'Σήμερα';
  static const String yesterday = 'Χθες';
  static const String dayBeforeYesterday = 'Προχθές';
  static const String daysAgoSuffix = 'ημέρες πριν';

  // --- Units ---
  static const String piece = 'τεμ';
  static const String kg = 'κιλά';
  static const String gram = 'γραμμάρια';
  static const String liter = 'λίτρα';
  static const String meter = 'μέτρα';
  static const String package = 'συσκευασία';
}
