## 6. Responsive Design System

### 6.1 Screen Layouts

#### Mobile (< 600px)
```
┌─────────────────┐
│   App Bar       │
├─────────────────┤
│                 │
│   Content       │
│   (Full Width)  │
│                 │
├─────────────────┤
│  Bottom Nav Bar │
└─────────────────┘
```

#### Tablet (600px - 1200px)
```
┌─────────────────────────────────────┐
│           App Bar                   │
├─────────────────────────────────────┤
│           │                         │
│  Side     │      Content            │
│  Nav      │      (2 Columns)        │
│  Rail     │                         │
│           │                         │
└─────────────────────────────────────┘
```

#### Desktop (> 1200px)
```
┌─────────────────────────────────────────────────────┐
│                    App Bar                          │
├────────────────┬────────────────────────────────────┤
│                │                                    │
│  Navigation    │         Content                    │
│  Drawer        │         (3-4 Columns)              │
│                │                                    │
│                │                                    │
└────────────────┴────────────────────────────────────┘
```

### 6.2 Navigation Strategy

```dart
/// SPO: Navigation based on screen size
class AppNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileNavigation(context),
      tablet: _buildTabletNavigation(context),
      desktop: _buildDesktopNavigation(context),
    );
  }
  
  Widget _buildMobileNavigation(BuildContext context) {
    return Scaffold(
      body: _currentScreen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Αρχική'),
          NavigationDestination(icon: Icon(Icons.receipt), label: 'Αποδείξεις'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Είδη'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Αναφορές'),
        ],
      ),
    );
  }
  
  Widget _buildTabletNavigation(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.selected,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home), label: Text('Αρχική')),
              NavigationRailDestination(icon: Icon(Icons.receipt), label: Text('Αποδείξεις')),
              NavigationRailDestination(icon: Icon(Icons.category), label: Text('Είδη')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Αναφορές')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _currentScreen),
        ],
      ),
    );
  }
  
  Widget _buildDesktopNavigation(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
                child: Text('ExpenseTracker', style: TextStyle(fontSize: 20)),
              ),
              NavigationDrawerDestination(icon: Icon(Icons.home), label: Text('Αρχική')),
              NavigationDrawerDestination(icon: Icon(Icons.receipt), label: Text('Αποδείξεις')),
              NavigationDrawerDestination(icon: Icon(Icons.category), label: Text('Είδη')),
              NavigationDrawerDestination(icon: Icon(Icons.bar_chart), label: Text('Αναφορές')),
              Divider(),
              NavigationDrawerDestination(icon: Icon(Icons.settings), label: Text('Ρυθμίσεις')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _currentScreen),
        ],
      ),
    );
  }
}
```

### 6.3 Responsive Grid

```dart
/// SPO: Responsive grid widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    final columns = Breakpoints.gridColumns(context);
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: columns == 1 ? 2 : 1.5,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
```

---

## 7. Theme System (Dark/Light)

> **ΣΗΜΕΙΩΣΗ:** Τα snippets του §7 είναι pre-implementation drafts (τιμές
> χρωμάτων/διαστάσεων/τυπογραφίας διαφέρουν). Πηγή αλήθειας: §3.11–§3.13 +
> `lib/core/theme/` (νέα πεδία: `AppColors.overlay/divider*`,
> `AppDimensions.desktopLarge/suggestionListMaxHeight/iconXxl`,
> `AppTheme` με `CardThemeData` + `AppDimensions`).

### 7.1 Color Palette

```dart
/// SPO: Color palette
class AppColors {
  AppColors._();
  
  // Primary Colors
  static const Color primaryLight = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF90CAF9);
  
  // Secondary Colors
  static const Color secondaryLight = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF81C784);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Payment Status Colors
  static const Color paid = Color(0xFF4CAF50);
  static const Color partial = Color(0xFFFFA726);
  static const Color pending = Color(0xFFE53935);
  
  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];
  
  // Light Theme Background
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  // Dark Theme Background
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
}
```

### 7.2 Text Styles

```dart
/// SPO: Typography
class AppTextStyles {
  AppTextStyles._();
  
  static TextStyle headline1(BuildContext context) => 
    Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.bold,
    );
  
  static TextStyle headline2(BuildContext context) => 
    Theme.of(context).textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.bold,
    );
  
  static TextStyle headline3(BuildContext context) => 
    Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w600,
    );
  
  static TextStyle bodyText1(BuildContext context) => 
    Theme.of(context).textTheme.bodyLarge!;
  
  static TextStyle bodyText2(BuildContext context) => 
    Theme.of(context).textTheme.bodyMedium!;
  
  static TextStyle caption(BuildContext context) => 
    Theme.of(context).textTheme.bodySmall!;
  
  static TextStyle buttonText(BuildContext context) => 
    Theme.of(context).textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w600,
    );
}
```

### 7.3 Dimensions

```dart
/// SPO: Spacing and sizing constants
class AppDimensions {
  AppDimensions._();
  
  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  
  // Border Radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 9999;
  
  // Card Elevation
  static const double elevationSm = 1;
  static const double elevationMd = 2;
  static const double elevationLg = 4;
  
  // Icon Sizes
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
  
  // Button Heights
  static const double buttonHeight = 48;
  static const double buttonHeightSm = 36;
  
  // App Bar Height
  static const double appBarHeight = 56;
  
  // Bottom Nav Height
  static const double bottomNavHeight = 80;
  
  // Navigation Rail Width
  static const double navigationRailWidth = 80;
  
  // Navigation Drawer Width
  static const double navigationDrawerWidth = 280;
}
```
---

