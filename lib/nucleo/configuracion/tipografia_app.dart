import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estilos de texto centralizados de BarberApp, mapeados 1:1 a los nombres del
/// DESIGN.md (VISTA/modern_grooming_authority/DESIGN.md).
///
/// Los nombres en inglés (`headlineXl`, `bodyMd`, `labelSm`, etc.) son
/// intencionales: replican el vocabulario del propio DESIGN.md y el de
/// `TextTheme` de Material 3 (`headlineLarge`, `bodyMedium`, `labelSmall`),
/// la misma excepción documentada en `ColoresApp` para sus campos `on*`.
class TipografiaApp {
  TipografiaApp._();

  static TextStyle get headlineXl => GoogleFonts.montserrat(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 48 / 40,
    letterSpacing: -0.02 * 40,
  );

  static TextStyle get headlineLg => GoogleFonts.montserrat(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
  );

  static TextStyle get headlineLgMobile => GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
  );

  static TextStyle get headlineMd => GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  static TextStyle get headlineSm => GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  static TextStyle get bodyLg => GoogleFonts.hankenGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
  );

  static TextStyle get bodyMd => GoogleFonts.hankenGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static TextStyle get bodySm => GoogleFonts.hankenGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static TextStyle get labelMd => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.05 * 12,
  );

  static TextStyle get labelSm => GoogleFonts.jetBrainsMono(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 14 / 10,
    letterSpacing: 0.05 * 10,
  );
}
