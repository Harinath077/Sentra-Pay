import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Always dark mode — premium fintech look
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    // Dark mode is permanent — no toggling
  }
}
