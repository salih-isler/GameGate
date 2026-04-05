// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/game_service.dart';
import 'details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GameService _gameService = GameService();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    // Debounce: Sürekli istek atmayı önler
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) _performSearch(query);
      else setState(() => _searchResults = []);
    });
  }

  void _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      var results = await _gameService.searchGames(query);
      if (mounted) setState(() { _searchResults = results; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Search for games... (e.g. Valorant)",
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Color(0xFF6C63FF)),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: _onSearchChanged,
            autofocus: true,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.manage_search, size: 100, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 20),
                      const Text("Start typing to search", style: TextStyle(color: Colors.white38, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final game = _searchResults[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(game: game))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E32),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: game['background_image'] != null
                                ? Image.network(game['background_image'], width: 50, height: 50, fit: BoxFit.cover)
                                : Container(width: 50, height: 50, color: Colors.grey),
                          ),
                          title: Text(game['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}