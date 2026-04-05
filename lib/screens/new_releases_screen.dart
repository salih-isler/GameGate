// lib/screens/new_releases_screen.dart

import 'package:flutter/material.dart';
import '../services/game_service.dart';
import 'details_screen.dart';

class NewReleasesScreen extends StatefulWidget {
  const NewReleasesScreen({super.key});

  @override
  State<NewReleasesScreen> createState() => _NewReleasesScreenState();
}

class _NewReleasesScreenState extends State<NewReleasesScreen> {
  final GameService _gameService = GameService();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _games = [];
  bool _isLoading = true;      // İlk yükleme
  bool _isLoadingMore = false; // Sayfa sonuna gelince yükleme
  int _currentPage = 1;        // Hangi sayfadayız

  @override
  void initState() {
    super.initState();
    _fetchGames();

    // Scroll Dinleyicisi: En aşağıya inildi mi?
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoadingMore) {
        _loadMoreGames();
      }
    });
  }

  // İlk açılışta verileri çek
  void _fetchGames() async {
    try {
      var games = await _gameService.getNewReleases(page: 1);
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Aşağı kaydırınca sonraki sayfayı çek
  void _loadMoreGames() async {
    setState(() => _isLoadingMore = true);
    try {
      int nextPage = _currentPage + 1;
      var newGames = await _gameService.getNewReleases(page: nextPage);
      
      if (mounted) {
        setState(() {
          _games.addAll(newGames); // Yeni oyunları listeye ekle
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121225), // Ana tema rengi
      appBar: AppBar(
        title: const Text("New Releases 🔥"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : ListView.builder(
              controller: _scrollController, // Scroll kontrolcüsü önemli
              padding: const EdgeInsets.all(16),
              itemCount: _games.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Eğer listenin en sonundaysak yükleniyor çubuğunu göster
                if (index == _games.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                final game = _games[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DetailsScreen(game: game)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E32),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Oyun Resmi
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: game['background_image'] != null
                              ? Image.network(
                                  game['background_image'],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : Container(width: 120, height: 120, color: Colors.grey),
                        ),
                        // Oyun Bilgileri
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Text(
                                      game['released'] ?? "TBA",
                                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // --- GÜNCELLENEN KISIM ---
                                _buildRatingBadge(game),
                                // -------------------------
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ------------------------------------------
  // --- YENİ EKLENEN AKILLI PUAN ROZETİ ---
  // ------------------------------------------
  Widget _buildRatingBadge(Map<String, dynamic> game) {
    // 1. Önce Metacritic puanına bak (Varsa bunu kullan)
    if (game['metacritic'] != null && game['metacritic'] != 0) {
      int metaScore = game['metacritic'];
      return _designBadge(metaScore, true); // true = Metacritic olduğunu belirtir
    }

    // 2. Yoksa Kullanıcı Puanına (rating) bak
    if (game['rating'] != null && game['rating'] != 0.0) {
      double rawRating = (game['rating'] is int) 
          ? (game['rating'] as int).toDouble() 
          : game['rating'];
      int userScore = (rawRating * 20).round(); // 5 üzerinden puanı 100'e çevir
      return _designBadge(userScore, false);
    }

    // 3. İkisi de yoksa (Puan 0 ise) "-" göster
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: const Text(
        "-", 
        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  // Rozet Tasarımı Yardımcı Fonksiyonu
  Widget _designBadge(int score, bool isMetacritic) {
    Color color = score >= 75
        ? const Color(0xFF00E676) // Yeşil (Yüksek)
        : (score >= 50 ? const Color(0xFFFFC400) : const Color(0xFFFF3D00)); // Sarı veya Kırmızı

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(isMetacritic ? 0.8 : 0.5)), // Metacritic ise çerçeve daha belirgin
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          if (isMetacritic) ...[ // Metacritic ise yanına küçük bir 'm' harfi koy
             const SizedBox(width: 4),
             Text("m", style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontStyle: FontStyle.italic)),
          ]
        ],
      ),
    );
  }
}