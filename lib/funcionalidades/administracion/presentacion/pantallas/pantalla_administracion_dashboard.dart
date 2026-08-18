import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_moneda.dart';
import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../../inventario/presentacion/controladores/controlador_alerta_stock.dart';
import '../../datos/repositorio_accesos_admin.dart';
import '../../dominio/catalogo_accesos_admin.dart';
import '../componentes/tarjeta_grafico_tendencia.dart';
import '../controladores/controlador_acceso_rapido_admin.dart';
import '../controladores/controlador_barberos.dart';
import '../controladores/controlador_dashboard.dart';

/// Calcula el % de cambio de ingresos hoy vs. ayer, formateado con signo.
/// Guard de división por cero (`ayer == 0`): si además hoy > 0 es un
/// arranque desde cero real, se muestra "+100%"; si ambos son 0 no hay
/// cambio que mostrar, "0%".
String _calcularPorcentajeCambio(double hoy, double ayer) {
  if (ayer == 0) {
    return hoy > 0 ? '+100%' : '0%';
  }
  final cambio = ((hoy - ayer) / ayer * 100).round();
  return '${cambio >= 0 ? '+' : ''}$cambio%';
}

/// Diferencia real de citas hoy vs. ayer, formateada con signo (ej. '+3',
/// '-2', '0').
String _calcularDiferenciaCitas(int hoy, int ayer) {
  final diferencia = hoy - ayer;
  return '${diferencia > 0 ? '+' : ''}$diferencia';
}

