import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart'; // Localization
import '../services/game_service.dart';
import '../providers/theme_provider.dart'; // Theme Provider
import 'game_comparison_screen.dart'; // Detail screen import

class GamePricesScreen extends StatefulWidget {
  const GamePricesScreen({super.key});

  @override
  State<GamePricesScreen> createState() => _GamePricesScreenState();
}

class _GamePricesScreenState extends State<GamePricesScreen> {
  final GameService _gameService = GameService();
  List<dynamic> _allDeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeals();
  }

  void _fetchDeals() async {
    try {
      // Fetch 60 game deals
      var deals = await _gameService.getGameDeals();
      if (mounted) {
        setState(() {
          _allDeals = deals;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper function to safely get a subset of the list
  List<dynamic> _getSafeSubset(int start, int count) {
    if (_allDeals.length < start) return [];
    int end = start + count;
    if (end > _allDeals.length) end = _allDeals.length;
    return _allDeals.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    // --- THEME PROVIDER ---
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDarkMode;

    // Define colors based on theme
    Color bgColor = isDark ? const Color(0xFF171A21) : const Color(0xFFF5F5F5);
    Color cardColor = isDark ? const Color(0xFF1B2838) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "titles.store".tr(), // Localized title
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                // Categories

                // 1st category (0–9)
                _buildCategorySection("🔥 Stars of the Week", _getSafeSubset(0, 10), textColor, cardColor, subTextColor),

                // 2nd category (10–19)
                _buildCategorySection("⚔️ Action & RPG", _getSafeSubset(10, 10), textColor, cardColor, subTextColor),

                // 3rd category (20–29)
                _buildCategorySection("🏎️ Racing & Sports", _getSafeSubset(20, 10), textColor, cardColor, subTextColor),

                // 4th category (30–39)
                _buildCategorySection("🧟 Horror & Thriller", _getSafeSubset(30, 10), textColor, cardColor, subTextColor),

                // 5th category (40–49)
                _buildCategorySection("💎 Hidden Gems (Indie)", _getSafeSubset(40, 10), textColor, cardColor, subTextColor),

                // 6th category (50–60)
                _buildCategorySection("🎯 Strategy & Simulation", _getSafeSubset(50, 10), textColor, cardColor, subTextColor),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // Category title + horizontal list
  Widget _buildCategorySection(String title, List<dynamic> games, Color textColor, Color cardColor, Color subTextColor) {
    if (games.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(Icons.arrow_forward, color: subTextColor, size: 18),
            ],
          ),
        ),

        // Horizontal scroll list
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: games.length,
            itemBuilder: (context, index) {
              return _buildGameCard(games[index], textColor, cardColor, subTextColor);
            },
          ),
        ),
      ],
    );
  }

  // Game card widget
  Widget _buildGameCard(dynamic game, Color textColor, Color cardColor, Color subTextColor) {
    String title = game['title'] ?? "Game";
    String thumb = game['thumb'] ?? "";
    String salePrice = game['salePrice'] ?? "0";
    String normalPrice = game['normalPrice'] ?? "0";
    String savings = double.parse(game['savings'] ?? "0").toStringAsFixed(0);
    String gameID = game['gameID'];

    return GestureDetector(
      onTap: () {
        // Navigate to detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameComparisonScreen(
              gameID: gameID,
              gameTitle: title,
              thumbUrl: thumb,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                thumb,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 120,
                  color: Colors.grey[800],
                  child: const Icon(Icons.videogame_asset),
                ),
              ),
            ),

            // Info area
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2),
                  ),
                  const SizedBox(height: 8),

                  // Price & discount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Green discount label
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4c6b22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "-$savings%",
                          style: const TextStyle(
                            color: Color(0xFFa4d007),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      // Prices
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "\$$normalPrice",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            "\$$salePrice",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
