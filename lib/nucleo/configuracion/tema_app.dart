import 'package:flutter/material.dart';

import 'colores_app.dart';
import 'colores_estado_app.dart';
import 'tipografia_app.dart';

class TemaApp {
  TemaApp._();

  // Memoizados por color de acento: `_construir` arma un TextTheme entero vía
  // GoogleFonts, costoso de recomputar en cada rebuild de MaterialApp.router
  // (ej. cada vez que cambia el estado de un provider no relacionado). Antes
  // de parametrizar el color, `oscuro`/`claro` eran `static final` (se
  // computaban una sola vez); esta caché preserva ese mismo comportamiento
  // "una vez por variante" ahora que son métodos. `Color` implementa
  // `==`/`hashCode` por valor, así que sirve tal cual como key de mapa
  // (incluida la key `null` = color por defecto).
  static final Map<Color?, ThemeData> _cacheOscuro = {};
  static final Map<Color?, ThemeData> _cacheClaro = {};

  /// Tema oscuro. Sin [colorSemilla] (o con el dorado por defecto,
  /// [ColoresApp.primario]) usa el `ColorScheme` armado a mano con los
  /// valores exactos del DESIGN.md, para no cambiar el look default de la
  /// app. Con un [colorSemilla] custom (ajustes de marca de una barbería) se
  /// deriva un `ColorScheme` oscuro a partir de ese color con
  /// `ColorScheme.fromSeed`, en vez de mantener la paleta manual completa.
  static ThemeData oscuro({Color? colorSemilla}) {
    return _cacheOscuro.putIfAbsent(
      colorSemilla,
      () => _oscuroSinCache(colorSemilla),
    );
  }

  static ThemeData _oscuroSinCache(Color? colorSemilla) {
    final esColorPorDefecto =
        colorSemilla == null || colorSemilla == ColoresApp.primario;
    final colorScheme = esColorPorDefecto
        ? const ColorScheme(
            brightness: Brightness.dark,
            primary: ColoresApp.primario,
            onPrimary: ColoresApp.onPrimario,
            primaryContainer: ColoresApp.primarioContenedor,
            onPrimaryContainer: ColoresApp.onPrimarioContenedor,
            secondary: ColoresApp.secundario,
            onSecondary: ColoresApp.onSecundario,
            secondaryContainer: ColoresApp.secundarioContenedor,
            onSecondaryContainer: ColoresApp.onSecundarioContenedor,
            tertiary: ColoresApp.terciario,
            onTertiary: ColoresApp.onTerciario,
            tertiaryContainer: ColoresApp.terciarioContenedor,
            onTertiaryContainer: ColoresApp.onTerciarioContenedor,
            error: ColoresApp.error,
            onError: ColoresApp.onError,
            errorContainer: ColoresApp.errorContenedor,
            onErrorContainer: ColoresApp.onErrorContenedor,
            surface: ColoresApp.superficie,
            onSurface: ColoresApp.onSuperficie,
            onSurfaceVariant: ColoresApp.onSuperficieVariante,
            outline: ColoresApp.contorno,
            outlineVariant: ColoresApp.contornoVariante,
            shadow: Colors.black,
            scrim: Colors.black,
            inverseSurface: ColoresApp.superficieInversa,
            onInverseSurface: ColoresApp.onSuperficieInversa,
            inversePrimary: ColoresApp.primarioInverso,
            surfaceTint: ColoresApp.tinteSuperficie,
            surfaceDim: ColoresApp.superficieDim,
            surfaceBright: ColoresApp.superficieBrillante,
            surfaceContainerLowest: ColoresApp.superficieContenedorMasBaja,
            surfaceContainerLow: ColoresApp.superficieContenedorBaja,
            surfaceContainer: ColoresApp.superficieContenedor,
            surfaceContainerHigh: ColoresApp.superficieContenedorAlta,
            surfaceContainerHighest: ColoresApp.superficieContenedorMasAlta,
          )
        : ColorScheme.fromSeed(
            seedColor: colorSemilla,
            brightness: Brightness.dark,
          );

    return _construir(
      colorScheme,
      coloresEstado: ColoresEstadoApp.valoresDesignSystem,
    );
  }

  /// Tema claro: siempre `ColorScheme.fromSeed`, con [colorSemilla] (ajustes
  /// de marca de una barbería) o con el dorado por defecto
  /// ([ColoresApp.primario]) cuando es `null`.
  static ThemeData claro({Color? colorSemilla}) {
    return _cacheClaro.putIfAbsent(
      colorSemilla,
      () => _construir(
        ColorScheme.fromSeed(
          seedColor: colorSemilla ?? ColoresApp.primario,
          brightness: Brightness.light,
        ),
        // El DESIGN.md no define una variante clara para los estados de
        // cita; se reutilizan los mismos valores (son semanticos, no
        // dependen de la superficie de fondo).
        coloresEstado: ColoresEstadoApp.valoresDesignSystem,
      ),
    );
  }

  static ThemeData _construir(
    ColorScheme colorScheme, {
    required ColoresEstadoApp coloresEstado,
  }) {
    final textTheme = TextTheme(
      displayLarge: TipografiaApp.headlineXl.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineLarge: TipografiaApp.headlineLg.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineMedium: TipografiaApp.headlineMd.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineSmall: TipografiaApp.headlineSm.copyWith(
        color: colorScheme.onSurface,
      ),
      bodyLarge: TipografiaApp.bodyLg.copyWith(color: colorScheme.onSurface),
      bodyMedium: TipografiaApp.bodyMd.copyWith(color: colorScheme.onSurface),
      bodySmall: TipografiaApp.bodySm.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: TipografiaApp.labelMd.copyWith(color: colorScheme.onSurface),
      labelMedium: TipografiaApp.labelMd.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: TipografiaApp.labelSm.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarThemeData(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: TipografiaApp.headlineSm.copyWith(
          color: colorScheme.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: TipografiaApp.labelMd,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          textStyle: TipografiaApp.labelMd,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          textStyle: TipografiaApp.labelMd,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        labelStyle: TipografiaApp.labelSm.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      extensions: [coloresEstado],
    );
  }
}
