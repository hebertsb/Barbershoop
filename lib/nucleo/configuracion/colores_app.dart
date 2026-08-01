import 'package:flutter/material.dart';

/// Paleta de colores centralizada de BarberApp ("Modern Grooming Authority").
/// Fuente: VISTA/modern_grooming_authority/DESIGN.md.
/// Cambiar un color acá lo cambia en toda la app.
///
/// Los campos con prefijo `on` (ej. `onSuperficie`, `onPrimarioContenedor`)
/// mantienen intencionalmente el inglés "on" para reflejar la convención
/// `ColorScheme.onX` de Flutter y facilitar su cableado más adelante; no es
/// un desliz de la convención de idioma en español.
class ColoresApp {
  ColoresApp._();

  // Superficies (modo oscuro, valores exactos del DESIGN.md)
  static const superficie = Color(0xFF121414);
  static const superficieDim = Color(0xFF121414);
  static const superficieBrillante = Color(0xFF38393A);
  static const superficieContenedorMasBaja = Color(0xFF0C0F0F);
  static const superficieContenedorBaja = Color(0xFF1A1C1C);
  static const superficieContenedor = Color(0xFF1E2020);
  static const superficieContenedorAlta = Color(0xFF282A2B);
  static const superficieContenedorMasAlta = Color(0xFF333535);
  static const onSuperficie = Color(0xFFE2E2E2);
  static const onSuperficieVariante = Color(0xFFD0C5AF);
  static const superficieInversa = Color(0xFFE2E2E2);
  static const onSuperficieInversa = Color(0xFF2F3131);
  static const contorno = Color(0xFF99907C);
  static const contornoVariante = Color(0xFF4D4635);
  static const tinteSuperficie = Color(0xFFE9C349);
  static const fondo = Color(0xFF121414);
  static const onFondo = Color(0xFFE2E2E2);

  // Primario (dorado)
  static const primario = Color(0xFFF2CA50);
  static const onPrimario = Color(0xFF3C2F00);
  static const primarioContenedor = Color(0xFFD4AF37);
  static const onPrimarioContenedor = Color(0xFF554300);
  static const primarioInverso = Color(0xFF735C00);

  // Secundario
  static const secundario = Color(0xFFC8C6C5);
  static const onSecundario = Color(0xFF313030);
  static const secundarioContenedor = Color(0xFF4A4949);
  static const onSecundarioContenedor = Color(0xFFBAB8B7);

  // Terciario
  static const terciario = Color(0xFFD0CDCD);
  static const onTerciario = Color(0xFF303030);
  static const terciarioContenedor = Color(0xFFB4B2B2);
  static const onTerciarioContenedor = Color(0xFF454544);

  // Error
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContenedor = Color(0xFF93000A);
  static const onErrorContenedor = Color(0xFFFFDAD6);

  // Marca / decorativos
  static const charcoalProfundo = Color(0xFF0A0A0A);
  static const charcoalOpaco = Color(0xFF2C2C2C);
  static const gradienteDoradoInicio = Color(0xFFD4AF37);
  static const gradienteDoradoFin = Color(0xFFF1D57A);

  // Estados de cita
  static const estadoPendiente = Color(0xFFFFB100);
  static const estadoConfirmada = Color(0xFFD4AF37);
  static const estadoCompletada = Color(0xFF4CAF50);
  static const estadoCancelada = Color(0xFFE53935);
}
