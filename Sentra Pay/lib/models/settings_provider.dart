import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _historyFeatureUnlocked = false;
  bool _advancedAnalyticsUnlocked = false;
  bool _qrScannerUnlocked = true; // Default unlocked

  bool get historyFeatureUnlocked => _historyFeatureUnlocked;
  bool get advancedAnalyticsUnlocked => _advancedAnalyticsUnlocked;
  bool get qrScannerUnlocked => _qrScannerUnlocked;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _historyFeatureUnlocked = prefs.getBool('historyFeatureUnlocked') ?? false;
    _advancedAnalyticsUnlocked = prefs.getBool('advancedAnalyticsUnlocked') ?? false;
    _qrScannerUnlocked = prefs.getBool('qrScannerUnlocked') ?? true;
    notifyListeners();
  }

  Future<void> toggleHistoryFeature(bool value) async {
    _historyFeatureUnlocked = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('historyFeatureUnlocked', value);
    notifyListeners();
  }

  Future<void> toggleAdvancedAnalytics(bool value) async {
    _advancedAnalyticsUnlocked = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('advancedAnalyticsUnlocked', value);
    notifyListeners();
  }

  Future<void> toggleQrScanner(bool value) async {
    _qrScannerUnlocked = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('qrScannerUnlocked', value);
    notifyListeners();
  }

  Future<void> unlockAllFeatures() async {
    _historyFeatureUnlocked = true;
    _advancedAnalyticsUnlocked = true;
    _qrScannerUnlocked = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('historyFeatureUnlocked', true);
    await prefs.setBool('advancedAnalyticsUnlocked', true);
    await prefs.setBool('qrScannerUnlocked', true);
    notifyListeners();
  }

  Future<void> resetAllFeatures() async {
    _historyFeatureUnlocked = false;
    _advancedAnalyticsUnlocked = false;
    _qrScannerUnlocked = true; // Keep QR scanner as default
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('historyFeatureUnlocked', false);
    await prefs.setBool('advancedAnalyticsUnlocked', false);
    await prefs.setBool('qrScannerUnlocked', true);
    notifyListeners();
  }
}
