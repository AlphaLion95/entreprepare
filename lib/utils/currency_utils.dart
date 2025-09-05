// Create folder if missing: c:\flutter_projects\entreprepare\lib\utils
const Map<String, String> _currencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'PHP': '₱',
  'GBP': '£',
  'JPY': '¥',
  // add more as needed
};

String currencySymbol(String code) =>
    _currencySymbols[code.toUpperCase()] ?? code;

String formatCurrency(double value, String code) {
  final sym = currencySymbol(code);
  // simple formatting: symbol + two decimals
  return '$sym${value.toStringAsFixed(2)}';
}
