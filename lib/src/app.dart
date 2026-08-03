import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens.dart';

class AppPalette {
  AppPalette._();

  static const background = Color(0xFFF4F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF11120F);
  static const muted = Color(0xFF6D7068);
  static const line = Color(0xFFE2E4DD);
  static const lime = Color(0xFFC6F432);
  static const limeDark = Color(0xFF546D00);
  static const blue = Color(0xFF4F7CFF);
  static const red = Color(0xFFE84D5B);
}

class ElliottVisionApp extends StatelessWidget {
  const ElliottVisionApp({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: MaterialApp(
        title: 'Elliott Vision',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppPalette.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppPalette.lime,
            brightness: Brightness.light,
            primary: AppPalette.ink,
            surface: AppPalette.surface,
            error: AppPalette.red,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppPalette.background,
            foregroundColor: AppPalette.ink,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: AppPalette.surface,
            indicatorColor: AppPalette.lime,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppPalette.surface,
            hintStyle: const TextStyle(color: AppPalette.muted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppPalette.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppPalette.ink, width: 1.5),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.ink,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required AppState notifier, required Widget child, Key? key})
    : super(key: key, notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope fehlt im Widget-Baum.');
    return scope!.notifier!;
  }
}
