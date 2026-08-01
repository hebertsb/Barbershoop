import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';

/// Tarjeta compacta de un KPI del dashboard de reportes: título, valor
/// grande, ícono, y opcionalmente un subtítulo o una mini-tendencia
/// (sparkline) de los últimos puntos.
class TarjetaKpiReporte extends StatelessWidget {
  const TarjetaKpiReporte({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.colorIcono,
    this.subtitulo,
    this.sparklineData,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color colorIcono;
  final String? subtitulo;
  final List<double>? sparklineData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: colorIcono, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: TipografiaApp.bodySm.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              valor,
              style: TipografiaApp.headlineSm.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitulo!,
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (sparklineData != null && sparklineData!.length > 1) ...[
              const SizedBox(height: 4),
              SizedBox(
                height: 20,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _PintorSparkline(sparklineData!, colorIcono),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PintorSparkline extends CustomPainter {
  _PintorSparkline(this.datos, this.color);

  final List<double> datos;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final maximo = datos.reduce((a, b) => a > b ? a : b);
    final minimo = datos.reduce((a, b) => a < b ? a : b);
    final rango = (maximo - minimo).abs() < 0.0001 ? 1 : maximo - minimo;

    final paso = size.width / (datos.length - 1);
    final path = Path();
    for (var i = 0; i < datos.length; i++) {
      final x = i * paso;
      final normalizado = (datos[i] - minimo) / rango;
      final y = size.height - (normalizado * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorSparkline oldDelegate) =>
      oldDelegate.datos != datos || oldDelegate.color != color;
}
