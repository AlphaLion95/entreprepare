# entreprepare

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Currency Settings

The app now supports dynamic currency display with default `PHP`.

Architecture:
- `services/currency_notifier.dart`: Loads and watches user settings, exposes current currency (defaults to PHP).
- `services/currency_scope.dart`: InheritedWidget wrapper placed in `main.dart` to provide global access without external state libs.
- `utils/currency_utils.dart`: `currencySymbol` and `formatCurrency` helpers; extend `_currencySymbols` map to add more codes.
- UI screens (home, plan list, plan editor, settings) now resolve currency via `CurrencyScope.of(context).currency` instead of keeping independent state.

Changing Currency:
1. Open Settings screen.
2. Select desired currency (e.g. USD, EUR, PHP).
3. Tap Save. This updates Firestore/local store and CurrencyNotifier; UI refreshes automatically.

Adding a New Currency Code:
1. Edit `lib/utils/currency_utils.dart` and add entry to `_currencySymbols` map.
2. Add the code to the dropdown list in `settings_screen.dart`.

Fallback Behavior:
- If settings cannot be loaded, UI falls back to `PHP`.
- If a symbol is missing, the code itself (e.g., `AUD`) is prefixed before the amount.

Formatting:
- Currently simple: `symbol + value.toStringAsFixed(2)`.
- For locale-aware formatting you can integrate `intl` package later and update `formatCurrency` to use `NumberFormat.currency`.
