import 'package:flutter/foundation.dart';
import 'settings_service.dart';

/// Simple ChangeNotifier that exposes current currency code (e.g. PHP) and
/// listens to settings changes. Falls back to 'PHP' if unavailable.
class CurrencyNotifier extends ChangeNotifier {
  final SettingsService _settingsService;
  String _currency = 'PHP';
  bool _initialized = false;

  CurrencyNotifier(this._settingsService);

  String get currency => _currency;
  bool get initialized => _initialized;

  /// Initialize by fetching once, then listening to changes.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final s = await _settingsService.fetchSettings();
      if (s != null && s.currency.isNotEmpty) {
        _currency = s.currency;
      }
      // watch stream for live updates (if auth disabled this becomes a single future)
      _settingsService.watchSettings().listen((s) {
        final next = s?.currency ?? 'PHP';
        if (next != _currency) {
          _currency = next;
          notifyListeners();
        }
      });
    } catch (_) {
      // swallow; keep default
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  /// Directly set currency and persist.
  Future<void> setCurrency(String code) async {
    final next = code.trim().toUpperCase();
    if (next.isEmpty) return;
    if (next == _currency) return;
    _currency = next;
    notifyListeners();
    try {
      final existing = await _settingsService.fetchSettings();
      final updated = Settings(
        currency: next,
        plan: existing?.plan ?? 'trial',
        features: existing?.features ?? {},
        updatedAt: DateTime.now(),
      );
      await _settingsService.saveSettings(updated);
    } catch (_) {
      // revert? For simplicity keep new value; user can re-open settings if mismatch.
    }
  }
}
