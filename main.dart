import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(ElliottVisionApp(store: store));
}

class ElliottVisionApp extends StatelessWidget {
  const ElliottVisionApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111111);
    return MaterialApp(
      title: 'Elliott Vision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F8F6),
        colorScheme: ColorScheme.fromSeed(seedColor: ink, brightness: Brightness.light),
        fontFamily: 'sans',
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF8F8F6), elevation: 0, scrolledUnderElevation: 0),
        cardTheme: const CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))),
        navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: Color(0xFFE9E9E5), height: 72),
        inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(16)))),
      ),
      home: HomeScreen(store: store),
    );
  }
}
