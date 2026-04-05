import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:easy_localization/easy_localization.dart'; 
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:path/path.dart' as path; 

import '../providers/theme_provider.dart';
import '../services/game_service.dart';
import 'details_screen.dart';
import 'new_releases_screen.dart';
import 'search_screen.dart';
import 'news_screen.dart';
import 'login_screen.dart';
import 'game_prices_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService _gameService = GameService();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<dynamic> _allGames = [];
  List<dynamic> _displayedGames = [];
  List<dynamic> _newGames = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;

  File? _profileImage;
  String? _userEmail;

  // Filtreler
  String? _selectedGenre;
  double _minScore = 0;
  int? _selectedYear; // Yıl filtresi değişkeni

  final List<String> _genres = ['Action', 'Adventure', 'RPG', 'Shooter', 'Indie', 'Puzzle', 'Strategy', 'Sports'];
  // Yıl Listesi
  final List<int> _years = [2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _getUserInfo();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoadingMore) {
        _loadMoreGames();
      }
    });
  }

  void _getUserInfo() {
    final user = _auth.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _userEmail = user.email;
        });
        // Kullanıcıya özel resmi yükle
        _loadProfileImage(user.uid);
      }
    }
  }

  // --- 1. KULLANICIYA ÖZEL RESMİ YÜKLE ---
  Future<void> _loadProfileImage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? imagePath = prefs.getString('profile_image_$userId');
      
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          if (mounted) {
            setState(() {
              _profileImage = file;
            });
            await file.lastModified(); 
          }
        } else {
          if (mounted) setState(() => _profileImage = null);
        }
      } else {
        if (mounted) setState(() => _profileImage = null);
      }
    } catch (e) {
      debugPrint("Resim yükleme hatası: $e");
    }
  }

  // --- 2. RESMİ ÇEK VE KULLANICIYA ÖZEL KAYDET ---
  Future<void> _pickImageFromCamera() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      
      if (photo != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String uniqueName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String newPath = path.join(directory.path, uniqueName);
        
        final File newImage = await File(photo.path).copy(newPath);

        if (mounted) {
          setState(() {
            _profileImage = newImage;
          });
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${user.uid}', newPath);
        
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() {}); 
      }
    } catch (e) {
      debugPrint("Kamera hatası: $e");
    }
  }

  // --- 3. BÜYÜTME PENCERESİ ---
  void _showEnlargedImage(BuildContext context) {
    if (_profileImage == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                _profileImage!, 
                fit: BoxFit.cover,
                key: ValueKey(_profileImage!.path), 
              ),
            ),
            const SizedBox(height: 10),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            )
          ],
        ),
      ),
    );
  }

  void _sortGamesByScore(List<dynamic> games) {
    games.sort((a, b) {
      int scoreA = a['metacritic'] ?? ((a['rating'] ?? 0) * 20).round();
      int scoreB = b['metacritic'] ?? ((b['rating'] ?? 0) * 20).round();
      return scoreB.compareTo(scoreA);
    });
  }

  void _fetchData() async {
    try {
      var popular = await _gameService.getPopularGames(page: 1);
      var newReleases = await _gameService.getPopularGames(page: 2);

      _sortGamesByScore(popular);

      if (mounted) {
        setState(() {
          _allGames = popular;
          _displayedGames = popular;
          _newGames = newReleases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadMoreGames() async {
    setState(() => _isLoadingMore = true);
    try {
      int nextPage = _currentPage + 1;
      var newGames = await _gameService.getPopularGames(page: nextPage);

      if (mounted) {
        setState(() {
          _allGames.addAll(newGames);
          _sortGamesByScore(_allGames);
          _currentPage = nextPage;
          _isLoadingMore = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _applyFilters() {
    setState(() {
      var filtered = _allGames.where((game) {
        int score = game['metacritic'] ?? ((game['rating'] ?? 0) * 20).round();
        if (score < _minScore) return false;

        // YIL FİLTRESİ
        if (_selectedYear != null && game['released'] != null) {
          int gameYear = int.parse(game['released'].toString().split('-')[0]);
          if (gameYear != _selectedYear) return false;
        }

        if (_selectedGenre != null && game['genres'] != null) {
          bool hasGenre = (game['genres'] as List).any((g) => g['name'] == _selectedGenre);
          if (!hasGenre) return false;
        }
        return true;
      }).toList();

      _sortGamesByScore(filtered);
      _displayedGames = filtered;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedGenre = null;
      _minScore = 0;
      _selectedYear = null;
      _sortGamesByScore(_allGames);
      _displayedGames = List.from(_allGames);
    });
  }

  void _showFilterModal(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    Color modalColor = isDark ? const Color(0xFF1E1E32) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color accentColor = const Color(0xFF6C63FF);

    showModalBottomSheet(
      context: context,
      backgroundColor: modalColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("titles.search".tr(), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          _resetFilters();
                          Navigator.pop(context);
                        },
                        child: Text("review_dialog.cancel".tr(), style: const TextStyle(color: Colors.redAccent)),
                      )
                    ],
                  ),
                  Divider(color: textColor.withOpacity(0.3)),

                  // --- 1. TÜR (GENRE) ---
                  const Text("Genre", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _genres.map((genre) {
                        bool isSelected = _selectedGenre == genre;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(genre),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() => _selectedGenre = selected ? genre : null);
                            },
                            backgroundColor: isDark ? Colors.black26 : Colors.grey[200],
                            selectedColor: accentColor,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : textColor.withOpacity(0.7)),
                            checkmarkColor: Colors.white,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 2. YIL (RELEASE YEAR) - YENİ EKLENDİ ---
                  const Text("Release Year", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _years.map((year) {
                        bool isSelected = _selectedYear == year;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(year.toString()),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() => _selectedYear = selected ? year : null);
                            },
                            backgroundColor: isDark ? Colors.black26 : Colors.grey[200],
                            selectedColor: accentColor,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : textColor.withOpacity(0.7)),
                            checkmarkColor: Colors.white,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 3. PUAN (MIN SCORE) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Min Score", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text("${_minScore.round()}+", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _minScore,
                    min: 0,
                    max: 95,
                    divisions: 19,
                    activeColor: accentColor,
                    inactiveColor: textColor.withOpacity(0.1),
                    onChanged: (val) => setModalState(() => _minScore = val),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // UYGULA BUTONU
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.iconTheme.color ?? (theme.brightness == Brightness.dark ? Colors.white : Colors.black);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      
      drawer: _buildModernDrawer(bgColor, cardColor, textColor, themeProvider),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilterModal(context),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.filter_list, color: Colors.white),
      ),
      
      appBar: AppBar(
        centerTitle: true,
        title: Text("titles.app_name".tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 20)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NewsScreen())), icon: Icon(Icons.newspaper, color: textColor)),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())), icon: Icon(Icons.search, color: textColor)),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GamePricesScreen())), icon: Icon(Icons.shopping_bag_outlined, color: textColor)),
          const SizedBox(width: 10),
        ],
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 100, bottom: 80), 
              itemCount: _displayedGames.length + 1 + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) return _buildHorizontalNewReleases(textColor);
                if (index == _displayedGames.length + 1) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Colors.grey)));
                
                final game = _displayedGames[index - 1];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(game: game))),
                  child: _buildCinematicCard(game, cardColor, textColor),
                );
              },
            ),
    );
  }

  Widget _buildHorizontalNewReleases(Color textColor) {
    if (_newGames.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("home.banner_title".tr(), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NewReleasesScreen())),
                child: Text("home.see_all".tr(), style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: _newGames.length,
            itemBuilder: (context, index) {
              final game = _newGames[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(game: game))),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(image: NetworkImage(game['background_image'] ?? ""), fit: BoxFit.cover),
                  ),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)])),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(8),
                    child: Text(game['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCinematicCard(dynamic game, Color cardColor, Color textColor) {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
        color: cardColor, 
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: game['name'].toString(), 
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  game['background_image'] ?? "",
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(color: Colors.grey),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent, 
                  Colors.black.withOpacity(0.1), 
                  Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9)
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),
          Positioned(top: 15, right: 15, child: _buildBlurryBadge(game)),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(6)), child: Text("home.featured_badge".tr(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    if (game['released'] != null) Text(game['released'].toString().split("-")[0], style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: Text(game['name'], style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 6),
                Row(children: [Text("Tap for details", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)), const SizedBox(width: 4), Icon(Icons.arrow_forward, color: textColor.withOpacity(0.7), size: 12)]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurryBadge(dynamic game) {
    int score = 0;
    if (game['metacritic'] != null) {
      score = game['metacritic'];
    } else if (game['rating'] != null) {
      score = ((game['rating'] as num) * 20).round();
    }
    if (score == 0) return const SizedBox();
    Color color = score >= 75 ? Colors.greenAccent : (score >= 50 ? Colors.amberAccent : Colors.redAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(score.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildModernDrawer(Color bgColor, Color cardColor, Color textColor, ThemeProvider themeProvider) {
    return Drawer(
      backgroundColor: bgColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgColor, const Color(0xFF6C63FF).withOpacity(0.5)],
              ),
            ),
            accountName: Text("auth.welcome_user".tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
            accountEmail: Text(_userEmail ?? "Guest", style: TextStyle(color: textColor.withOpacity(0.7))),
            
            // --- PROFİL FOTOSU (Stack) ---
            currentAccountPicture: GestureDetector(
              onTap: () {
                 if (_profileImage != null) {
                   _showEnlargedImage(context);
                 } else {
                   _pickImageFromCamera();
                 }
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      border: Border.all(color: textColor, width: 2),
                      image: _profileImage != null 
                        ? DecorationImage(
                            image: FileImage(_profileImage!), 
                            fit: BoxFit.cover
                          )
                        : null
                    ),
                    child: _profileImage == null 
                        ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey) 
                        : null,
                  ),
                  
                  GestureDetector(
                    onTap: _pickImageFromCamera,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          _buildDrawerItem(Icons.home_filled, "titles.home".tr(), () => Navigator.pop(context), textColor),
          _buildDrawerItem(Icons.local_fire_department, "titles.new_releases".tr(), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const NewReleasesScreen())); }, textColor),
          _buildDrawerItem(Icons.search, "titles.search".tr(), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())); }, textColor),
          _buildDrawerItem(Icons.newspaper, "titles.news".tr(), () { 
            Navigator.pop(context); 
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NewsScreen())); 
          }, textColor),
          Divider(color: textColor.withOpacity(0.3)),
          
          ListTile(
            leading: Icon(Icons.language, color: textColor.withOpacity(0.7)),
            title: Text("settings.language".tr(), style: TextStyle(color: textColor)),
            trailing: DropdownButton<String>(
              value: context.locale.languageCode,
              dropdownColor: cardColor,
              underline: Container(),
              icon: Icon(Icons.arrow_drop_down, color: textColor.withOpacity(0.7)),
              style: TextStyle(color: textColor),
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
          ),
          
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: textColor.withOpacity(0.7)), 
            title: Text("settings.dark_mode".tr(), style: TextStyle(color: textColor)), 
            activeColor: const Color(0xFF6C63FF), 
            value: themeProvider.isDarkMode, 
            onChanged: (bool value) {
               themeProvider.toggleTheme(); 
            }, 
          ),
          
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0), 
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _profileImage = null);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              }, 
              icon: const Icon(Icons.logout, color: Colors.redAccent), 
              label: Text("auth.logout".tr(), style: const TextStyle(color: Colors.redAccent)), 
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent))
            )
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, Color color) {
    return ListTile(
      leading: Icon(icon, color: color.withOpacity(0.7)), 
      title: Text(title, style: TextStyle(color: color)), 
      onTap: onTap
    );
  }
}