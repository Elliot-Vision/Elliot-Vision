import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens.dart';

class AppPalette {
  AppPalette._();

  static const background = Color(0xFF0B0D0A);
  static const surface = Color(0xFF151813);
  static const surfaceRaised = Color(0xFF20251C);
  static const ink = Color(0xFFF2F5ED);
  static const muted = Color(0xFF9EA496);
  static const line = Color(0xFF2A3026);
  static const lime = Color(0xFFC6F432);
  static const limeDark = Color(0xFFB4DF2B);
  static const onAccent = Color(0xFF11140D);
  static const blue = Color(0xFF7C9BFF);
  static const red = Color(0xFFFF6F7D);
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
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppPalette.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppPalette.lime,
            brightness: Brightness.dark,
            primary: AppPalette.lime,
            onPrimary: AppPalette.onAccent,
            surface: AppPalette.surface,
            error: AppPalette.red,
          ),
          canvasColor: AppPalette.surface,
          dividerColor: AppPalette.line,
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: AppPalette.ink,
            displayColor: AppPalette.ink,
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
              borderSide: const BorderSide(
                color: AppPalette.lime,
                width: 1.5,
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.lime,
              foregroundColor: AppPalette.onAccent,
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
