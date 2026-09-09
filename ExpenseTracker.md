📱 ExpenseTracker - Ολοκληρωμένη Τελική Πρόταση

🎯 Τελική Ολοκληρωμένη Πρόταση
📋 Πίνακας Περιεχομένων
Βασικές Αρχές Σχεδίασης

Αναλυτική Δομή Βάσης

Core Functionality

Smart Features

UI/UX Flow

Βήματα Υλοποίησης

Testing Strategy

Deployment Plan

🏗️ Βασικές Αρχές Σχεδίασης
1. Offline-First Architecture
dart
class OfflineFirstManager {
  // Όλες οι λειτουργίες λειτουργούν χωρίς internet
  // Αυτόματος συγχρονισμός όταν υπάρχει σύνδεση
  
  final Queue<SyncOperation> _syncQueue = Queue();
  final StreamController<SyncStatus> _syncStatus = StreamController();
  
  Future<void> performOfflineOperation(Operation op) async {
    // 1. Αποθήκευση τοπικά
    await _saveLocally(op);
    
    // 2. Προσθήκη στην ουρά συγχρονισμού
    _syncQueue.add(op);
    
    // 3. Προσπάθεια άμεσου συγχρονισμού αν υπάρχει σύνδεση
    if (await _hasInternet()) {
      await _syncNow();
    }
  }
}
2. Event-Driven Architecture
dart
// Χρήση Event Bus για αποσύζευξη components
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  
  final Map<Type, List<Function>> _listeners = {};
  
  void emit<T>(T event) {
    if (_listeners.containsKey(T)) {
      for (var listener in _listeners[T]!) {
        listener(event);
      }
    }
  }
  
  void listen<T>(Function(T) callback) {
    if (!_listeners.containsKey(T)) {
      _listeners[T] = [];
    }
    _listeners[T]!.add(callback);
  }
}

// Events
class ReceiptSavedEvent {}
class ItemAddedEvent { final Item item; }
class CategoryCreatedEvent { final Category category; }
class DataSyncCompletedEvent {}
3. Repository Pattern με Caching
dart
abstract class IRepository<T> {
  Future<List<T>> getAll();
  Future<T> getById(int id);
  Future<int> insert(T entity);
  Future<int> update(T entity);
  Future<void> delete(int id);
  Future<void> sync();
}

class ItemRepository implements IRepository<Item> {
  final ItemDao _localDao;
  final ItemApi _remoteApi;
  final CacheManager _cache;
  
  @override
  Future<List<Item>> getAll() async {
    // 1. Έλεγχος cache
    final cached = await _cache.get('items');
    if (cached != null) return cached;
    
    // 2. Από local database
    final local = await _localDao.getAll();
    if (local.isNotEmpty) {
      await _cache.set('items', local);
      return local;
    }
    
    // 3. From remote (if online)
    if (await _hasInternet()) {
      final remote = await _remoteApi.fetchAll();
      await _localDao.insertAll(remote);
      await _cache.set('items', remote);
      return remote;
    }
    
    return [];
  }
}
🗄️ Αναλυτική Δομή Βάσης (Τελική)
sql
-- ============================================
-- 1. ΠΙΝΑΚΑΣ ΚΑΤΗΓΟΡΙΩΝ (με υποκατηγορίες)
-- ============================================
CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    color TEXT,
    parent_id INTEGER,
    level INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT 1,
    created_by TEXT,  -- user_id για multi-user
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE CASCADE,
    UNIQUE(name, parent_id)
);

-- ============================================
-- 2. ΠΙΝΑΚΑΣ ΠΡΟΜΗΘΕΥΤΩΝ
-- ============================================
CREATE TABLE suppliers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    vat_number TEXT UNIQUE,
    tax_office TEXT,
    phone TEXT,
    mobile TEXT,
    email TEXT,
    website TEXT,
    address TEXT,
    city TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'Ελλάδα',
    bank_name TEXT,
    bank_account TEXT,
    iban TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. ΠΙΝΑΚΑΣ ΕΙΔΩΝ (με stock management)
-- ============================================
CREATE TABLE items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category_id INTEGER NOT NULL,
    barcode TEXT UNIQUE,
    sku TEXT,  -- Stock Keeping Unit
    unit TEXT DEFAULT 'τεμ',
    unit_weight DECIMAL(10,3),  -- βάρος ανά μονάδα
    min_stock DECIMAL(10,2) DEFAULT 0,
    max_stock DECIMAL(10,2) DEFAULT 0,
    current_stock DECIMAL(10,2) DEFAULT 0,
    reorder_level DECIMAL(10,2) DEFAULT 0,
    last_price DECIMAL(10,2),
    last_supplier_id INTEGER,
    preferred_supplier_id INTEGER,
    notes TEXT,
    is_taxable BOOLEAN DEFAULT 1,
    default_vat_rate DECIMAL(5,2) DEFAULT 24.0,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    FOREIGN KEY (last_supplier_id) REFERENCES suppliers(id),
    FOREIGN KEY (preferred_supplier_id) REFERENCES suppliers(id),
    UNIQUE(name, category_id)
);

