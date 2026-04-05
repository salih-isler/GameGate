import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // Çeviri için
import '../services/game_service.dart';
import 'news_detail_screen.dart'; // Detay sayfasını import ettik
import 'game_prices_screen.dart'; // Fiyat sayfasına geçiş için (Varsa)

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final GameService _gameService = GameService();
  List<dynamic> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  void _fetchNews() async {
    try {
      var news = await _gameService.getGamingNews();
      if (mounted) {
        setState(() {
          _articles = news;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("HABER ÇEKME HATASI: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- DARK MODE ADAPTASYONU (SADECE BURASI EKLENDİ) ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Eğer Dark Mode ise senin eski renklerin (White), değilse Siyah (Black)
    final textColor = isDarkMode ? Colors.white : Colors.black;
    // Eğer Dark Mode ise senin eski kart rengin, değilse Beyaz
    final cardColor = isDarkMode ? const Color(0xFF1E1E32) : Colors.white;
    // Yan metinler için gri tonları
    final subTextColor = isDarkMode ? Colors.white60 : Colors.black54;
    final metaColor = isDarkMode ? Colors.white30 : Colors.black38;
    // -----------------------------------------------------

    return Scaffold(
      // Arka planı temaya bıraktık
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      appBar: AppBar(
        // Başlık rengini dinamik yaptık
        title: Text("News".tr(), style: TextStyle(color: textColor)), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor), // Geri butonu rengi
        actions: [
          // DİL DEĞİŞTİRME BUTONU
          IconButton(
            tooltip: "Dili Değiştir / Change Language",
            icon: Icon(
              Icons.language, 
              // Aktif dil mor, pasif dil dinamik renk (beyaz veya siyah)
              color: context.locale.languageCode == 'tr' ? const Color(0xFF6C63FF) : textColor
            ),
            onPressed: () {
              if (context.locale.languageCode == 'tr') {
                context.setLocale(const Locale('en'));
              } else {
                context.setLocale(const Locale('tr'));
              }
            },
          ),
          
          // FİYAT MAĞAZASI BUTONU
          IconButton(
            // İkon rengini dinamik yaptık
            icon: Icon(Icons.shopping_bag_outlined, color: textColor),
            tooltip: "store_title".tr(), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GamePricesScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _articles.length,
              itemBuilder: (context, index) {
                final article = _articles[index];
                
                if (article['urlToImage'] == null || article['title'] == null) {
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailScreen(
                          newsUrl: article['url'],
                          title: article['source']['name'] ?? "News",
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: cardColor, // Dinamik Kart Rengi
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Gölgeyi hafiflettik
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Haber Görseli
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            article['urlToImage'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 180,
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image, color: Colors.white54),
                            ),
                          ),
                        ),
                        
                        // İçerik Metinleri
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Başlık
                              Text(
                                article['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor, // Dinamik Renk
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Kaynak Etiketi
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  article['source']['name'] ?? "News",
                                  style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              
                              // Açıklama
                              Text(
                                article['description'] ?? "",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: subTextColor, // Dinamik Renk
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 15),
                              
                              // Tarih
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  article['publishedAt']?.substring(0, 10) ?? "",
                                  style: TextStyle(
                                    color: metaColor, // Dinamik Renk
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}