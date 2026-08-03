import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/abrir_mapa_externo.dart';
import '../../../../nucleo/utilidades/formato_distancia.dart';
import '../../../../nucleo/utilidades/horario_apertura.dart';
import '../../../../nucleo/utilidades/ubicacion_actual.dart';
import '../../../administracion/presentacion/controladores/controlador_sucursales.dart';
import '../../dominio/orden_sucursales_por_distancia.dart';
import '../controladores/controlador_reserva.dart';

class PantallaSeleccionSucursal extends ConsumerStatefulWidget {
  const PantallaSeleccionSucursal({super.key});

  @override
  ConsumerState<PantallaSeleccionSucursal> createState() =>
      _PantallaSeleccionSucursalState();
}

class _PantallaSeleccionSucursalState
    extends ConsumerState<PantallaSeleccionSucursal> {
  Position? _posicionActual;

  @override
  void initState() {
    super.initState();
    // Diferido a addPostFrameCallback: invalidar en initState de forma
    // sincronica puede disparar un rebuild en cascada de otro widget que ya
    // esta montado y observa el mismo provider (ej. PantallaInicioCliente,
    // que sigue vivo debajo de este push y tiene su propio Timer.periodic
    // invalidando controladorSucursalesProvider) justo mientras este widget
    // todavia esta inicializandose -- eso dispara
    // "dependOnInheritedWidgetOfExactType...called before initState()
    // completed". Postergarlo un frame evita la carrera.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(controladorSucursalesProvider);
    });
    _cargarPosicionActual();
  }

  Future<void> _cargarPosicionActual() async {
    final posicion = await obtenerPosicionActual();
    if (mounted) setState(() => _posicionActual = posicion);
  }

  /// Selecciona la sucursal y avanza al siguiente paso del flujo de reserva.
  ///
  /// Si ya hay una promoción activa en [EstadoReserva] con su servicio
  /// (o combo) ya cargado -- caso de reservar desde una oferta con 2+
  /// sucursales activas -- se salta la pantalla de selección de servicio
  /// y se va directo a elegir barbero.
  void _irAlSiguientePaso(String sucursalId) {
    final controlador = ref.read(controladorReservaProvider.notifier);
    controlador.seleccionarSucursal(sucursalId);
    final promocion = ref.read(controladorReservaProvider).promocion;
    if (promocion != null && promocion.servicioId != null) {
      context.push('/reservar/barbero');
    } else {
      context.push('/reservar/servicio');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sucursalesState = ref.watch(controladorSucursalesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona una Sucursal')),
      body: sucursalesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (sucursales) {
          final activas = sucursales.where((s) => s.activo).toList();
          if (activas.isEmpty) {
            return const Center(child: Text('No hay sucursales disponibles.'));
          }
          final conDistancia = ordenarSucursalesPorDistancia(
            activas,
            _posicionActual,
          );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conDistancia.length,
            itemBuilder: (_, index) {
              final item = conDistancia[index];
              final sucursal = item.sucursal;
              final abierta = estaSucursalAbiertaAhora(
                sucursal.horarioApertura,
                sucursal.horarioCierre,
              );
              final colorEstado = abierta
                  ? ColoresApp.estadoCompletada
                  : ColoresApp.estadoCancelada;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _irAlSiguientePaso(sucursal.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sucursal.urlImagen != null)
                        CachedNetworkImage(
                          imageUrl: sucursal.urlImagen!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 140,
                            color: colorScheme.surfaceContainerHigh,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 100,
                            color: colorScheme.surfaceContainerHigh,
                            child: const Center(
                              child: Icon(Icons.store_outlined, size: 40),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          width: double.infinity,
                          color: colorScheme.surfaceContainerHigh,
                          child: Center(
                            child: Icon(
                              Icons.store_outlined,
                              size: 44,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    sucursal.nombre,
                                    style: TipografiaApp.headlineSm.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorEstado.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    abierta ? 'Abierto' : 'Cerrado',
                                    style: TipografiaApp.labelSm.copyWith(
                                      color: colorEstado,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (sucursal.direccion != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      sucursal.direccion!,
                                      style: TipografiaApp.bodySm.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (sucursal.telefono != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    sucursal.telefono!,
                                    style: TipografiaApp.bodySm.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (item.distanciaMetros != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.near_me_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatoDistancia(item.distanciaMetros!),
                                    style: TipografiaApp.bodySm.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (sucursal.latitud != null &&
                                sucursal.longitud != null) ...[
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => abrirMapaExterno(
                                    sucursal.latitud!,
                                    sucursal.longitud!,
                                  ),
                                  icon: const Icon(Icons.map_outlined, size: 18),
                                  label: const Text('Cómo llegar'),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _irAlSiguientePaso(sucursal.id),
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: const Text('Seleccionar Sucursal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor:
                                      colorScheme.onPrimaryContainer,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}