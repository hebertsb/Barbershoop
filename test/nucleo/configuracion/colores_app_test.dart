import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/nucleo/configuracion/colores_app.dart';

void main() {
  test('ColoresApp expone la paleta dorado/carbon del DESIGN.md', () {
    // Superficies
    expect(ColoresApp.superficie, const Color(0xFF121414));
    expect(ColoresApp.superficieDim, const Color(0xFF121414));
    expect(ColoresApp.superficieBrillante, const Color(0xFF38393A));
    expect(ColoresApp.superficieContenedorMasBaja, const Color(0xFF0C0F0F));
    expect(ColoresApp.superficieContenedorBaja, const Color(0xFF1A1C1C));
    expect(ColoresApp.superficieContenedor, const Color(0xFF1E2020));
    expect(ColoresApp.superficieContenedorAlta, const Color(0xFF282A2B));
    expect(ColoresApp.superficieContenedorMasAlta, const Color(0xFF333535));
    expect(ColoresApp.onSuperficie, const Color(0xFFE2E2E2));
    expect(ColoresApp.onSuperficieVariante, const Color(0xFFD0C5AF));
    expect(ColoresApp.superficieInversa, const Color(0xFFE2E2E2));
    expect(ColoresApp.onSuperficieInversa, const Color(0xFF2F3131));
    expect(ColoresApp.contorno, const Color(0xFF99907C));
    expect(ColoresApp.contornoVariante, const Color(0xFF4D4635));
    expect(ColoresApp.tinteSuperficie, const Color(0xFFE9C349));
    expect(ColoresApp.fondo, const Color(0xFF121414));
    expect(ColoresApp.onFondo, const Color(0xFFE2E2E2));

    // Primario
    expect(ColoresApp.primario, const Color(0xFFF2CA50));
    expect(ColoresApp.onPrimario, const Color(0xFF3C2F00));
    expect(ColoresApp.primarioContenedor, const Color(0xFFD4AF37));
    expect(ColoresApp.onPrimarioContenedor, const Color(0xFF554300));
    expect(ColoresApp.primarioInverso, const Color(0xFF735C00));

    // Secundario
    expect(ColoresApp.secundario, const Color(0xFFC8C6C5));
    expect(ColoresApp.onSecundario, const Color(0xFF313030));
    expect(ColoresApp.secundarioContenedor, const Color(0xFF4A4949));
    expect(ColoresApp.onSecundarioContenedor, const Color(0xFFBAB8B7));

    // Terciario
    expect(ColoresApp.terciario, const Color(0xFFD0CDCD));
    expect(ColoresApp.onTerciario, const Color(0xFF303030));
    expect(ColoresApp.terciarioContenedor, const Color(0xFFB4B2B2));
    expect(ColoresApp.onTerciarioContenedor, const Color(0xFF454544));

    // Error
    expect(ColoresApp.error, const Color(0xFFFFB4AB));
    expect(ColoresApp.onError, const Color(0xFF690005));
    expect(ColoresApp.errorContenedor, const Color(0xFF93000A));
    expect(ColoresApp.onErrorContenedor, const Color(0xFFFFDAD6));

    // Marca / decorativos
    expect(ColoresApp.charcoalProfundo, const Color(0xFF0A0A0A));
    expect(ColoresApp.charcoalOpaco, const Color(0xFF2C2C2C));
    expect(ColoresApp.gradienteDoradoInicio, const Color(0xFFD4AF37));
    expect(ColoresApp.gradienteDoradoFin, const Color(0xFFF1D57A));

    // Estados de cita
    expect(ColoresApp.estadoPendiente, const Color(0xFFFFB100));
    expect(ColoresApp.estadoConfirmada, const Color(0xFFD4AF37));
    expect(ColoresApp.estadoCompletada, const Color(0xFF4CAF50));
    expect(ColoresApp.estadoCancelada, const Color(0xFFE53935));
  });
}
