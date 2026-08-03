import 'package:flutter/material.dart';

/// Configuración de marca visual de la barbería:
/// nombre, slogan, logo y color de acento.
class ModeloMarcaBarberia {
  const ModeloMarcaBarberia({
    this.nombre = 'BarberApp',
    this.slogan,
    this.logoUrl,
    this.colorAcento,
    this.colorAcentoHex,
  });

  final String nombre;
  final String? slogan;

  // El logo se guarda como 'logo_url' en la BD.
  final String? logoUrl;

  // colorAcento como Color (para uso en widgets).
  final Color? colorAcento;

  // colorAcentoHex como string hexadecimal, ej: '#F2CA50'.
  final String? colorAcentoHex;

  // ── Getters alias ──────────────────────────────────────────────────────

  /// Alias de [logoUrl].
  String? get urlLogo => logoUrl;

  factory ModeloMarcaBarberia.desdeJson(Map<String, dynamic> json) {
    final hexStr =
        (json['color_acento'] ?? json['color_acento_hex']) as String?;
    Color? color;
    String? hexFinal;
    if (hexStr != null && hexStr.isNotEmpty) {
      hexFinal = hexStr.startsWith('#') ? hexStr : '#$hexStr';
      final val = int.tryParse(hexStr.replaceFirst('#', ''), radix: 16);
      if (val != null) {
        color = Color(val < 0xFF000000 ? (0xFF000000 | val) : val);
      }
    }
    return ModeloMarcaBarberia(
      nombre:
          json['nombre_barberia'] as String? ??
          json['nombre'] as String? ??
          'BarberApp',
      slogan: json['slogan'] as String?,
      logoUrl: (json['logo_url'] ?? json['url_logo']) as String?,
      colorAcento: color,
      colorAcentoHex: hexFinal,
    );
  }

  Map<String, dynamic> aJson() {
    final hex =
        colorAcentoHex ??
        (colorAcento != null
            ? '#${colorAcento!.value.toRadixString(16).padLeft(8, '0').substring(2)}'
            : null);
    return {
      'nombre_barberia': nombre,
      'slogan': slogan,
      'logo_url': logoUrl,
      'color_acento': hex,
    };
  }

  ModeloMarcaBarberia copyWith({
    String? nombre,
    String? slogan,
    String? logoUrl,
    Color? colorAcento,
    String? colorAcentoHex,
  }) {
    return ModeloMarcaBarberia(
      nombre: nombre ?? this.nombre,
      slogan: slogan ?? this.slogan,
      logoUrl: logoUrl ?? this.logoUrl,
      colorAcento: colorAcento ?? this.colorAcento,
      colorAcentoHex: colorAcentoHex ?? this.colorAcentoHex,
    );
  }
}