class PantallaAdministracionDashboard extends ConsumerWidget {
  const PantallaAdministracionDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(controladorAutenticacionProvider).value;
    final resumenState = ref.watch(controladorDashboardProvider);
    final barberosState = ref.watch(controladorBarberosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Mientras carga o si falla, se usan las primeras 4 del catálogo como
    // fallback fijo -- la sección "Acceso Rápido" nunca se ve vacía ni
    // salta de golpe una vez que el uso real termina de resolver.
    final accesosRapidos =
        ref.watch(controladorAccesoRapidoAdminProvider).value ??
        catalogoAccesosAdmin.take(4).toList();

    final barberosActivos = (barberosState.value ?? [])
        .where((b) => b.activo)
        .length;
    final totalBarberos = (barberosState.value ?? []).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sin notificaciones nuevas')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await ref
                  .read(controladorAutenticacionProvider.notifier)
                  .cerrarSesion();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(controladorDashboardProvider);
            ref.invalidate(controladorBarberosProvider);
            ref.invalidate(controladorAlertaStockProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Vista General
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vista General',
                            style: TipografiaApp.headlineLgMobile.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Métricas de Desempeño de Hoy · ${perfil?.nombre ?? "Admin"}',
                            style: TipografiaApp.bodySm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'HOY',
                            style: TipografiaApp.labelSm.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Top Bento Grid Cards - Diferentes Tamaños según VISTA Mockup
                resumenState.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, s) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No se pudieron cargar los indicadores.',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                  data: (resumen) => Column(
                    children: [
                      // 1. Tarjeta Grande Principal: INGRESOS DE HOY
                      _TarjetaIngresosHero(
                        monto: formatoMoneda(resumen.ingresosHoy),
                        porcentaje: _calcularPorcentajeCambio(
                          resumen.ingresosHoy,
                          resumen.ingresosAyer,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 2. Fila con 2 Tarjetas Medianas Cuadradas
                      Row(
                        children: [
                          Expanded(
                            child: _TarjetaKpiBento(
                              titulo: 'CITAS TOTALES',
                              valor: '${resumen.citasHoy}',
                              icono: Icons.calendar_today,
                              tendenciaTexto: _calcularDiferenciaCitas(
                                resumen.citasHoy,
                                resumen.citasAyer,
                              ),
                              tendenciaColor:
                                  resumen.citasHoy >= resumen.citasAyer
                                  ? ColoresApp.estadoCompletada
                                  : ColoresApp.estadoCancelada,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TarjetaKpiBento(
                              titulo: 'BARBEROS ACTIVOS',
                              valor: totalBarberos > 0
                                  ? '$barberosActivos / $totalBarberos'
                                  : '$barberosActivos',
                              icono: Icons.content_cut,
                              tendenciaTexto: 'ACTIVOS',
                              tendenciaColor: ColoresApp.primario,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Tarjeta Ancha Estilo Gráfico Bento: Tendencia de Ingresos
                const TarjetaGraficoTendencia(),

                const SizedBox(height: 24),

                // 4. Seccion Accesos Rapidos Estilo Bento Card Cuadrados
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acceso Rápido',
                        style: TipografiaApp.headlineSm.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final acceso in accesosRapidos) ...[
                        _BotonAccesoBento(
                          titulo: acceso.titulo,
                          icono: acceso.icono,
                          onTap: () {
                            ref
                                .read(repositorioAccesosAdminProvider)
                                .registrarAcceso(acceso.ruta);
                            context.push(acceso.ruta);
                          },
                        ),
                        if (acceso != accesosRapidos.last)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Alertas de Stock Bajo (Bento Card Destacado)
                Consumer(
                  builder: (context, ref, _) {
                    final alertaStock = ref.watch(
                      controladorAlertaStockProvider,
                    );
                    final cantidad = alertaStock.value ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cantidad > 0
                              ? ColoresApp.estadoCancelada
                              : ColoresApp.estadoCompletada.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                cantidad > 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: cantidad > 0
                                    ? ColoresApp.estadoCancelada
                                    : ColoresApp.estadoCompletada,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cantidad > 0
                                    ? 'Alertas de Stock Bajo'
                                    : 'Stock en Nivel Óptimo',
                                style: TipografiaApp.headlineSm.copyWith(
                                  color: cantidad > 0
                                      ? colorScheme.onSurface
                                      : ColoresApp.estadoCompletada,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cantidad > 0
                                      ? 'Existen $cantidad insumos con stock por debajo del mínimo crítico.'
                                      : 'Todos los insumos del almacén tienen stock suficiente.',
                                  style: TipografiaApp.bodySm.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push('/administracion/almacen'),
                                child: Text(
                                  cantidad > 0 ? 'REABASTECER' : 'VER ALMACÉN',
                                  style: TipografiaApp.labelSm.copyWith(
                                    color: cantidad > 0
                                        ? ColoresApp.primario
                                        : colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta Hero de Ingresos Grandes (idéntica a VISTA/panel_de_administracion_es)
class _TarjetaIngresosHero extends StatelessWidget {
  const _TarjetaIngresosHero({required this.monto, required this.porcentaje});

  final String monto;
  final String porcentaje;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColoresApp.primario.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColoresApp.primario.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: ColoresApp.primario,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ColoresApp.estadoCompletada.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: ColoresApp.estadoCompletada,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      porcentaje,
                      style: TipografiaApp.labelSm.copyWith(
                        color: ColoresApp.estadoCompletada,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'INGRESOS DE HOY',
            style: TipografiaApp.labelSm.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              monto,
              style: TipografiaApp.headlineXl.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaKpiBento extends StatelessWidget {
  const _TarjetaKpiBento({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.tendenciaTexto,
    required this.tendenciaColor,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final String tendenciaTexto;
  final Color tendenciaColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Icon(icono, color: ColoresApp.primario, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tendenciaColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tendenciaTexto,
                  style: TipografiaApp.labelSm.copyWith(
                    color: tendenciaColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            style: TipografiaApp.labelSm.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonAccesoBento extends StatelessWidget {
  const _BotonAccesoBento({
    required this.titulo,
    required this.icono,
    required this.onTap,
  });

  final String titulo;
  final IconData icono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icono, color: colorScheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TipografiaApp.bodyMd.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}