import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:easy_localization/easy_localization.dart'; // Dil Paketi
import '../services/game_service.dart';
import '../services/firestore_service.dart';

class DetailsScreen extends StatefulWidget {
  final dynamic game;
  const DetailsScreen({super.key, required this.game});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final GameService _gameService = GameService();
  final FirestoreService _firestoreService = FirestoreService();
  
  Map<String, dynamic>? _gameDetails;
  List<dynamic> _redditPosts = [];
  List<dynamic> _stores = []; 
  List<dynamic> _gamePrices = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  void _fetchDetails() async {
    try {
      // Tüm verileri paralel çekerek hız kazanıyoruz
      var detailsFuture = _gameService.getGameDetails(widget.game['id']);
      var redditFuture = _gameService.getGameRedditPosts(widget.game['id']);
      var storesFuture = _gameService.getStores(); 
      var pricesFuture = _gameService.getGamePrices(widget.game['name']); 

      var results = await Future.wait([detailsFuture, redditFuture, storesFuture, pricesFuture]);

      if (mounted) {
        setState(() {
          _gameDetails = results[0] as Map<String, dynamic>;
          _redditPosts = results[1] as List<dynamic>;
          _stores = results[2] as List<dynamic>;
          _gamePrices = results[3] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Veri çekme hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HIZLI VE GÜVENLİ TARAYICI (Geri Dönüş Butonlu) ---
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    
    // LaunchMode.inAppBrowserView -> Uygulama içinde güvenli pencere açar (X butonu olur)
    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
       // Eğer bu mod desteklenmezse dış tarayıcıyı dener
       if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Could not launch $url"), backgroundColor: Colors.red),
           );
         }
       }
    }
  }

  // Mağaza ID'sinden Mağaza İsmini Bulma
  String getStoreName(String storeID) {
    var store = _stores.firstWhere((s) => s['storeID'] == storeID, orElse: () => null);
    return store != null ? store['storeName'] : "Store";
  }

  // Mağaza ID'sinden Logo Bulma
  String getStoreLogo(String storeID) {
    var store = _stores.firstWhere((s) => s['storeID'] == storeID, orElse: () => null);
    return store != null ? "https://www.cheapshark.com${store['images']['logo']}" : "";
  }

