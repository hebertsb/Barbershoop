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
                const SizedBox(height: 32),
                const _SeccionProximaCita(),
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
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Cerrar sesión'),
                content: const Text('¿Estás seguro de que deseas salir?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref
                          .read(controladorAutenticacionProvider.notifier)
                          .cerrarSesion();
                    },
                    child: const Text('Salir'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
class _SeccionProximaCita extends ConsumerWidget {
  const _SeccionProximaCita();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citasState = ref.watch(controladorMisCitasProvider);
    final serviciosState = ref.watch(controladorServiciosProvider);
    final barberosState = ref.watch(barberosPublicosProvider);
    // ref.watch (no .read) es intencional: además de traer el umbral,
    // mantiene esta sección re-evaluando "cuánto falta" cada vez que el
    // Timer.periodic de arriba invalida este provider (cada 60s) -- si se
    // cambia a .read, el botón Reprogramar deja de desaparecer solo con el
    // paso del tiempo.
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => const SizedBox.shrink(),
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
                child: Text(
                  'No tienes citas próximas activas.',
                  style: TipografiaApp.bodyMd.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            // `citas.servicio_id` solo guarda el primer servicio de un
            // combo (diseño intencional) -- si la cita viene de una
            // promoción combo, `nombresServiciosCombo` trae la lista
            // completa (ej. "Corte + Barba"); si no, se busca el
            // servicio individual en el catálogo como antes.
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
/// Sección de servicios populares con carrusel horizontal.
/// Recibe [onIniciarReserva] desde [PantallaInicioCliente] para que la
/// navegación se haga desde el contexto correcto (navigator raíz).
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
    if (servicios.isEmpty) return const SizedBox.shrink();
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
        // Altura = imagen(130) + padding(22) + nombre(20) + desc(36) + margen(12)
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: servicios.length,
            // Usar "_" para no ocultar el context del build()
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
/// Sección de ofertas especiales con carrusel horizontal.
/// Recibe [onIniciarReserva] desde [PantallaInicioCliente] para que la
/// navegación se haga desde el contexto correcto (navigator raíz).
class _SeccionOfertaEspecial extends ConsumerWidget {
  const _SeccionOfertaEspecial({required this.onIniciarReserva});
  final Future<void> Function({String? servicioId}) onIniciarReserva;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promocionesState = ref.watch(controladorPromocionesClienteProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return promocionesState.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (promociones) {
        if (promociones.isEmpty) return const SizedBox.shrink();
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
            // Cada tarjeta mide su propio alto natural (evita alturas fijas
            // que se desajustan con combos de servicios, 2 líneas de
            // descripción o escalas de accesibilidad de texto grandes).
            SingleChildScrollView(
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
                          // Navegar usando el navigator raíz
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
            ),
          ],
        );
      },
    );
  }
}