import 'package:flutter/material.dart';

import '../constants/currencies.dart';
import '../services/settings_service.dart';

class SettingsNotifier extends ChangeNotifier {
  SettingsNotifier(this._service);

  final SettingsService _service;

  bool _darkMode = false;
  String _currencyCode = kDefaultCurrencyCode;
  int _lowStockThreshold = 10;

  bool get darkMode => _darkMode;
  String get currencyCode => _currencyCode;
  int get lowStockThreshold => _lowStockThreshold;

  ThemeMode get themeMode =>
      _darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    _darkMode = await _service.loadDarkMode();
    final rawCurrency = await _service.loadCurrencyCode();
    _currencyCode = normalizeCurrencyCode(rawCurrency);
    if (_currencyCode != rawCurrency.toUpperCase().trim()) {
      await _service.saveCurrencyCode(_currencyCode);
    }
    _lowStockThreshold = await _service.loadLowStockThreshold();
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _service.saveDarkMode(value);
    notifyListeners();
  }

  Future<void> setCurrencyCode(String code) async {
    _currencyCode = normalizeCurrencyCode(code);
    await _service.saveCurrencyCode(_currencyCode);
    notifyListeners();
  }

  Future<void> setLowStockThreshold(int value) async {
    _lowStockThreshold = value.clamp(1, 9999);
    await _service.saveLowStockThreshold(_lowStockThreshold);
    notifyListeners();
  }
}
