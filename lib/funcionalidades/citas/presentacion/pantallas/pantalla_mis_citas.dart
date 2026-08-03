import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/contacto_whatsapp.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../../administracion/presentacion/controladores/controlador_sucursales.dart';
import '../../../ajustes/presentacion/controladores/controlador_ajustes_pagos.dart';
import '../../../pagos/presentacion/controladores/controlador_pagos.dart';
import '../../dominio/enum_estado_cita.dart';
import '../../../resenas/presentacion/componentes/resena_cita.dart';
import '../componentes/acciones_mi_cita.dart';
import '../componentes/estado_pago_cita.dart';
import '../componentes/tarjeta_mi_cita.dart';
import '../controladores/controlador_mis_citas.dart';

/// Pantalla de solo lectura con las citas del cliente autenticado
/// (pasadas y futuras). Se convertir en la pestaa "Agenda" del
/// shell de navegacin del rol cliente.
class PantallaMisCitas extends ConsumerStatefulWidget {
  const PantallaMisCitas({super.key});

  @override
  ConsumerState<PantallaMisCitas> createState() => _PantallaMisCitasState();
}

class _PantallaMisCitasState extends ConsumerState<PantallaMisCitas> {
  Timer? _timerRefresco;

  @override
  void initState() {
    super.initState();
    _timerRefresco = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      _refrescar();
    });
  }

  @override
  void dispose() {
    _timerRefresco?.cancel();
    super.dispose();
  }

  // El estado de las citas (`controladorMisCitasProvider`) y el estado de
  // pago por cita (`controladorPagoDeCitaProvider`, family autoDispose que
  // `EstadoPagoCita` consulta de forma independiente) son providers
  // separados: invalidar solo el primero no alcanza para que un pago
  // rechazado/confirmado desde el otro lado se refleje ac. Se invalida el
  // family completo (sin argumento) para refrescar todas las tarjetas
  // visibles a la vez.
  void _refrescar() {
    ref.invalidate(controladorMisCitasProvider);
    ref.invalidate(controladorPagoDeCitaProvider);
  }

  @override
  Widget build(BuildContext context) {
    final citasState = ref.watch(controladorMisCitasProvider);
    final barberosState = ref.watch(barberosPublicosProvider);
    final serviciosState = ref.watch(controladorServiciosProvider);
    final sucursalesState = ref.watch(controladorSucursalesProvider);
    final configState = ref.watch(controladorAjustesPagosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Citas')),
      body: RefreshIndicator(
        onRefresh: () async {
          _refrescar();
        },
        child: citasState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (citas) {
            if (citas.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 64,
                    ),
                    child: Center(
                      child: Text(
                        'Todava no tens citas reservadas.',
                        style: TipografiaApp.bodyMd.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final barberos = barberosState.value ?? [];
            final servicios = serviciosState.value ?? [];
            final sucursales = sucursalesState.value ?? [];
            final config = configState.value;

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: citas.length,
              itemBuilder: (context, index) {
                final cita = citas[index];

                // `citas.servicio_id` solo guarda el primer servicio de un
                // combo (diseo intencional) -- si la cita viene de una
                // promocin combo, `nombresServiciosCombo` trae la lista
                // completa (ej. "Corte + Barba"); si no, se busca el
                // servicio individual en el catlogo como antes.
                String nombreServicio;
                if (cita.nombresServiciosCombo.isNotEmpty) {
                  nombreServicio = cita.nombresServiciosCombo.join(' + ');
                } else {
                  final candidatosServicio = servicios
                      .where((s) => s.id == cita.servicioId)
                      .toList();
                  nombreServicio = candidatosServicio.isEmpty
                      ? 'Servicio'
                      : candidatosServicio.first.nombre;
                }
                final candidatosBarbero = barberos
                    .where((b) => b.id == cita.barberoId)
                    .toList();
                final nombreBarbero = candidatosBarbero.isEmpty
                    ? 'Barbero'
                    : (candidatosBarbero.first.nombrePerfil ?? 'Barbero');
                final telefonoBarberoCrudo = candidatosBarbero.isEmpty
                    ? null
                    : candidatosBarbero.first.telefonoPerfil;
                final telefonoBarberoWhatsapp = telefonoBarberoCrudo == null
                    ? null
                    : normalizarTelefonoWhatsapp(telefonoBarberoCrudo);

                final candidatosSucursal = sucursales
                    .where((s) => s.id == cita.sucursalId)
                    .toList();
                final telefonoSucursalCrudo = candidatosSucursal.isEmpty
                    ? null
                    : candidatosSucursal.first.telefono;
                final telefonoSucursalWhatsapp = telefonoSucursalCrudo == null
                    ? null
                    : normalizarTelefonoWhatsapp(telefonoSucursalCrudo);

                // `cita.precioCobrado` ya viene calculado por `reservar_cita`
                // desde que se crea la cita -- combo + descuento de promo ya
                // aplicados, no hace falta recalcular desde el catlogo.
                final montoPago = config?.calcularMontoAPagar(
                  cita.precioCobrado,
                );

                return TarjetaMiCita(
                  cita: cita,
                  nombreServicio: nombreServicio,
                  nombreBarbero: nombreBarbero,
                  telefonoBarberoWhatsapp: telefonoBarberoWhatsapp,
                  telefonoSucursalWhatsapp: telefonoSucursalWhatsapp,
                  pieDePago: cita.estado == EstadoCita.pendiente
                      ? EstadoPagoCita(
                          citaId: cita.id,
                          modoPago: config?.modo,
                          monto: montoPago,
                          urlQrBanco: config?.urlQrBanco,
                        )
                      : null,
                  acciones: cita.estado == EstadoCita.pendiente
                      ? AccionesMiCita(cita: cita)
                      : null,
                  resena: cita.estado == EstadoCita.completada
                      ? ResenaCita(citaId: cita.id)
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