-- ============================================
-- 4. ΠΙΝΑΚΑΣ ΑΠΟΔΕΙΞΕΩΝ (με φορολογικά στοιχεία)
-- ============================================
CREATE TABLE receipts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    receipt_number INTEGER UNIQUE NOT NULL,
    receipt_date DATE NOT NULL,
    supplier_id INTEGER NOT NULL,
    invoice_number TEXT,  -- Αριθμός τιμολογίου
    invoice_series TEXT,
    payment_method TEXT,  -- 'cash', 'card', 'transfer', 'check'
    total_amount DECIMAL(10,2) DEFAULT 0,
    vat_total DECIMAL(10,2) DEFAULT 0,  -- Συνολικός ΦΠΑ
    discount_total DECIMAL(10,2) DEFAULT 0,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    remaining_amount DECIMAL(10,2) DEFAULT 0,
    payment_status TEXT DEFAULT 'pending', -- 'pending', 'partial', 'paid'
    notes TEXT,
    attachment_path TEXT,  -- Φωτογραφία απόδειξης
    is_synced BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);

-- ============================================
-- 5. ΠΙΝΑΚΑΣ ΑΝΑΛΥΤΙΚΩΝ ΑΠΟΔΕΙΞΕΩΝ (με ΦΠΑ)
-- ============================================
CREATE TABLE receipt_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    receipt_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    quantity DECIMAL(10,2) DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    vat_rate DECIMAL(5,2) DEFAULT 24.0,
    vat_amount DECIMAL(10,2) DEFAULT 0,
    discount DECIMAL(10,2) DEFAULT 0,
    total_price DECIMAL(10,2) NOT NULL,
    total_with_vat DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (receipt_id) REFERENCES receipts(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id)
);

-- ============================================
-- 6. ΠΙΝΑΚΑΣ ΠΛΗΡΩΜΩΝ (πολλαπλές πληρωμές)
-- ============================================
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    receipt_id INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method TEXT NOT NULL, -- 'cash', 'card', 'transfer'
    reference TEXT,  -- Αριθμός συναλλαγής
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (receipt_id) REFERENCES receipts(id) ON DELETE CASCADE
);

-- ============================================
-- 7. ΠΙΝΑΚΑΣ ΙΣΤΟΡΙΚΟΥ ΤΙΜΩΝ
-- ============================================
CREATE TABLE price_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    vat_rate DECIMAL(5,2) DEFAULT 24.0,
    receipt_date DATE NOT NULL,
    supplier_id INTEGER NOT NULL,
    quantity DECIMAL(10,2) DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES items(id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);

-- ============================================
-- 8. ΠΙΝΑΚΑΣ BUDGET (Προϋπολογισμός)
-- ============================================
CREATE TABLE budgets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    spent_amount DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    UNIQUE(category_id, month, year)
);

