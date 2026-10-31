import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color seed = Color(0xFF2E9E8F);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        appBarTheme: const AppBarTheme(centerTitle: true),
      );
}
