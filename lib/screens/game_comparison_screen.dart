import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // URL Launcher
import '../services/game_service.dart';

class GameComparisonScreen extends StatefulWidget {
  final String gameID;
  final String gameTitle;
  final String thumbUrl;

  const GameComparisonScreen({
    super.key,
    required this.gameID,
    required this.gameTitle,
    required this.thumbUrl,
  });

  @override
  State<GameComparisonScreen> createState() => _GameComparisonScreenState();
}

class _GameComparisonScreenState extends State<GameComparisonScreen> {
  final GameService _gameService = GameService();
  
  List<dynamic> _stores = []; // Mağaza isimleri
  List<dynamic> _deals = [];  // Fiyatlar
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    try {
      // 1. Mağaza İsimlerini Çek
      final stores = await _gameService.getStores();
      
      // 2. Oyunun Fiyatlarını Çek
      final gameDetails = await _gameService.getGameDetailsToPrice(widget.gameID);
      
      if (mounted) {
        setState(() {
          _stores = stores;
          _deals = gameDetails['deals']; 
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Hata: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Store ID -> İsim
  String getStoreName(String storeID) {
    final store = _stores.firstWhere((s) => s['storeID'] == storeID, orElse: () => null);
    return store != null ? store['storeName'] : "Mağaza";
  }

  // Store ID -> Logo URL
  String getStoreLogo(String storeID) {
    final store = _stores.firstWhere((s) => s['storeID'] == storeID, orElse: () => null);
    return store != null ? "https://www.cheapshark.com${store['images']['logo']}" : "";
  }

  // URL Açma Fonksiyonu
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Could not launch $url"), backgroundColor: Colors.red),
         );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171A21),
      appBar: AppBar(
        title: Text(widget.gameTitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF171A21),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              children: [
                // --- Üst Kısım: Oyun Resmi ---
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.thumbUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "En İyi Fiyatlar",
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 28, 
                            fontWeight: FontWeight.bold, 
                            shadows: [Shadow(blurRadius: 10, color: Colors.black)]
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Mağazaya gitmek için listeye tıklayın",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        )
                      ],
                    ),
                  ),
                ),

                // --- Alt Kısım: Fiyat Listesi ---
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deals.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final deal = _deals[index];
                      
                      // Gerekli Veriler
                      final storeName = getStoreName(deal['storeID']);
                      final iconUrl = getStoreLogo(deal['storeID']);
                      final price = deal['price'];
                      final retailPrice = deal['retailPrice'];
                      
                      // Yönlendirme Linki Oluşturma
                      final dealID = deal['dealID'];
                      final redirectUrl = "https://www.cheapshark.com/redirect?dealID=$dealID";

                      return GestureDetector(
                        // TIKLANINCA TARAYICIDA AÇ
                        onTap: () => _launchURL(redirectUrl),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2838),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0,2))]
                          ),
                          child: Row(
                            children: [
                              // 1. Logo
                              if (iconUrl.isNotEmpty)
                                Image.network(iconUrl, width: 32, height: 32)
                              else
                                const Icon(Icons.store, color: Colors.white),
                              
                              const SizedBox(width: 15),

                              // 2. Mağaza Adı
                              Expanded(
                                child: Text(
                                  storeName,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ),

                              // 3. Fiyatlar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (retailPrice != null && retailPrice != price)
                                    Text(
                                      "\$$retailPrice",
                                      style: const TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.lineThrough),
                                    ),
                                  Text(
                                    "\$$price",
                                    style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(width: 15),
                              
                              // 4. Dış Link İkonu
                              const Icon(Icons.open_in_new, color: Colors.blueGrey, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}