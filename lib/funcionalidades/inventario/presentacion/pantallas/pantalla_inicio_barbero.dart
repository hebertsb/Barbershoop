import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../../administracion/presentacion/controladores/controlador_sucursales.dart';
import '../../../ajustes/presentacion/controladores/controlador_ajustes_marca.dart';
import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../../../citas/dominio/enum_estado_cita.dart';
import '../../../citas/presentacion/componentes/tarjeta_ingresos_barbero.dart';
import '../../../citas/presentacion/componentes/tarjeta_proxima_cita_barbero.dart';
import '../../../citas/presentacion/controladores/controlador_citas.dart';
import '../componentes/alerta_insumos_barbero.dart';

/// Home del rol barbero -- saludo + resumen del da + acceso a Agenda.
/// Mis Insumos tiene su propia pestaa y Mis Reseas/Mi Perfil viven en el
/// men "Ms", todo va [EsqueletoBarbero] -- esta pantalla ya no incluye
/// tarjetas de acceso a ninguno de ellos.
class PantallaInicioBarbero extends ConsumerStatefulWidget {
  const PantallaInicioBarbero({super.key});

  @override
  ConsumerState<PantallaInicioBarbero> createState() =>
      _PantallaInicioBarberoState();
}

class _PantallaInicioBarberoState extends ConsumerState<PantallaInicioBarbero> {
  String? _sucursalIdVisible;
  Timer? _timerRefresco;

  @override
  void initState() {
    super.initState();
    _timerRefresco = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      final sucursalId = _sucursalIdVisible;
      if (sucursalId == null) return;
      ref.invalidate(controladorCitasProvider(sucursalId));
    });
  }

  @override
  void dispose() {
    _timerRefresco?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(controladorAutenticacionProvider).value;

    // La sucursal se resuelve desde la propia fila del barbero en
    // `barberos` (llenada al invitarlo), no desde `perfiles.sucursal_id`
    // -- esa columna nunca se llena para el rol barbero, solo aplica a
    // secretaria. Un barbero con ms de una fila (multi-sucursal) usa la
    // primera, mismo criterio que ya usa `pantalla_agenda_barbero.dart`.
    final barberosCoincidentes =
        (ref.watch(controladorBarberosProvider).value ?? [])
            .where((b) => b.perfilId == perfil?.id)
            .toList();
    final miBarbero = barberosCoincidentes.isEmpty
        ? null
        : barberosCoincidentes.first;
    final sucursalId = miBarbero?.sucursalId;
    _sucursalIdVisible = sucursalId;
    final colorScheme = Theme.of(context).colorScheme;

    final sucursales = ref.watch(controladorSucursalesProvider).value ?? [];
    final sucursalesCoincidentes = sucursales
        .where((s) => s.id == sucursalId)
        .toList();
    final nombreSucursal = sucursalesCoincidentes.isEmpty
        ? null
        : sucursalesCoincidentes.first.nombre;

    final citas = sucursalId == null
        ? null
        : ref.watch(controladorCitasProvider(sucursalId)).value;
    final citasHoy = citas
        ?.where(
          (c) =>
              c.estado != EstadoCita.cancelada &&
              c.estado != EstadoCita.noAsistio,
        )
        .length;

    final servicios = ref.watch(controladorServiciosProvider).value ?? [];
    final proximaCita = obtenerProximaCita(citas, miBarbero?.id);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EncabezadoInicioBarbero(nombreSucursal: nombreSucursal),
              const SizedBox(height: 16),
              const AlertaInsumosBarbero(),
              Text(
                'Hola, ${perfil?.nombre ?? "Barbero"}',
                style: TipografiaApp.headlineMd.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                citasHoy == null || citasHoy == 0
                    ? 'No tienes citas programadas para hoy'
                    : citasHoy == 1
                    ? 'Hoy tienes 1 cita programada'
                    : 'Hoy tienes $citasHoy citas programadas',
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const TarjetaIngresosBarbero(),
              const SizedBox(height: 12),
              if (proximaCita != null) ...[
                TarjetaProximaCitaBarbero(
                  cita: proximaCita,
                  nombreServicio: nombreServicioDeCita(proximaCita, servicios),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    'Agenda del Día',
                    style: TipografiaApp.bodyMd.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Tus citas y asistencias de hoy'),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.outline,
                  ),
                  onTap: () => context.go('/mi-agenda'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado del inicio del barbero: logo + nombre de marca / sucursal a la
/// que pertenece, con acceso a cerrar sesin. Mismo patrn visual que
/// `_EncabezadoInicio` de [PantallaInicioCliente], pero la lnea secundaria
/// es el nombre de la sucursal en lugar del saludo al usuario (el saludo ya
/// se muestra debajo, en el cuerpo de esta pantalla).
class _EncabezadoInicioBarbero extends ConsumerWidget {
  const _EncabezadoInicioBarbero({required this.nombreSucursal});

  final String? nombreSucursal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              if (nombreSucursal != null)
                Text(
                  nombreSucursal!,
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.logout, color: colorScheme.primary),
          tooltip: 'Cerrar sesin',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Cerrar sesin'),
                content: const Text('Ests seguro de que deseas salir?'),
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