-- ============================================
-- 9. ΠΙΝΑΚΑΣ RECEIPT_TAGS (Ετικέτες)
-- ============================================
CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    color TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE receipt_tags (
    receipt_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (receipt_id, tag_id),
    FOREIGN KEY (receipt_id) REFERENCES receipts(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- ============================================
-- 10. ΠΙΝΑΚΑΣ USER_SETTINGS (Ρυθμίσεις)
-- ============================================
CREATE TABLE user_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT,
    type TEXT DEFAULT 'string', -- 'string', 'int', 'bool', 'json'
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES (Βελτιστοποίηση)
-- ============================================
CREATE INDEX idx_items_name ON items(name);
CREATE INDEX idx_items_category ON items(category_id);
CREATE INDEX idx_items_barcode ON items(barcode);
CREATE INDEX idx_receipts_date ON receipts(receipt_date);
CREATE INDEX idx_receipts_supplier ON receipts(supplier_id);
CREATE INDEX idx_receipts_payment_status ON receipts(payment_status);
CREATE INDEX idx_receipt_items_receipt ON receipt_items(receipt_id);
CREATE INDEX idx_receipt_items_item ON receipt_items(item_id);
CREATE INDEX idx_price_history_item ON price_history(item_id);
CREATE INDEX idx_price_history_date ON price_history(receipt_date);
CREATE INDEX idx_payments_receipt ON payments(receipt_id);
CREATE INDEX idx_budgets_category ON budgets(category_id);
CREATE INDEX idx_budgets_date ON budgets(year, month);

-- ============================================
-- TRIGGERS (Αυτοματοποιήσεις)
-- ============================================

-- 1. Αυτόματος υπολογισμός total_amount
CREATE TRIGGER update_receipt_total 
AFTER INSERT ON receipt_items
BEGIN
    UPDATE receipts 
    SET total_amount = (
        SELECT SUM(total_price) 
        FROM receipt_items 
        WHERE receipt_id = NEW.receipt_id
    ),
    vat_total = (
        SELECT SUM(vat_amount) 
        FROM receipt_items 
        WHERE receipt_id = NEW.receipt_id
    )
    WHERE id = NEW.receipt_id;
END;

-- 2. Αυτόματη ενημέρωση price_history
CREATE TRIGGER update_price_history
AFTER INSERT ON receipt_items
BEGIN
    INSERT OR REPLACE INTO price_history (
        item_id, price, vat_rate, receipt_date, supplier_id, quantity
    )
    SELECT 
        NEW.item_id, 
        NEW.unit_price, 
        NEW.vat_rate,
        r.receipt_date, 
        r.supplier_id,
        NEW.quantity
    FROM receipts r
    WHERE r.id = NEW.receipt_id;
END;

-- 3. Αυτόματη ενημέρωση remaining_amount
CREATE TRIGGER update_remaining_amount
AFTER INSERT ON payments
BEGIN
    UPDATE receipts 
    SET paid_amount = (
        SELECT SUM(amount) 
        FROM payments 
        WHERE receipt_id = NEW.receipt_id
    ),
    remaining_amount = total_amount - (
        SELECT SUM(amount) 
        FROM payments 
        WHERE receipt_id = NEW.receipt_id
    ),
    payment_status = CASE
        WHEN total_amount - (SELECT SUM(amount) FROM payments WHERE receipt_id = NEW.receipt_id) <= 0
        THEN 'paid'
        WHEN (SELECT SUM(amount) FROM payments WHERE receipt_id = NEW.receipt_id) > 0
        THEN 'partial'
        ELSE 'pending'
    END
    WHERE id = NEW.receipt_id;
END;

-- 4. Αυτόματη ενημέρωση current_stock
CREATE TRIGGER update_stock
AFTER INSERT ON receipt_items
BEGIN
    UPDATE items 
    SET current_stock = current_stock + NEW.quantity,
        last_price = NEW.unit_price,
        last_supplier_id = (
            SELECT supplier_id 
            FROM receipts 
            WHERE id = NEW.receipt_id
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.item_id;
END;
⚡ Core Functionality
1. Receipt Entry Flow (Βελτιωμένο)
dart
class ReceiptEntryController {
  // 1. Αρχικοποίηση
  Future<void> initialize() async {
    // Φόρτωση ρυθμίσεων
    await _loadSettings();
    
    // Δημιουργία νέου αριθμού απόδειξης
    receiptNumber = await ReceiptNumberGenerator.generateNextNumber();
    
    // Προεπιλεγμένη ημερομηνία (σήμερα)
    receiptDate = DateTime.now();
  }
  
  // 2. Εισαγωγή είδους με auto-suggest
  Future<void> addItem(String query) async {
    // Debounce αναζήτησης
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () async {
      // Αναζήτηση με fuzzy matching
      final suggestions = await _searchService.searchItems(
        query,
        limit: 10,
        includeInactive: false,
      );
      
      // Εμφάνιση προτάσεων
      _showSuggestions(suggestions);
    });
  }
  
  // 3. Επεξεργασία νέου είδους
  Future<void> handleNewItem(String itemName) async {
    // Έλεγχος αν υπάρχει ήδη
    final exists = await _itemRepository.exists(itemName);
    
    if (exists) {
      // Εμφάνιση υπάρχοντος
      _showExistingItem(itemName);
      return;
    }
    
    // Αυτόματη πρόταση κατηγορίας
    final suggestedCategory = await _smartCategorizer.suggest(itemName);
    
    // Εμφάνιση dialog για νέα κατηγορία
    final result = await _showNewCategoryDialog(
      itemName: itemName,
      suggestedCategory: suggestedCategory,
    );
    
    if (result != null) {
      // Δημιουργία νέου είδους
      final newItem = await _itemRepository.create(
        name: itemName,
        categoryId: result.categoryId,
        unit: result.unit,
        defaultVatRate: result.vatRate,
      );
      
      // Προσθήκη στην τρέχουσα απόδειξη
      _addItemToReceipt(newItem);
    }
  }
  
  // 4. Αποθήκευση απόδειξης
  Future<void> saveReceipt() async {
    // Validation
    if (!_validateReceipt()) {
      _showValidationErrors();
      return;
    }
    
    // Transaction
    await _database.transaction((txn) async {
      // Αποθήκευση απόδειξης
      final receiptId = await _receiptRepository.save(
        receipt: _receipt,
        items: _items,
        payments: _payments,
      );
      
      // Ενημέρωση budget
      await _budgetService.updateSpending(_items, _receipt.receiptDate);
      
      // Ενημέρωση price history
      await _priceHistoryService.update(_items);
      
      // Εκκαθάριση cache
      _cacheManager.invalidate('recent_items');
    });
    
    // Events
    EventBus().emit(ReceiptSavedEvent(_receipt));
    
    // Navigation
    _showSuccessMessage();
    _navigateToReceiptView(_receipt.id);
  }
}
2. Smart Search & Auto-Complete (Προηγμένο)
dart
class SmartSearchService {
  // Fuzzy search με Levenshtein distance
  List<SearchResult> fuzzySearch(String query, List<Item> items) {
    return items
        .map((item) => SearchResult(
              item: item,
              score: _calculateRelevance(query, item),
            ))
        .where((result) => result.score > 0.3)
        .sorted((a, b) => b.score.compareTo(a.score))
        .take(10)
        .toList();
  }
  
  double _calculateRelevance(String query, Item item) {
    double score = 0.0;
    
    // 1. Ακριβής αντιστοίχιση (weight: 1.0)
    if (item.name == query) score += 1.0;
    
    // 2. Prefix match (weight: 0.8)
    if (item.name.startsWith(query)) score += 0.8;
    
    // 3. Contains match (weight: 0.6)
    if (item.name.contains(query)) score += 0.6;
    
    // 4. Levenshtein distance (weight: 0.4)
    final distance = levenshteinDistance(query, item.name);
    final maxLen = max(query.length, item.name.length);
    final similarity = 1 - (distance / maxLen);
    score += similarity * 0.4;
    
    // 5. Συντελεστής συχνότητας χρήσης (weight: 0.3)
    final usageScore = _getUsageScore(item.id);
    score += usageScore * 0.3;
    
    return score;
  }
}
3. Smart Categorization με ML
dart
class SmartCategorizer {
  // Rule-based + ML predictions
  Future<Category> suggestCategory(String itemName) async {
    // 1. Έλεγχος keywords
    final keywordMatch = _checkKeywords(itemName);
    if (keywordMatch != null) return keywordMatch;
    
    // 2. Ιστορικό αγορών
    final historicalMatch = await _checkHistory(itemName);
    if (historicalMatch != null) return historicalMatch;
    
    // 3. Μηχανική μάθηση (αν υπάρχει μοντέλο)
    if (_mlModel != null) {
      final prediction = await _mlModel!.predict(itemName);
      if (prediction.confidence > 0.7) {
        return prediction.category;
      }
    }
    
    // 4. Default κατηγορία
    return await _getDefaultCategory();
  }
  
  // Λεξικό keywords
  final Map<String, String> _keywords = {
    'γάλα': 'Γαλακτοκομικά',
    'ψωμί': 'Αρτοποιία',
    'κρέας': 'Κρέατα',
    'λαχανικά': 'Λαχανικά',
    'φρούτα': 'Φρούτα',
    'απορρυπαντικό': 'Οικιακά',
    'σκόνη': 'Οικιακά',
    'χαρτί': 'Οικιακά',
    'βενζίνη': 'Μεταφορικά',
    'πετρέλαιο': 'Μεταφορικά',
    // ... περισσότερα
  };
}
🎨 UI/UX Flow (Αναλυτικό)
Screen 1: Home Dashboard
text
┌─────────────────────────────────────────────────────┐
│  📊 ExpenseTracker                         ⚙️  🔍 │
├─────────────────────────────────────────────────────┤
│  ┌────────────┬────────────┬────────────┐        │
│  │ 💰 Σύνολο  │ 📝 Αποδείξεις│ 📈 Μ.Ο.   │        │
│  │  1,234.50€ │     45     │  27.43€    │        │
│  └────────────┴────────────┴────────────┘        │
│                                                     │
│  ─── Γρήγορες Ενέργειες ───                       │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐           │
│  │📝 Νέα │ │📊 Ανα-│ │🏷️ Είδη│ │👥 Προ-│           │
│  │Απόδειξη│ │φορές │ │      │ │μηθευτές│           │
│  └──────┘ └──────┘ └──────┘ └──────┘           │
│                                                     │
│  ─── Τελευταίες Αποδείξεις ───                   │
│  ┌─────────────────────────────────────┐        │
│  │ 15/01  Σούπερ Μάρκετ Α.Ε.  45.20€  │        │
│  │        ✅ Πληρωμένη                 │        │
│  ├─────────────────────────────────────┤        │
│  │ 14/01  Φαρμακείο Κωνσταντή  12.80€ │        │
│  │        ⏳ Εκκρεμεί                  │        │
│  └─────────────────────────────────────┘        │
│                                                     │
│  ─── Προϋπολογισμός Μήνα ───                    │
│  ████████████████████░░░░░░░░ 78% (450€/580€)   │
│  Μπλε: Τρόφιμα   Πράσινο: Οικιακά   Κόκκινο:... │
└─────────────────────────────────────────────────────┘
Screen 2: Receipt Entry (Κύρια)
text
┌─────────────────────────────────────────────────────┐
│  ←  Νέα Απόδειξη #1024                   [💾]     │
├─────────────────────────────────────────────────────┤
│  📅 15/01/2026  [Σήμερα] [Χθες] [Επιλογή]       │
│                                                     │
│  🏪 Προμηθευτής: [________________________] ▼    │
│  ├── Σούπερ Μάρκετ Α.Ε.                          │
│  ├── Φαρμακείο Κωνσταντή                         │
│  └── Πρατήριο Βενζίνης                           │
│                                                     │
│  💳 Τρόπος Πληρωμής: [Μετρητά ▼]                  │
│                                                     │
│  ─── Αναλυτικά Ειδών ───                         │
│                                                     │
│  🔍 Είδος: [γα______________]                     │
│  ├── 🏷️ Γάλα (Γαλακτοκομικά)  1.50€            │
│  ├── 🏷️ Γάλα σόγιας (Γαλακτοκομικά)  2.80€    │
│  └── 🏷️ Γαλοπούλα (Κρέατα)  8.90€             │
│                                                     │
│  Ποσότητα: [2]  Μονάδα: [τεμ ▼]                   │
│  Τιμή: [1.50€]  ΦΠΑ: [13% ▼]  Έκπτωση: [0%]    │
│                                                     │
│  [+ Προσθήκη είδους]                              │
│                                                     │
│  ─── Λίστα Ειδών ───                            │
│  1. Γάλα (13%)       1.50€ × 2 = 3.00€        │
│  2. Ψωμί (6%)        1.20€ × 3 = 3.60€        │
│  3. Βενζίνη (24%)    1.80€ × 1 = 1.80€        │
│                                                     │
│  ────────────────────────────────────────         │
│  Υποσύνολο:    7.56€                            │
│  ΦΠΑ:          1.34€                            │
│  Έκπτωση:      0.00€                            │
│  ────────────────────────────────────────         │
│  ΣΥΝΟΛΟ:       8.90€                            │
│                                                     │
│  💰 Πληρωμή: [8.90€] [Εξόφληση] [Μερική]        │
│                                                     │
│  📎 Σημειώσεις: [________________]               │
│  📷 [Προσθήκη φωτογραφίας]                       │
│                                                     │
│  [  Ακύρωση  ]  [  Αποθήκευση  ]                  │
└─────────────────────────────────────────────────────┘
Screen 3: Reports & Analytics
text
┌─────────────────────────────────────────────────────┐
│  ←  Αναφορές                         📤  🔽     │
├─────────────────────────────────────────────────────┤
│  📅 01/01/2026 - 31/01/2026  [🔄]                 │
│                                                     │
│  ─── Συνοπτικά Στατιστικά ───                    │
│  📊 Σύνολο: 1,234.50€  📈 Αύξηση: +12.3%        │
│  🏷️ Κατηγορίες: 12  🏪 Προμηθευτές: 8          │
│                                                     │
│  ─── Δαπάνες ανά Κατηγορία ───                   │
│  ┌─────────────────────────────────────┐        │
│  │  🟦 Τρόφιμα         450.00€ (36%) │        │
│  │  🟩 Οικιακά          280.00€ (23%) │        │
│  │  🟧 Μεταφορικά       200.00€ (16%) │        │
│  │  🟪 Υγεία            180.00€ (15%) │        │
│  │  🟨 Λοιπά            124.50€ (10%) │        │
│  └─────────────────────────────────────┘        │
│                                                     │
│  ─── Διακύμανση Τιμών ───                       │
│  Είδος: [Γάλα 1L ________________] 🔍           │
│  📈 Γράφημα τιμής ανά ημερομηνία                 │
│  2.00€ ─┬─                                     │
│  1.80€ ─┤ ─┬─                                  │
│  1.60€ ─┤  └─┬─                                │
│  1.40€ ─┤     └────────────────               │
│         └─────────────────────────────────      │
│         01/01  15/01  30/01                    │
│                                                     │
│  🏷️ Ετικέτες: [Ψώνια] [Σούπερ] [Οικογένεια]     │
│                                                     │
│  [📊 Εξαγωγή PDF]  [📈 CSV]  [📧 Email]         │
└─────────────────────────────────────────────────────┘
📝 Βήματα Υλοποίησης
Φάση 0: Setup & Infrastructure (1-2 εβδομάδες)
bash
# 1. Δημιουργία project
flutter create --org com.yourcompany expense_tracker
cd expense_tracker

# 2. Προσθήκη dependencies (pubspec.yaml)
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.5
  flutter_riverpod: ^2.4.0
  
  # Database
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  floor: ^1.4.2
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive_flutter: ^1.1.0
  
  # Navigation
  go_router: ^12.0.0
  
  # UI Components
  flutter_svg: ^2.0.9
  google_fonts: ^6.1.0
  
  # Forms & Validation
  flutter_form_builder: ^9.1.0
  form_builder_validators: ^9.0.0
  
  # Charts
  fl_chart: ^0.65.0
  
  # Export
  pdf: ^3.10.4
  printing: ^5.11.1
  csv: ^5.1.0
  
  # Camera & Image
  image_picker: ^1.0.4
  flutter_image_compress: ^2.0.0
  
  # Barcode
  barcode_scan2: ^4.2.5
  
  # Security
  local_auth: ^2.1.7
  
  # Analytics
  firebase_core: ^2.24.2
  firebase_analytics: ^10.7.4
  
  # Utils
  intl: ^0.18.1
  uuid: ^4.2.1
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.6
  floor_generator: ^1.4.2
  flutter_native_splash: ^2.3.8
  flutter_launcher_icons: ^0.13.1

# 3. Δημιουργία splash screen
flutter pub run flutter_native_splash:create

# 4. Δημιουργία app icon
flutter pub run flutter_launcher_icons:main
Φάση 1: Database Layer (1-2 εβδομάδες)
dart
// 1. DatabaseHelper
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'expense_tracker.db');
    
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Εκτέλεση όλων των CREATE TABLE statements
    await db.execute(categoriesTable);
    await db.execute(suppliersTable);
    await db.execute(itemsTable);
    // ... κλπ
    
    // Εισαγωγή default δεδομένων
    await _insertDefaultData(db);
  }
}

