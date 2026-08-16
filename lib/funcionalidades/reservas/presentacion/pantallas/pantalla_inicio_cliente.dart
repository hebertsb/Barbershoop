import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/navegador_raiz.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../../administracion/presentacion/controladores/controlador_sucursales.dart';
import '../../../ajustes/presentacion/controladores/controlador_ajustes_marca.dart';
import '../../../ajustes/presentacion/controladores/controlador_instrucciones_cita.dart';
import '../../../ajustes/presentacion/controladores/controlador_minutos_cancelacion.dart';
import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../../citas/presentacion/controladores/controlador_mis_citas.dart';
import '../../../fidelidad/presentacion/componentes/pildora_fidelidad_flotante.dart';
import '../../../promociones/presentacion/componentes/tarjeta_promocion_cliente.dart';
import '../../../promociones/presentacion/controladores/controlador_promociones_cliente.dart';
import '../componentes/tarjeta_proxima_cita.dart';
import '../componentes/tarjeta_servicio_popular.dart';
import '../controladores/controlador_reserva.dart';
/// Pantalla de inicio del cliente: próxima cita, servicios populares y
/// ofertas especiales. Usa [navegadorRaizKey] para navegar desde callbacks
/// async y evitar el error DependOnInheritedWidgetOfExactType que ocurre
/// cuando se usa el context del itemBuilder después de un await.
class PantallaInicioCliente extends ConsumerStatefulWidget {
  const PantallaInicioCliente({super.key});
  @override
  ConsumerState<PantallaInicioCliente> createState() =>
      _PantallaInicioClienteState();
}
class _PantallaInicioClienteState extends ConsumerState<PantallaInicioCliente> {
  Timer? _timerRefresco;
  @override
  void initState() {
    super.initState();
    _timerRefresco = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      ref.invalidate(controladorMisCitasProvider);
      ref.invalidate(controladorServiciosProvider);
      ref.invalidate(controladorSucursalesProvider);
      ref.invalidate(barberosPublicosProvider);
      ref.invalidate(controladorMinutosCancelacionProvider);
      ref.invalidate(controladorPromocionesClienteProvider);
    });
  }
  @override
  void dispose() {
    _timerRefresco?.cancel();
    super.dispose();
  }
  /// Inicia el flujo de reserva navegando al paso correspondiente.
  /// Usa [navegadorRaizKey] para garantizar que la navegación funciona
  /// incluso cuando se llama desde un callback async dentro de un itemBuilder.
  Future<void> _iniciarReserva({String? servicioId}) async {
    ref.read(controladorReservaProvider.notifier).reiniciar();
    if (servicioId != null) {
      ref
          .read(controladorReservaProvider.notifier)
          .seleccionarServicio(servicioId);
    }
    final sucursales = await ref.read(controladorSucursalesProvider.future);
    final activas = sucursales.where((s) => s.activo).toList();
    // Usar el navigator raíz para evitar problemas con el contexto del shell
    final nav = navegadorRaizKey.currentContext;
    if (nav == null || !nav.mounted) return;
    if (activas.length == 1) {
      ref
          .read(controladorReservaProvider.notifier)
          .seleccionarSucursal(activas.first.id);
      nav.push(servicioId != null ? '/reservar/barbero' : '/reservar/servicio');
    } else {
      nav.push('/reservar/sucursal');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(controladorMisCitasProvider);
            ref.invalidate(controladorServiciosProvider);
            ref.invalidate(controladorSucursalesProvider);
            ref.invalidate(barberosPublicosProvider);
            ref.invalidate(controladorMinutosCancelacionProvider);
            ref.invalidate(controladorPromocionesClienteProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _EncabezadoInicio(),
                const SizedBox(height: 16),
                const PildoraFidelidadFlotante(),
                const SizedBox(height: 16),
                _SeccionProximaCita(onIniciarReserva: _iniciarReserva),
                const SizedBox(height: 32),
                _SeccionServiciosPopulares(onIniciarReserva: _iniciarReserva),
                const SizedBox(height: 32),
                _SeccionOfertaEspecial(onIniciarReserva: _iniciarReserva),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _iniciarReserva(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
class _EncabezadoInicio extends ConsumerWidget {
  const _EncabezadoInicio();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(controladorAutenticacionProvider).value?.nombre;
    final marca = ref.watch(controladorAjustesMarcaProvider).valueOrNull;
    final urlLogo = marca?.urlLogo;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.surfaceContainerHighest,
          backgroundImage: urlLogo != null
              ? CachedNetworkImageProvider(urlLogo)
              : null,
          child: urlLogo == null
              ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                marca?.nombre ?? 'BarberApp',
                style: TipografiaApp.headlineMd.copyWith(
                  color: ColoresApp.primario,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                nombre != null ? 'Hola, $nombre' : 'Hola',
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: colorScheme.primary),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente: notificaciones')),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.logout, color: colorScheme.primary),
          tooltip: 'Cerrar sesión',
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
    );
  }
}
class _SeccionProximaCita extends ConsumerWidget {
  const _SeccionProximaCita({required this.onIniciarReserva});
  final Future<void> Function({String? servicioId}) onIniciarReserva;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citasState = ref.watch(controladorMisCitasProvider);
    final serviciosState = ref.watch(controladorServiciosProvider);
    final barberosState = ref.watch(barberosPublicosProvider);
    final minutosCancelacion = ref.watch(controladorMinutosCancelacionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próxima Cita',
              style: TipografiaApp.headlineSm.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/mis-citas'),
              child: Text(
                'VER TODAS',
                style: TipografiaApp.labelSm.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        citasState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, s) => Container(
            width: double.infinity,
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
                  '¿Listo para tu próximo corte?',
                  style: TipografiaApp.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reserva una cita con tu barbero preferido.',
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => onIniciarReserva(),
                  icon: const Icon(Icons.add_task),
                  label: const Text('NUEVA RESERVA'),
                ),
              ],
            ),
          ),
          data: (_) {
            final proximaCita = ref.watch(proximaCitaProvider);
            if (proximaCita == null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'No tienes citas próximas activas',
                          style: TipografiaApp.bodyLg.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reserva tu horario ideal en pocos segundos.',
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => onIniciarReserva(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColoresApp.primario,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: const Text(
                          'AGENDAR UNA CITA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            String nombreServicio;
            if (proximaCita.nombresServiciosCombo.isNotEmpty) {
              nombreServicio = proximaCita.nombresServiciosCombo.join(' + ');
            } else {
              final servicios = serviciosState.value ?? [];
              final candidatosServicio = servicios
                  .where((s) => s.id == proximaCita.servicioId)
                  .toList();
              nombreServicio = candidatosServicio.isEmpty
                  ? 'Servicio'
                  : candidatosServicio.first.nombre;
            }
            final barberos = barberosState.value ?? [];
            final candidatosBarbero = barberos
                .where((b) => b.id == proximaCita.barberoId)
                .toList();
            final nombreBarbero = candidatosBarbero.isEmpty
                ? null
                : candidatosBarbero.first.nombrePerfil;
            final puedeReprogramar =
                minutosCancelacion.value == null ||
                proximaCita.puedeReprogramarse(minutosCancelacion.value!);
            return TarjetaProximaCita(
              cita: proximaCita,
              nombreServicio: nombreServicio,
              nombreBarbero: nombreBarbero,
              onReprogramar: !puedeReprogramar
                  ? null
                  : () {
                      ref
                          .read(controladorReservaProvider.notifier)
                          .iniciarReprogramacion(
                            sucursalId: proximaCita.sucursalId ?? '',
                            servicioId: proximaCita.servicioId,
                            citaIdAReemplazar: proximaCita.id,
                            fechaHoraOriginal: proximaCita.fechaHora,
                          );
                      context.push('/reservar/barbero');
                    },
              onVerInstrucciones: () async {
                try {
                  final instrucciones = await ref.read(
                    controladorInstruccionesCitaProvider.future,
                  );
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Instrucciones'),
                      content: Text(instrucciones),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Entendido'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            );
          },
        ),
      ],
    );
  }
}
class _SeccionServiciosPopulares extends ConsumerWidget {
  const _SeccionServiciosPopulares({required this.onIniciarReserva});
  final Future<void> Function({String? servicioId}) onIniciarReserva;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviciosState = ref.watch(controladorServiciosProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final servicios = (serviciosState.value ?? [])
        .where((s) => s.activo)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios Populares',
          style: TipografiaApp.headlineSm.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (serviciosState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (servicios.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Servicios de la Barbería',
                  style: TipografiaApp.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cortes de cabello, barba, perfilado y tratamientos.',
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => onIniciarReserva(),
                  icon: const Icon(Icons.content_cut),
                  label: const Text('VER SERVICIOS Y RESERVAR'),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              itemCount: servicios.length,
              itemBuilder: (_, index) {
                final servicio = servicios[index];
                return TarjetaServicioPopular(
                  servicio: servicio,
                  onTap: () => onIniciarReserva(servicioId: servicio.id),
                );
              },
            ),
          ),
      ],
    );
  }
}
class _SeccionOfertaEspecial extends ConsumerWidget {
  const _SeccionOfertaEspecial({required this.onIniciarReserva});
  final Future<void> Function({String? servicioId}) onIniciarReserva;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promocionesState = ref.watch(controladorPromocionesClienteProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promociones y Ofertas',
          style: TipografiaApp.headlineSm.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        promocionesState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              'No hay promociones activas en este momento.',
              style: TipografiaApp.bodySm.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          data: (promociones) {
            if (promociones.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      color: ColoresApp.primario,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Novedades y Descuentos',
                            style: TipografiaApp.bodyLg.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '¡Atento! Próximamente publicaremos ofertas exclusivas.',
                            style: TipografiaApp.bodySm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    for (final promo in promociones)
                      TarjetaPromocionCliente(
                        promocion: promo,
                        onReservar: () async {
                          ref
                              .read(controladorReservaProvider.notifier)
                              .iniciarReservaConPromocion(promo);
                          final sucursales = await ref.read(
                            controladorSucursalesProvider.future,
                          );
                          final activas = sucursales
                              .where((s) => s.activo)
                              .toList();
                          final nav = navegadorRaizKey.currentContext;
                          if (nav == null || !nav.mounted) return;
                          if (activas.length == 1) {
                            ref
                                .read(controladorReservaProvider.notifier)
                                .seleccionarSucursal(activas.first.id);
                            if (promo.servicioId != null) {
                              nav.push('/reservar/barbero');
                            } else {
                              nav.push('/reservar/servicio');
                            }
                          } else {
                            nav.push('/reservar/sucursal');
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}