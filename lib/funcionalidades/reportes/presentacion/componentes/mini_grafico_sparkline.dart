import 'package:flutter/material.dart';

/// Mini-gráfico de línea (sparkline) sin ejes ni etiquetas, pensado para
/// vivir debajo del valor de una tarjeta KPI (~30-40px de alto).
///
/// Mismo criterio visual y de normalización que `_PintorGraficoTendencia`
/// (`administracion/presentacion/componentes/tarjeta_grafico_tendencia.dart`):
/// línea con sombra de gradiente y punto final destacado, adaptado a un
/// tamaño chico y sin badges de filtro ni etiquetas de eje.
class MiniGraficoSparkline extends StatelessWidget {
  const MiniGraficoSparkline({
    super.key,
    required this.valores,
    required this.color,
    this.altura = 36,
  });

  /// Valores reales (sin normalizar, ej. montos en bolivianos); se
  /// normalizan internamente 0.0-1.0 con el máximo de la lista.
  final List<double> valores;
  final Color color;
  final double altura;

  @override
  Widget build(BuildContext context) {
    if (valores.length < 2) return const SizedBox.shrink();

    final maxValor = valores.reduce((a, b) => a > b ? a : b);
    if (maxValor <= 0) return const SizedBox.shrink();

    final normalizados = valores.map((v) => v / maxValor).toList();

    return SizedBox(
      height: altura,
      width: double.infinity,
      child: CustomPaint(
        painter: _PintorSparkline(
          color: color,
          puntosNormalizados: normalizados,
        ),
      ),
    );
  }
}

class _PintorSparkline extends CustomPainter {
  _PintorSparkline({required this.color, required this.puntosNormalizados});

  final Color color;

  /// Lista de valores normalizados (0.0 = arriba, 1.0 = abajo), mismo
  /// criterio que `_PintorGraficoTendencia`.
  final List<double> puntosNormalizados;

  @override
  void paint(Canvas canvas, Size size) {
    final paintLinea = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final n = puntosNormalizados.length;
    final path = Path();
    final puntos = List.generate(
      n,
      (i) => Offset(
        n == 1 ? 0 : size.width * i / (n - 1),
        size.height * puntosNormalizados[i],
      ),
    );

    path.moveTo(puntos[0].dx, puntos[0].dy);
    for (var i = 1; i < puntos.length; i++) {
      path.lineTo(puntos[i].dx, puntos[i].dy);
    }

    // Sombra de gradiente bajo la línea, igual criterio que el gráfico grande.
    final pathGradiente = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paintGradiente = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(pathGradiente, paintGradiente);
    canvas.drawPath(path, paintLinea);

    final paintPunto = Paint()..color = color;
    canvas.drawCircle(puntos.last, 2.5, paintPunto);
  }

  @override
  bool shouldRepaint(covariant _PintorSparkline oldDelegate) =>
      oldDelegate.puntosNormalizados != puntosNormalizados ||
      oldDelegate.color != color;
}