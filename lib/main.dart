import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'l10n/generated/app_localizations.dart';

final _localeNotifier = ValueNotifier<Locale?>(null);

void main() => runApp(
  ValueListenableBuilder<Locale?>(
    valueListenable: _localeNotifier,
    builder: (_, locale, __) => QuantumApp(locale: locale),
  ),
);

class QuantumApp extends StatelessWidget {
  final Locale? locale;
  const QuantumApp({super.key, this.locale});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5E5CE6), // indigo purple apple-like accent
        brightness: Brightness.light,
      ),
      fontFamily: 'SF Pro Text',
      textTheme: Typography.blackMountainView.copyWith().apply(
        displayColor: const Color(0xFF1C1C1E),
        bodyColor: const Color(0xFF1C1C1E),
      ),
    );
    // Dark theme variant
    final darkBase = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5E5CE6),
        brightness: Brightness.dark,
      ),
      fontFamily: 'SF Pro Text',
      textTheme: Typography.whiteMountainView.copyWith().apply(
        displayColor: const Color(0xFFF5F5F7),
        bodyColor: const Color(0xFFF2F2F7),
      ),
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
    );
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      title: 'Quantum Calculator',
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: base.copyWith(
        appBarTheme: base.appBarTheme.copyWith(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF1C1C1E),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: Color(0xFF1C1C1E),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF5E5CE6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x33000000)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF5E5CE6), width: 1.4),
          ),
        ),
        dividerColor: const Color(0xFFE5E5EA),
      ),
      darkTheme: darkBase.copyWith(
        appBarTheme: darkBase.appBarTheme.copyWith(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Color(0xFF2C2C2E),
          surfaceTintColor: Color(0xFF2C2C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        dividerColor: const Color(0xFF3A3A3C),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF5E5CE6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}

/// Public API to change locale.
void setAppLocale(Locale? locale) {
  _localeNotifier.value = locale;
}