// 2. DAO Classes
@dao
abstract class ItemDao {
  @Query('SELECT * FROM items WHERE is_active = 1 ORDER BY name')
  Future<List<Item>> getAllActive();
  
  @Query('SELECT * FROM items WHERE name LIKE :query AND is_active = 1')
  Future<List<Item>> searchItems(String query);
  
  @Query('''
    SELECT i.*, c.name as category_name 
    FROM items i
    JOIN categories c ON i.category_id = c.id
    WHERE i.name LIKE :query
    ORDER BY i.name
    LIMIT :limit
  ''')
  Future<List<ItemWithCategory>> searchWithCategory(String query, int limit);
  
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertItem(Item item);
}

// 3. Models
@entity
class Item {
  @primaryKey
  int? id;
  
  @columnInfo(name: 'name')
  String name;
  
  @columnInfo(name: 'category_id')
  int categoryId;
  
  @columnInfo(name: 'barcode')
  String? barcode;
  
  @columnInfo(name: 'unit')
  String unit;
  
  @columnInfo(name: 'current_stock')
  double currentStock;
  
  @columnInfo(name: 'last_price')
  double? lastPrice;
  
  @columnInfo(name: 'is_active')
  bool isActive;
  
  Item({
    this.id,
    required this.name,
    required this.categoryId,
    this.barcode,
    this.unit = 'τεμ',
    this.currentStock = 0,
    this.lastPrice,
    this.isActive = true,
  });
}
Φάση 2: Core Business Logic (2-3 εβδομάδες)
dart
// 1. Receipt Service
class ReceiptService {
  final ReceiptDao _receiptDao;
  final ReceiptItemDao _receiptItemDao;
  final PaymentDao _paymentDao;
  final ItemDao _itemDao;
  final BudgetService _budgetService;
  
