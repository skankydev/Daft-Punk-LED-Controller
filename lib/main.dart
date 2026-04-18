import 'package:flutter/material.dart';

import 'pages/scan_page.dart';

void main() {
  runApp(const DaftPunkApp());
}

class DaftPunkApp extends StatelessWidget {
  const DaftPunkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daft Punk LED',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const ScanPage(),
    );
  }

  ThemeData _buildTheme() {
    const rose = Color(0xFFBF00FF);
    const cyan = Color(0xFF00E5FF);
    const fond = Color(0xFF0A0015);
    const carte = Color(0xFF120020);
    const bordure = Color(0xFF2A0050);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: fond,

      colorScheme: const ColorScheme.dark(
        primary: rose,
        secondary: cyan,
        surface: carte,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D001A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: rose,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 6,
        ),
        iconTheme: IconThemeData(color: cyan),
      ),

      cardTheme: CardThemeData(
        color: carte,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: bordure, width: 1),
        ),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: rose,
        thumbColor: rose,
        inactiveTrackColor: bordure,
        overlayColor: Color(0x22FF2D78),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: rose,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cyan,
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: bordure),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: rose),
        ),
      ),

      dividerColor: bordure,
    );
  }
}
