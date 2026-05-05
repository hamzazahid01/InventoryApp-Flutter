import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _darkModeKey = 'settings_dark_mode_v1';
  static const _currencyCodeKey = 'settings_currency_code_v1';
  static const _lowStockKey = 'settings_low_stock_threshold_v1';

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<String> loadCurrencyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyCodeKey) ?? 'AED';
  }

  Future<void> saveCurrencyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, code.toUpperCase());
  }

  Future<int> loadLowStockThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lowStockKey) ?? 10;
  }

  Future<void> saveLowStockThreshold(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lowStockKey, value.clamp(1, 9999));
  }
}
