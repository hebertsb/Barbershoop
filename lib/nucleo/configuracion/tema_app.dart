import 'package:flutter/material.dart';

class TemaApp {
  TemaApp._();

  static ThemeData get claro => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      );
}
