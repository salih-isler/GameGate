import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Varsayılan olarak Karanlık Mod (Dark Mode) açık başlasın
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  // Temayı değiştiren fonksiyon
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Tüm uygulamaya "Ben değiştim!" diye haber verir
  }
}