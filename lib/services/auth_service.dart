// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kayıt Olma Fonksiyonu
  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      return "success"; // İşlem Başarılı
    } on FirebaseAuthException catch (e) {
      return e.message; // Hata mesajını döndür (Örn: Bu mail zaten kayıtlı)
    }
  }

  // Giriş Yapma Fonksiyonu
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message; // Hata mesajını döndür (Örn: Şifre yanlış)
    }
  }

  // Çıkış Yapma
  Future<void> logout() async {
    await _auth.signOut();
  }
}