  Future<Receipt> createReceipt({
    required DateTime date,
    required int supplierId,
    required String paymentMethod,
    List<ReceiptItemInput> items = const [],
    List<PaymentInput> payments = const [],
    String? notes,
  }) async {
    // Validation
    if (items.isEmpty) {
      throw ValidationException('Η απόδειξη πρέπει να έχει τουλάχιστον ένα είδος');
    }
    
    // Δημιουργία receipt number
    final receiptNumber = await _generateReceiptNumber();
    
    final receipt = Receipt(
      receiptNumber: receiptNumber,
      receiptDate: date,
      supplierId: supplierId,
      paymentMethod: paymentMethod,
      notes: notes,
      totalAmount: 0, // θα υπολογιστεί από trigger
    );
    
    // Αποθήκευση με transaction
    final id = await _database.transaction((txn) async {
      final receiptId = await _receiptDao.insertReceipt(receipt);
      
      // Προσθήκη items
      for (var itemInput in items) {
        await _receiptItemDao.insertItem(
          receiptId: receiptId,
          itemId: itemInput.itemId,
          quantity: itemInput.quantity,
          unitPrice: itemInput.unitPrice,
          vatRate: itemInput.vatRate,
        );
      }
      
      // Προσθήκη payments
      for (var payment in payments) {
        await _paymentDao.insertPayment(
          receiptId: receiptId,
          amount: payment.amount,
          paymentDate: payment.date,
          paymentMethod: payment.method,
        );
      }
      
      // Ενημέρωση budget
      await _budgetService.updateSpending(items, date);
      
      return receiptId;
    });
    
    // Fetch complete receipt
    return await _getReceipt(id);
  }
}

