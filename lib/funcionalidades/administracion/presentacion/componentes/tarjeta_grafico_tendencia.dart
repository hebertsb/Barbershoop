import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_punto_tendencia.dart';
import '../controladores/controlador_tendencia_ingresos.dart';

const _diasCortos = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
const _mesesCortos = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

/// Un tick de la etiqueta del eje X: texto real (derivado de la fecha
/// devuelta por el RPC) y si va destacado (dorado/negrita), igual que el
/// tratamiento que ya tenía "Hoy" en el último punto.
class _EtiquetaEje {
  const _EtiquetaEje(this.texto, this.destacado);
  final String texto;
  final bool destacado;
}

/// Elige hasta [cantidad] índices espaciados entre 0 y n-1 (siempre incluye
/// el primero y el último) para no superponer etiquetas cuando hay muchos
/// puntos (ej. hasta 31 días en el período "mes").
List<int> _indicesEspaciados(int n, int cantidad) {
  if (n <= cantidad) return List.generate(n, (i) => i);
  final indices = <int>{};
  for (var i = 0; i < cantidad; i++) {
    indices.add(((n - 1) * i / (cantidad - 1)).round());
  }
  return indices.toList()..sort();
}

/// Tarjeta de Tendencia de Ingresos con filtros S/M/A: consume
/// `controladorTendenciaIngresosProvider` (datos reales de
/// `obtener_tendencia_ingresos`, 0053) en vez de series hardcodeadas.
class TarjetaGraficoTendencia extends ConsumerStatefulWidget {
  const TarjetaGraficoTendencia({super.key});

  @override
  ConsumerState<TarjetaGraficoTendencia> createState() =>
      _TarjetaGraficoTendenciaState();
}

class _TarjetaGraficoTendenciaState
    extends ConsumerState<TarjetaGraficoTendencia> {
  // S = Semana, M = Mes, A = Año
  String _periodoActivo = 'M';

  String get _periodoReal => switch (_periodoActivo) {
    'S' => 'semana',
    'M' => 'mes',
    _ => 'anio',
  };

  List<_EtiquetaEje> _construirEtiquetas(List<ModeloPuntoTendencia> puntos) {
    final n = puntos.length;
    if (n == 0) return [];

    if (_periodoActivo == 'S') {
      return List.generate(n, (i) {
        if (i == n - 1) return const _EtiquetaEje('Hoy', true);
        final fecha = puntos[i].fecha;
        return _EtiquetaEje(_diasCortos[fecha.weekday % 7], false);
      });
    }

    if (_periodoActivo == 'M') {
      final indices = _indicesEspaciados(n, 4);
      return indices.map((i) {
        final esUltimo = i == n - 1;
        final texto = esUltimo ? 'Hoy' : '${puntos[i].fecha.day}';
        return _EtiquetaEje(texto, esUltimo);
      }).toList();
    }

    // 'A' (año): nombre corto de mes; si hay muchos puntos, espaciar.
    final indices = _indicesEspaciados(n, 5);
    return indices.map((i) {
      final esUltimo = i == n - 1;
      final texto = _mesesCortos[puntos[i].fecha.month - 1];
      return _EtiquetaEje(texto, esUltimo);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final estado = ref.watch(controladorTendenciaIngresosProvider(_periodoReal));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tendencia de Ingresos',
                  style: TipografiaApp.headlineSm.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  _BadgeFiltroGrafico(
                    texto: 'S',
                    activo: _periodoActivo == 'S',
                    onTap: () => setState(() => _periodoActivo = 'S'),
                  ),
                  const SizedBox(width: 4),
                  _BadgeFiltroGrafico(
                    texto: 'M',
                    activo: _periodoActivo == 'M',
                    onTap: () => setState(() => _periodoActivo = 'M'),
                  ),
                  const SizedBox(width: 4),
                  _BadgeFiltroGrafico(
                    texto: 'A',
                    activo: _periodoActivo == 'A',
                    onTap: () => setState(() => _periodoActivo = 'A'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          estado.when(
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, s) => SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'No se pudo cargar la tendencia de ingresos.',
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
            data: (puntos) {
              final montos = puntos.map((p) => p.monto).toList();
              final maxMonto = montos.isEmpty
                  ? 0.0
                  : montos.reduce((a, b) => a > b ? a : b);
              final sinDatos = puntos.isEmpty || maxMonto <= 0;

              if (sinDatos) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'Sin ingresos registrados en este período.',
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              final normalizados = montos.map((m) => m / maxMonto).toList();
              final etiquetas = _construirEtiquetas(puntos);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _PintorGraficoTendencia(
                        colorLinea: ColoresApp.primario,
                        puntosNormalizados: normalizados,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: etiquetas
                        .map(
                          (etiq) => Text(
                            etiq.texto,
                            style: TipografiaApp.labelSm.copyWith(
                              color: etiq.destacado
                                  ? ColoresApp.primario
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: etiq.destacado
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BadgeFiltroGrafico extends StatelessWidget {
  const _BadgeFiltroGrafico({
    required this.texto,
    required this.activo,
    this.onTap,
  });
  final String texto;
  final bool activo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: activo
              ? ColoresApp.primario.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: activo ? ColoresApp.primario : Colors.white24,
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: activo ? ColoresApp.primario : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _PintorGraficoTendencia extends CustomPainter {
  _PintorGraficoTendencia({
    required this.colorLinea,
    required this.puntosNormalizados,
  });
  final Color colorLinea;

  /// Lista de valores normalizados (0.0 = arriba, 1.0 = abajo) para cada punto
  final List<double> puntosNormalizados;

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = colorLinea
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final n = puntosNormalizados.length;
    final path = Path();
    final points = List.generate(
      n,
      (i) => Offset(
        n == 1 ? 0 : size.width * i / (n - 1),
        size.height * (1.0 - puntosNormalizados[i]) * 0.85 + (size.height * 0.08),
      ),
    );

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Dibujar sombra bajo la línea
    final pathGradient = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paintGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorLinea.withValues(alpha: 0.3),
          colorLinea.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(pathGradient, paintGradient);
    canvas.drawPath(path, paintLine);

    // Dibujar punto brillante al final
    final paintDot = Paint()..color = colorLinea;
    canvas.drawCircle(points.last, 5, paintDot);
  }

  @override
  bool shouldRepaint(covariant _PintorGraficoTendencia oldDelegate) =>
      oldDelegate.puntosNormalizados != puntosNormalizados ||
      oldDelegate.colorLinea != colorLinea;
}