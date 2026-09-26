import 'package:flutter/material.dart';

const green = Color(0xFF234D35);
const canvas = Color(0xFFF8F9F4);
const muted = Color(0xFF747E72);
const lime = Color(0xFFE4EDB5);

ThemeData customerTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: green,
    primary: green,
    surface: canvas,
  ),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: canvas,
    foregroundColor: green,
    elevation: 0,
    centerTitle: false,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      side: const BorderSide(color: green),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    isDense: false,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(17),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: green, width: 2),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDCE2D7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDCE2D7)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE3E7DD), space: 28),
);
