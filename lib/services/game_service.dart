// lib/services/game_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class GameService {
  final String apiKey = 'af0364d795d8459ebe9c97ba8f6240af'; 
  final String baseUrl = 'https://api.rawg.io/api';

  // --- 1. OYUN HABERLERİ (Sadece Kaliteli Oyun Siteleri) ---
  Future<List<dynamic>> getGamingNews() async {
    // Demo key (Çalışmazsa newsapi.org'dan ücretsiz alabilirsin)
    const String newsApiKey = '9de5db322ba14e8c8c652ab8a23d382e'; 
    // Sadece bu kaliteli oyun sitelerinden haber getir
    const String domains = 'ign.com,gamespot.com,polygon.com,kotaku.com,pcgamer.com,eurogamer.net';
    
    final url = 'https://newsapi.org/v2/everything?domains=$domains&language=en&sortBy=publishedAt&apiKey=$newsApiKey';
    
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['articles']; 
    } else {
      print("HATA KODU: ${response.statusCode}");
  print("HATA MESAJI: ${response.body}");
      throw Exception('Could not load news!');
    }
  }

  // --- 2. İSİM TEMİZLEME (Fiyat Eşleşmesi İçin) ---
  String cleanGameName(String name) {
    // İki nokta veya tireden sonrasını at (Örn: "GTA V: Premium" -> "GTA V")
    String cleanName = name.split(':')[0].split('-')[0];
    
    // Romen rakamlarını normal sayıya çevir (CheapShark API için gerekli)
    cleanName = cleanName.replaceAll(' III', ' 3'); 
    cleanName = cleanName.replaceAll(' II', ' 2');  
    cleanName = cleanName.replaceAll(' IV', ' 4');
    if (cleanName.endsWith(' V')) cleanName = cleanName.replaceAll(' V', ' 5');
    
    return cleanName.trim();
  }

  // --- 3. FİYAT SORGULAMA (CheapShark API) ---
  Future<List<dynamic>> getGamePrices(String rawgName) async {
    String gameName = cleanGameName(rawgName);
    
    // Önce oyunun CheapShark ID'sini bul
    final searchUrl = 'https://www.cheapshark.com/api/1.0/games?title=$gameName&limit=1';
    final searchResponse = await http.get(Uri.parse(searchUrl));

    if (searchResponse.statusCode == 200) {
      final searchData = json.decode(searchResponse.body);
      if (searchData.isEmpty) return []; // Oyun bulunamazsa boş dön

      String cheapSharkId = searchData[0]['gameID'];
      
      // ID ile tüm mağaza fiyatlarını çek
      final pricesUrl = 'https://www.cheapshark.com/api/1.0/games?id=$cheapSharkId';
      final pricesResponse = await http.get(Uri.parse(pricesUrl));
      
      if (pricesResponse.statusCode == 200) {
        final pricesData = json.decode(pricesResponse.body);
        return pricesData['deals']; 
      }
    }
    return [];
  }

  // --- 4. MAĞAZA İSİMLERİ (ID -> İsim Çevirici) ---
  String? getStoreName(String storeID) {
    Map<String, String> stores = {
      "1": "Steam", "2": "GamersGate", "3": "GreenManGaming", "7": "GOG",
      "8": "Origin (EA)", "11": "Humble Store", "13": "Ubisoft", "15": "Fanatical",
      "25": "Epic Games", "31": "Blizzard", "34": "Noctre"
    };
    return stores[storeID]; 
  }

  // --- DİĞER STANDART FONKSİYONLAR ---
  
  // Popüler Oyunlar (Sayfalı)
  Future<List<dynamic>> getPopularGames({int page = 1}) async {
    final url = '$baseUrl/games?key=$apiKey&dates=2023-01-01,2025-12-30&ordering=-added&page_size=20&page=$page';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else { throw Exception('Error loading popular games'); }
  }

  // Yeni Çıkanlar (Son 6 Ay)
 Future<List<dynamic>> getNewReleases({int page = 1}) async {
    // Tarihleri dinamik alıyoruz (Son 3 ay)
    DateTime now = DateTime.now();
    DateTime past = now.subtract(const Duration(days: 90)); // Son 90 gün
    
    String dates = "${past.year}-${past.month.toString().padLeft(2, '0')}-${past.day.toString().padLeft(2, '0')},${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final response = await http.get(
      Uri.parse('$baseUrl/games?key=$apiKey&dates=$dates&ordering=-released&page_size=20&page=$page'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load new releases');
    }
  }

  // Arama Fonksiyonu
  Future<List<dynamic>> searchGames(String query) async {
    final url = '$baseUrl/games?key=$apiKey&search=$query&page_size=10';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else { throw Exception('Search failed'); }
  }

  // Detay Getir
  Future<Map<String, dynamic>> getGameDetails(int id) async {
    final url = '$baseUrl/games/$id?key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return json.decode(response.body);
    else throw Exception('Error loading details');
  }

  // Reddit Yorumları Getir
  Future<List<dynamic>> getGameRedditPosts(int id) async {
    final url = '$baseUrl/games/$id/reddit?key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results']; 
    } else return []; 
  }

  // 1. Tüm Mağazaların İsimlerini ve Logolarını Çeker (Steam, Epic vs.)
  Future<List<dynamic>> getStores() async {
    final response = await http.get(Uri.parse("https://www.cheapshark.com/api/1.0/stores"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Mağazalar yüklenemedi');
    }
  }

  // 2. Bir Oyunun ID'sine Göre Tüm Mağazalardaki Fiyatlarını Çeker (Cimri Mantığı)
  Future<Map<String, dynamic>> getGameDetailsToPrice(String gameID) async {
    final response = await http.get(Uri.parse("https://www.cheapshark.com/api/1.0/games?id=$gameID"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Detaylar yüklenemedi');
    }
  }
  Future<List<dynamic>> getGameDeals() async {
    // storeID=1 (Steam) ve onSale=1 (İndirimdekiler)
    final url = Uri.parse("https://www.cheapshark.com/api/1.0/deals?storeID=1&upperPrice=50&pageSize=60");
    
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fiyatlar yüklenemedi!');
    }
  }
}