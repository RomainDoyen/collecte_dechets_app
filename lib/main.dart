import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CollecteDechetsApp());
}

class CollecteDechetsApp extends StatelessWidget {
  const CollecteDechetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🗑️ Collecte Sainte-Rose',
      locale: const Locale('fr', 'FR'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
