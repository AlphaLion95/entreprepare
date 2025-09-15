import 'package:flutter/widgets.dart';
import 'currency_notifier.dart';

class CurrencyScope extends InheritedNotifier<CurrencyNotifier> {
  const CurrencyScope({super.key, required CurrencyNotifier notifier, required Widget child})
      : super(notifier: notifier, child: child);

  static CurrencyNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CurrencyScope>();
    assert(scope != null, 'CurrencyScope not found in context');
    return scope!.notifier!;
  }
}
