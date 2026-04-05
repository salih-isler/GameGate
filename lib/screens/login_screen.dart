// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    // Alanlar boş mu kontrol et
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.orange),
      );
      return;
    }

    // Giriş servisini çağır
    String? result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (result == "success") {
      // Başarılıysa Ana Sayfaya yönlendir
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomeScreen())
        );
      }
    } else {
      // Hata varsa göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? "errors.general".tr()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme Provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language Switcher
          DropdownButton<String>(
            value: context.locale.languageCode,
            dropdownColor: isDark ? const Color(0xFF1E1E32) : Colors.white,
            underline: Container(),
            icon: Icon(Icons.language, color: Colors.white.withOpacity(0.8)),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            items: [
              DropdownMenuItem(value: 'tr', child: Row(children: const [Text("🇹🇷 TR")])),
              DropdownMenuItem(value: 'en', child: Row(children: const [Text("🇺🇸 EN")])),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                context.setLocale(Locale(newValue));
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      // Gradient (Geçişli) Arka Plan
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
               ? [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF24243E)]
               : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- İKON & LOGO ---
                const Icon(Icons.gamepad, size: 80, color: Color(0xFF6C63FF)),
                const SizedBox(height: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF6C63FF)],
                  ).createShader(bounds),
                  child: Text(
                    "titles.app_name".tr(), 
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ),
                const SizedBox(height: 50),

                // --- GİRİŞ KUTULARI ---
                _buildModernInput(
                  _emailController, 
                  "auth.email_hint".tr(), 
                  Icons.email_outlined,
                  isDark
                ),
                const SizedBox(height: 20),
                _buildModernInput(
                  _passwordController, 
                  "auth.password_hint".tr(), 
                  Icons.lock_outline,
                  isDark,
                  isPassword: true
                ),
                
                const SizedBox(height: 40),

                // --- NEON BUTON ---
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)]),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4), 
                        blurRadius: 15, 
                        offset: const Offset(0, 5)
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, 
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text("auth.login_btn".tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  child: Text("auth.no_account".tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern Input Tasarımı
  Widget _buildModernInput(TextEditingController controller, String hint, IconData icon, bool isDark, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black54),
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}