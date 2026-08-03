import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Colores de estado de cita (pendiente/confirmada/completada/cancelada) y el
/// gradiente dorado de marca. No forman parte del ColorScheme estandar de
/// Material, así que viajan como ThemeExtension para cambiar solos entre
/// modo claro/oscuro: `Theme.of(context).extension<ColoresEstadoApp>()!`.
@immutable
class ColoresEstadoApp extends ThemeExtension<ColoresEstadoApp> {
  const ColoresEstadoApp({
    required this.pendiente,
    required this.confirmada,
    required this.completada,
    required this.cancelada,
    required this.gradienteInicio,
    required this.gradienteFin,
  });

  final Color pendiente;
  final Color confirmada;
  final Color completada;
  final Color cancelada;
  final Color gradienteInicio;
  final Color gradienteFin;

  /// Valores fijos del design system, usados por [TemaApp] en ambos modos
  /// (claro/oscuro): los colores de estado son semanticos y no cambian
  /// segun la superficie de fondo.
  static const valoresDesignSystem = ColoresEstadoApp(
    pendiente: ColoresApp.estadoPendiente,
    confirmada: ColoresApp.estadoConfirmada,
    completada: ColoresApp.estadoCompletada,
    cancelada: ColoresApp.estadoCancelada,
    gradienteInicio: ColoresApp.gradienteDoradoInicio,
    gradienteFin: ColoresApp.gradienteDoradoFin,
  );

  @override
  ColoresEstadoApp copyWith({
    Color? pendiente,
    Color? confirmada,
    Color? completada,
    Color? cancelada,
    Color? gradienteInicio,
    Color? gradienteFin,
  }) {
    return ColoresEstadoApp(
      pendiente: pendiente ?? this.pendiente,
      confirmada: confirmada ?? this.confirmada,
      completada: completada ?? this.completada,
      cancelada: cancelada ?? this.cancelada,
      gradienteInicio: gradienteInicio ?? this.gradienteInicio,
      gradienteFin: gradienteFin ?? this.gradienteFin,
    );
  }

  @override
  ColoresEstadoApp lerp(ThemeExtension<ColoresEstadoApp>? other, double t) {
    if (other is! ColoresEstadoApp) return this;
    return ColoresEstadoApp(
      pendiente: Color.lerp(pendiente, other.pendiente, t)!,
      confirmada: Color.lerp(confirmada, other.confirmada, t)!,
      completada: Color.lerp(completada, other.completada, t)!,
      cancelada: Color.lerp(cancelada, other.cancelada, t)!,
      gradienteInicio: Color.lerp(gradienteInicio, other.gradienteInicio, t)!,
      gradienteFin: Color.lerp(gradienteFin, other.gradienteFin, t)!,
    );
  }
}