// 2. Budget Service
class BudgetService {
  Future<void> updateSpending(List<ReceiptItemInput> items, DateTime date) async {
    final month = date.month;
    final year = date.year;
    
    // Ομαδοποίηση ανά κατηγορία
    final categoryTotals = <int, double>{};
    for (var item in items) {
      final categoryId = await _getCategoryForItem(item.itemId);
      categoryTotals[categoryId] = 
          (categoryTotals[categoryId] ?? 0) + item.totalPrice;
    }
    
    // Ενημέρωση budget
    for (var entry in categoryTotals.entries) {
      await _database.update(
        'budgets',
        {
          'spent_amount': db.raw('spent_amount + ${entry.value}'),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'category_id = ? AND month = ? AND year = ?',
        whereArgs: [entry.key, month, year],
      );
    }
  }
}

// 3. Export Service
class ExportService {
  Future<void> exportToPDF(ReportData data) async {
    final pdf = Document();
    
    pdf.addPage(
      Page(
        build: (context) {
          return Column(
            children: [
              Header(text: 'Αναφορά Αποδείξεων'),
              SizedBox(height: 20),
              Text('Περίοδος: ${data.startDate} - ${data.endDate}'),
              SizedBox(height: 20),
              _buildSummaryTable(data.summary),
              SizedBox(height: 20),
              _buildCategoryChart(data.categories),
              SizedBox(height: 20),
              _buildItemsTable(data.items),
            ],
          );
        },
      ),
    );
    
    // Αποθήκευση
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_report.pdf');
    await file.writeAsBytes(await pdf.save());
    
    // Εμφάνιση share dialog
    await Share.shareFiles([file.path]);
  }
}
Φάση 3: UI/UX Implementation (3-4 εβδομάδες)
dart
// 1. Main App
class ExpenseTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'ExpenseTracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// 2. AutoSuggest Field (Custom Widget)
class AutoSuggestField<T> extends StatefulWidget {
  final String label;
  final String hint;
  final Future<List<T>> Function(String) searchFn;
  final String Function(T) displayFn;
  final Widget Function(T) itemBuilder;
  final ValueChanged<T> onSelected;
  final String? Function(T?) validator;
  
  const AutoSuggestField({
    required this.label,
    required this.hint,
    required this.searchFn,
    required this.displayFn,
    required this.itemBuilder,
    required this.onSelected,
    this.validator,
  });
  
  @override
  _AutoSuggestFieldState createState() => _AutoSuggestFieldState();
}

class _AutoSuggestFieldState extends State<AutoSuggestField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            suffixIcon: _isLoading
                ? CircularProgressIndicator()
                : Icon(Icons.search),
          ),
        ),
        if (_suggestions.isNotEmpty && _focusNode.hasFocus)
          _buildSuggestionsList(),
      ],
    );
  }
  
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () async {
      if (value.isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      
      setState(() => _isLoading = true);
      final results = await widget.searchFn(value);
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    });
  }
  
  Widget _buildSuggestionsList() {
    return Card(
      elevation: 4,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          return ListTile(
            title: widget.itemBuilder(item),
            onTap: () {
              widget.onSelected(item);
              _controller.text = widget.displayFn(item);
              setState(() => _suggestions = []);
              _focusNode.unfocus();
            },
          );
        },
      ),
    );
  }
}

