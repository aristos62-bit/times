/// Κοινά helpers αναλύσεων «Στατιστικά» (§2.3).
///
/// Part αρχείο (split 30-09-2026, κανόνας 7 <500 γρ.): labels/headers/rows
/// προβολών + dropdowns + `_groupDisplay` + `_LedgerError` — χρησιμοποιούνται
/// από 2+ αναλύσεις. Τα imports του `statistics_section.dart` ισχύουν εδώ.
part of 'statistics_section.dart';

/// SPoT label ταξινόμησης αγορών (§2.3 · 2η ανάλυση).
String _sortLabel(PurchasesSort sort) => switch (sort) {
  PurchasesSort.dateAsc => AppStrings.statsSortDateAsc,
  PurchasesSort.dateDesc => AppStrings.statsSortDateDesc,
  PurchasesSort.supplier => AppStrings.statsSortSupplier,
  PurchasesSort.category => AppStrings.statsSortCategory,
};

/// SPoT label ομαδοποίησης (§2.3 · 3η ανάλυση).
String _groupLabel(PurchasesGroup group) => switch (group) {
  PurchasesGroup.category => AppStrings.statsGroupCategory,
  PurchasesGroup.supplier => AppStrings.statsGroupSupplier,
  PurchasesGroup.day => AppStrings.statsGroupDay,
  PurchasesGroup.month => AppStrings.statsGroupMonth,
};

/// Headers πίνακα αγορών (8+N στήλες — 5 fixed + N μονάδων + Τιμή/Έκπτωση/Καθαρή, §2.3).
List<String> _purchasesHeaders(List<Unit> units) => [
  AppStrings.statsColumnDate,
  AppStrings.statsColumnReceipt,
  AppStrings.fieldItemName,
  AppStrings.statsColumnCategory,
  AppStrings.statsColumnSupplier,
  for (final unit in units) unit.name,
  AppStrings.statsColumnPrice,
  AppStrings.statsColumnDiscount,
  AppStrings.statsColumnNet,
];

/// Γραμμή strings πίνακα αγορών (presentation SPoT, §2.5 — μία πηγή για
/// οθόνη-dialog/PDF, όχι αντιγραφή ανά καλούντα).
List<String> _purchasesBodyRow(
  PeriodPurchaseRow row,
  List<Unit> units,
  MaterialLocalizations localizations,
) {
  String money(int cents) =>
      '${CurrencyTextField.formatCents(cents)} ${AppStrings.currencySymbol}';
  return [
    localizations.formatShortDate(row.date),
    '${row.receiptId}',
    row.itemName,
    row.categoryName,
    row.supplierName,
    for (final unit in units)
      if (row.unitId == unit.id)
        QuantityTextField.formatQuantity(row.quantity)
      else
        '',
    money(row.priceCents),
    money(row.discountCents),
    money(row.priceCents - row.discountCents),
  ];
}

/// Γραμμή συνόλων («Σύνολο: (...) Χ,ΧΧ €» — μία πηγή, §1.1).
String _purchasesTotalsLine(PurchasesTotals totals) =>
    '${totals.label}: ${CurrencyTextField.formatCents(totals.netTotalCents)} '
    '${AppStrings.currencySymbol}';

/// Dropdown ταξινόμησης (shared 2η/3η ανάλυση — pattern selector §2.1).
class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.sort, required this.onChanged});

  final PurchasesSort sort;
  final ValueChanged<PurchasesSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<PurchasesSort>(
      key: ValueKey(sort),
      initialSelection: sort,
      label: const Text(AppStrings.statsSortLabel),
      onSelected: (value) {
        if (value != null) onChanged(value);
      },
      dropdownMenuEntries: [
        for (final s in PurchasesSort.values)
          DropdownMenuEntry(value: s, label: _sortLabel(s)),
      ],
    );
  }
}

/// Dropdown ομαδοποίησης (3η ανάλυση — pattern selector §2.1).
class _GroupDropdown extends StatelessWidget {
  const _GroupDropdown({required this.group, required this.onChanged});

  final PurchasesGroup group;
  final ValueChanged<PurchasesGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<PurchasesGroup>(
      key: ValueKey(group),
      initialSelection: group,
      label: const Text(AppStrings.statsGroupLabel),
      onSelected: (value) {
        if (value != null) onChanged(value);
      },
      dropdownMenuEntries: [
        for (final g in PurchasesGroup.values)
          DropdownMenuEntry(value: g, label: _groupLabel(g)),
      ],
    );
  }
}

/// Προβολή raw group-key (§2.3 · 3η ανάλυση): ονόματα ως έχουν · ημέρα/μήνας
/// με locale (ο service δεν έχει locale — mapping εδώ, §2.5). Άγνωστο format
/// → raw (defensive, ποτέ crash).
String _groupDisplay(
  PurchasesGroup group,
  String raw,
  MaterialLocalizations localizations,
) {
  if (group == PurchasesGroup.day) {
    final parts = raw.split('-');
    if (parts.length == 3) {
      final date = DateTime.tryParse(raw);
      if (date != null) return localizations.formatShortDate(date);
    }
    return raw;
  }
  if (group == PurchasesGroup.month) {
    final parts = raw.split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year != null && month != null && month >= 1 && month <= 12) {
        return localizations.formatMonthYear(DateTime(year, month));
      }
    }
    return raw;
  }
  return raw;
}

/// Σφάλμα ledger: `loadDataFailed` + «Επανάληψη» (SPoT, §2.1).
class _LedgerError extends StatelessWidget {
  const _LedgerError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppErrors.loadDataFailed, style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: onRetry,
          child: const Text(AppStrings.retryButton),
        ),
      ],
    );
  }
}
