import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart'; // Provider paketi
import 'providers/theme_provider.dart'; // Az önce oluşturduğumuz dosya
import 'screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider( // PROVIDER SARMALAYICISI
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider'ı dinliyoruz
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GameGate',
      
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Provider'dan gelen veriye göre tema
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
      ),
      
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardColor: const Color(0xFF1E1E32),
        appBarTheme: AppBarTheme(backgroundColor: Colors.black.withOpacity(0.6), foregroundColor: Colors.white),
      ),
      
      home: const LoginScreen(),
    );
  }
}