// 3. Theme with System Detection
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  // Auto-detect system theme
  void initialize() {
    WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
      _updateThemeFromSystem();
    };
    _updateThemeFromSystem();
  }
  
  void _updateThemeFromSystem() {
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }
}
Φάση 4: Reports & Analytics (2-3 εβδομάδες)
dart
// 1. Report Service
class ReportService {
  Future<ReportData> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    int? categoryId,
    int? supplierId,
    int? itemId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    
    // 1. Συνολικό ποσό
    final totalResult = await db.rawQuery('''
      SELECT SUM(total_amount) as total
      FROM receipts
      WHERE receipt_date BETWEEN ? AND ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    final totalAmount = totalResult.first['total'] as double? ?? 0;
    
    // 2. Ανά κατηγορία
    final categoryResults = await db.rawQuery('''
      SELECT 
        c.id,
        c.name,
        c.color,
        SUM(ri.total_price) as amount
      FROM receipt_items ri
      JOIN items i ON ri.item_id = i.id
      JOIN categories c ON i.category_id = c.id
      JOIN receipts r ON ri.receipt_id = r.id
      WHERE r.receipt_date BETWEEN ? AND ?
      ${categoryId != null ? 'AND c.id = ?' : ''}
      GROUP BY c.id
      ORDER BY amount DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    // 3. Ιστορικό τιμών ανά είδος
    final priceHistory = await db.rawQuery('''
      SELECT 
        i.name,
        ph.price,
        ph.receipt_date,
        s.name as supplier_name
      FROM price_history ph
      JOIN items i ON ph.item_id = i.id
      JOIN suppliers s ON ph.supplier_id = s.id
      WHERE ph.item_id = ?
        AND ph.receipt_date BETWEEN ? AND ?
      ORDER BY ph.receipt_date ASC
    ''', [itemId, startDate.toIso8601String(), endDate.toIso8601String()]);
    
    return ReportData(
      totalAmount: totalAmount,
      categories: categoryResults.map((row) => CategoryReport(
        id: row['id'] as int,
        name: row['name'] as String,
        color: row['color'] as String?,
        amount: row['amount'] as double,
        percentage: (row['amount'] as double) / totalAmount * 100,
      )).toList(),
      priceHistory: priceHistory.map((row) => PriceHistoryEntry(
        itemName: row['name'] as String,
        price: row['price'] as double,
        date: DateTime.parse(row['receipt_date'] as String),
        supplierName: row['supplier_name'] as String,
      )).toList(),
    );
  }
}

// 2. Chart Widget
class CategoryChart extends StatelessWidget {
  final List<CategoryReport> data;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: data.map((category) {
            final color = category.color != null 
                ? Color(int.parse(category.color!.replaceFirst('#', '0xFF')))
                : Colors.primaries[data.indexOf(category) % Colors.primaries.length];
            
            return PieChartSectionData(
              value: category.amount,
              title: '${category.percentage.toStringAsFixed(1)}%',
              color: color,
              radius: 100,
              titleStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}
Φάση 5: Testing & Optimization (2-3 εβδομάδες)
dart
// 1. Unit Tests
class ReceiptServiceTest {
  test('Create receipt should calculate total correctly', () async {
    // Setup
    final service = ReceiptService();
    final items = [
      ReceiptItemInput(itemId: 1, quantity: 2, unitPrice: 10.0, vatRate: 24),
      ReceiptItemInput(itemId: 2, quantity: 1, unitPrice: 15.0, vatRate: 13),
    ];
    
    // Act
    final receipt = await service.createReceipt(
      date: DateTime.now(),
      supplierId: 1,
      paymentMethod: 'cash',
      items: items,
    );
    
    // Assert
    expect(receipt.totalAmount, equals(35.0));
    expect(receipt.items.length, equals(2));
  });
}

// 2. Widget Tests
void main() {
  testWidgets('AutoSuggestField should show suggestions', (tester) async {
    // Mock service
    final mockSearch = (String query) async {
      return [Item(id: 1, name: 'Γάλα', categoryId: 1)];
    };
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutoSuggestField(
            label: 'Είδος',
            hint: 'Αναζήτηση...',
            searchFn: mockSearch,
            displayFn: (item) => item.name,
            itemBuilder: (item) => Text(item.name),
            onSelected: (item) {},
          ),
        ),
      ),
    );
    
    // Enter text
    await tester.enterText(find.byType(TextField), 'γα');
    await tester.pump(Duration(milliseconds: 350));
    
    // Check suggestions
    expect(find.text('Γάλα'), findsOneWidget);
  });
}

// 3. Integration Tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete user flow', (tester) async {
    // 1. Launch app
    await tester.pumpWidget(ExpenseTrackerApp());
    
    // 2. Navigate to new receipt
    await tester.tap(find.text('Νέα Απόδειξη'));
    await tester.pumpAndSettle();
    
    // 3. Add supplier
    await tester.enterText(find.byKey(Key('supplier_field')), 'Σούπερ');
    await tester.tap(find.text('Σούπερ Μάρκετ Α.Ε.'));
    await tester.pump();
    
    // 4. Add item
    await tester.enterText(find.byKey(Key('item_field')), 'Γάλα');
    await tester.tap(find.text('Γάλα'));
    await tester.pump();
    
    // 5. Enter price
    await tester.enterText(find.byKey(Key('price_field')), '1.50');
    
    // 6. Save
    await tester.tap(find.text('Αποθήκευση'));
    await tester.pumpAndSettle();
    
    // 7. Verify
    expect(find.text('Η απόδειξη αποθηκεύτηκε'), findsOneWidget);
  });
}