  void _showAddReviewDialog(bool isDark) {
    int selectedRating = 5; 
    TextEditingController commentController = TextEditingController();
    
    // Tema renkleri
    Color dialogColor = isDark ? const Color(0xFF1E1E32) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("review_dialog.title".tr(), style: TextStyle(color: textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("review_dialog.tap_rate".tr(), style: TextStyle(color: textColor.withOpacity(0.7))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setDialogState(() => selectedRating = index + 1),
                        icon: Icon(index < selectedRating ? Icons.star : Icons.star_border, color: const Color(0xFFFFC400), size: 32),
                      );
                    }),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: commentController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "review_dialog.hint_text".tr(),
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text("review_dialog.cancel".tr(), style: TextStyle(color: textColor.withOpacity(0.5)))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                  onPressed: () {
                    if (commentController.text.isNotEmpty) {
                      _firestoreService.addReview(widget.game['name'].toString(), selectedRating, commentController.text);
                      Navigator.pop(context); 
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("details.success_review".tr())));
                    }
                  },
                  child: Text("review_dialog.post".tr(), style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FİYAT LİSTESİ BÖLÜMÜ ---
  Widget _buildPriceSection(bool isDark, Color textColor, Color cardColor) {
    if (_gamePrices.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("where_to_buy".tr(), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _gamePrices.map((deal) {
              final storeName = getStoreName(deal['storeID']);
              final iconUrl = getStoreLogo(deal['storeID']);
              final price = deal['price'];
              final dealID = deal['dealID'];
              final redirectUrl = "https://www.cheapshark.com/redirect?dealID=$dealID";

              return GestureDetector(
                onTap: () => _launchURL(redirectUrl),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      if (iconUrl.isNotEmpty) Image.network(iconUrl, width: 24, height: 24),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(storeName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("\$$price", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildScoreBadge() {
    int score = 0;
    
    if (_gameDetails != null && _gameDetails!['metacritic'] != null) {
      score = _gameDetails!['metacritic'];
    } else if (widget.game['metacritic'] != null) {
      score = widget.game['metacritic'];
    } else if (widget.game['rating'] != null) {
      score = ((widget.game['rating'] as num) * 20).round();
    }

    if (score == 0) return const SizedBox();

    Color color = score >= 75 ? const Color(0xFF00E676) : (score >= 50 ? const Color(0xFFFFC400) : const Color(0xFFFF3D00));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(5),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "details.metascore".tr(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold)
          ),
          const SizedBox(width: 5),
          Text(
            "$score", 
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- TEMA AYARLARI ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300, pinned: true, backgroundColor: bgColor,
                  iconTheme: IconThemeData(color: textColor),
                  flexibleSpace: FlexibleSpaceBar(
                    background: widget.game['background_image'] != null 
                        ? Hero(
                            tag: widget.game['name'].toString(), 
                            child: Image.network(widget.game['background_image'], fit: BoxFit.cover),
                          )
                        : Container(color: Colors.grey),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.game['name'], style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        
                        Row(
                          children: [
                            _buildScoreBadge(),
                          ],
                        ),
                        
                        const SizedBox(height: 20),

                        // FİYATLAR (HIZLI TARAYICI İLE)
                        _buildPriceSection(isDark, textColor, cardColor), 

                        Text(_gameDetails?['description_raw'] ?? "details.description_empty".tr(), style: TextStyle(color: textColor.withOpacity(0.8), height: 1.5, fontSize: 14)),
                        const SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                          children: [
                            Text("details.user_reviews_title".tr(), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)), 
                            ElevatedButton.icon(
                              onPressed: () => _showAddReviewDialog(isDark), 
                              icon: const Icon(Icons.rate_review, size: 18, color: Colors.white), 
                              label: Text("details.add_review_btn".tr(), style: const TextStyle(color: Colors.white)), 
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF))
                            )
                          ]
                        ),
                        const SizedBox(height: 10),
                        
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestoreService.getReviews(widget.game['name'].toString()),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) return const Text("Something went wrong", style: TextStyle(color: Colors.red));
                            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                            var reviews = snapshot.data!.docs;
                            if (reviews.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20), width: double.infinity, 
                                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(10)), 
                                child: Column(children: [Icon(Icons.chat_bubble_outline, color: textColor.withOpacity(0.5), size: 30), const SizedBox(height: 5), Text("details.no_reviews_yet".tr(), style: TextStyle(color: textColor.withOpacity(0.5)))]));
                            }
                            return Column(
                              children: reviews.map((doc) {
                                var data = doc.data() as Map<String, dynamic>;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), 
                                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(data['userEmail']?.split('@')[0] ?? "User", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)), Row(children: List.generate(5, (index) => Icon(index < (data['rating'] ?? 0) ? Icons.star : Icons.star_border, color: const Color(0xFFFFC400), size: 14)))]),
                                      const SizedBox(height: 6),
                                      Text(data['comment'] ?? "", style: TextStyle(color: textColor)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 40),
                        if (_redditPosts.isNotEmpty) ...[
                          Row(children: [const Icon(Icons.reddit, color: Color(0xFFFF4500)), const SizedBox(width: 8), Text("details.reddit_title".tr(), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 10),
                          ..._redditPosts.map((post) => Container(
                            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), 
                            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)), 
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(post['name'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)), 
                              const SizedBox(height: 5), 
                              Text("${"details.posted_by".tr()} u/${post['username']}", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)), 
                              if (post['url'] != null) Padding(padding: const EdgeInsets.only(top: 5.0), child: Text(post['url'], style: const TextStyle(color: Colors.blue, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))
                            ]))).toList(),
                        ] else ...[Text("details.reddit_empty".tr(), style: TextStyle(color: textColor.withOpacity(0.5)))],
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}