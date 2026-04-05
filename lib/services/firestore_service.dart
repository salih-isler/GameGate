// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ARTIK ID DEĞİL, OYUN İSMİNİ (gameName) ALIYORUZ
  Future<void> addReview(String gameName, int rating, String comment) async {
    User? user = _auth.currentUser;
    if (user == null) {
      print("HATA: Kullanıcı giriş yapmamış!");
      return;
    }

    try {
      // .doc(gameId) YERİNE .doc(gameName) YAZDIK
      await _db.collection('games').doc(gameName).collection('reviews').add({
        'userId': user.uid,
        'userEmail': user.email,
        'rating': rating,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("BAŞARILI: Yorum kaydedildi!");
    } catch (e) {
      print("FIREBASE HATASI: $e");
    }
  }

  // BURASI DA ARTIK İSME GÖRE VERİ ÇEKİYOR
  Stream<QuerySnapshot> getReviews(String gameName) {
    return _db
        .collection('games')
        .doc(gameName) // <-- ID yerine İsim
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}