// 4. Performance Tests
void main() {
  test('Database should handle 1000 items', () async {
    final startTime = DateTime.now();
    
    // Insert 1000 items
    for (var i = 0; i < 1000; i++) {
      await ItemDao().insertItem(
        Item(
          name: 'Item $i',
          categoryId: 1,
          unit: 'τεμ',
        ),
      );
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    expect(duration.inMilliseconds, lessThan(5000));
  });
}
Φάση 6: Deployment & CI/CD (1-2 εβδομάδες)
yaml
# .github/workflows/build.yml
name: Build & Deploy

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - name: Install dependencies
        run: flutter pub get
      - name: Run tests
        run: flutter test --coverage
      - name: Build APK
        run: |
          flutter build apk --release --split-per-abi
          flutter build appbundle --release
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: android-release
          path: build/app/outputs/apk/release/
      - name: Upload App Bundle
        uses: actions/upload-artifact@v3
        with:
          name: android-appbundle
          path: build/app/outputs/bundle/release/app-release.aab
      - name: Deploy to Play Store
        if: github.ref == 'refs/heads/main'
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJson: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.yourcompany.expense_tracker
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production

  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - name: Build Web
        run: flutter build web --release --web-renderer canvaskit
      - name: Deploy to GitHub Pages
        if: github.ref == 'refs/heads/main'
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
          force_orphan: true

  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - name: Build Windows
        run: flutter build windows --release
      - name: Upload Windows
        uses: actions/upload-artifact@v3
        with:
          name: windows-release
          path: build/windows/runner/Release/
📊 Monitoring & Analytics
dart
// 1. Performance Monitoring
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  static void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }
  
  static void stopTimer(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      
      // Log performance
      AnalyticsService.trackEvent('performance_timer', {
        'name': name,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _timers.remove(name);
    }
  }
}

// 2. Error Tracking
class ErrorTracker {
  static void logError(Error error, StackTrace stackTrace) {
    // Local log
    print('Error: $error');
    print('StackTrace: $stackTrace');
    
    // Analytics
    AnalyticsService.trackEvent('error', {
      'message': error.toString(),
      'stackTrace': stackTrace.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // File log
    File('${getApplicationDocumentsDirectory().path}/error_log.txt')
        .writeAsStringSync(
          '${DateTime.now()}: $error\n$stackTrace\n\n',
          mode: FileMode.append,
        );
  }
}

// 3. Analytics Service
class AnalyticsService {
  static void trackEvent(String event, [Map<String, dynamic>? params]) {
    // Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: event,
      parameters: params,
    );
    
    // Local tracking (offline)
    _saveLocalEvent(event, params);
  }
  
  static void _saveLocalEvent(String event, Map<String, dynamic>? params) {
    // Αποθήκευση σε local database
    // Συγχρονισμός όταν υπάρχει σύνδεση
  }
}
🎯 Τελικό Χρονοδιάγραμμα
text
Φάση 0: Infrastructure           ██████░░░░░░░░░░░░░░  1-2 εβδομάδες
Φάση 1: Database Layer           ████████████░░░░░░░░  2-3 εβδομάδες
Φάση 2: Core Logic               ████████████████░░░░  3-4 εβδομάδες
Φάση 3: UI/UX Implementation     ████████████████████  4-5 εβδομάδες
Φάση 4: Reports & Analytics      ██████████████████░░  3-4 εβδομάδες
Φάση 5: Testing & Optimization   ████████████████░░░░  3-4 εβδομάδες
Φάση 6: Deployment               ██████████░░░░░░░░░░  2 εβδομάδες
---------------------------------------------------------------------
Σύνολο:                           ~18-24 εβδομάδες
📝 Σύνοψη - Βασικά Σημεία
✅ Διορθώσεις Λογικής
Atomic receipt number generation - Αποφυγή διπλότυπων

Πολλαπλές πληρωμές - Δυνατότητα μερικής εξόφλησης

Πλήρης υποστήριξη ΦΠΑ - 0%, 6%, 13%, 24%

Stock management - Αυτόματη παρακολούθηση αποθέματος

Offline-first - Πλήρης λειτουργία χωρίς internet

Event-driven architecture - Αποσύζευξη components

✨ Νέα Προτεινόμενα Χαρακτηριστικά
Budget planning - Μηνιαίος προϋπολογισμός ανά κατηγορία

OCR scanning - Σάρωση αποδείξεων με κάμερα

Barcode scanner - Γρήγορη εισαγωγή προϊόντων

Multi-currency - Υποστήριξη διαφορετικών νομισμάτων

Family sharing - Κοινόχρηστες αποδείξεις

Automated backups - Αυτόματο backup στο cloud

Biometric authentication - Fingerprint / Face ID

🚀 Πλεονεκτήματα
Πλήρως λειτουργικό offline

Adaptive UI - Mobile, Tablet, Desktop

Dark/Light theme - Auto-detection

High performance - Optimized queries & caching

Secure - Local encryption & biometrics

Extensible - Clean architecture

Production-ready - Comprehensive testing