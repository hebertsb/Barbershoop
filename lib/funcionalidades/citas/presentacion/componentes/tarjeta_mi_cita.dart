import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_estado_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../dominio/enum_estado_cita.dart';
import '../../dominio/modelo_cita.dart';
import 'boton_contacto_whatsapp.dart';
import 'etiqueta_estado.dart';

/// Tarjeta de solo lectura con el resumen de una cita del cliente.
///
/// Recibe los nombres de servicio y barbero ya resueltos por quien la
/// invoca: este widget es puramente presentacional, sin lógica de
/// búsqueda ni acceso a providers. [pieDePago] y [acciones] siguen el mismo
/// criterio: si no son null, se dibujan tal cual al final de la tarjeta —
/// quien arma la lista decide cuándo corresponde (cita `pendiente`) y con
/// qué contenido (esas decisiones sí necesitan leer providers, por eso viven
/// en componentes aparte en vez de acá).
class TarjetaMiCita extends StatelessWidget {
  const TarjetaMiCita({
    super.key,
    required this.cita,
    required this.nombreServicio,
    required this.nombreBarbero,
    this.pieDePago,
    this.acciones,
    this.resena,
    this.telefonoBarberoWhatsapp,
    this.telefonoSucursalWhatsapp,
  });

  final ModeloCita cita;
  final String nombreServicio;
  final String nombreBarbero;
  final Widget? pieDePago;

  /// Botones de acción (ej. "Cancelar"/"Reprogramar"), dibujados debajo de
  /// [pieDePago] cuando no es null.
  final Widget? acciones;

  /// Botón "Calificar" (o nada, si ya tiene reseña), dibujado al final de
  /// la tarjeta cuando no es null -- mismo criterio que `pieDePago`/`acciones`.
  final Widget? resena;

  /// Ya normalizados (ver `normalizarTelefonoWhatsapp`) -- `null` = ese
  /// botón de contacto no se muestra (el barbero/la sucursal no tienen
  /// teléfono cargado, o el dato cargado no es un teléfono válido).
  final String? telefonoBarberoWhatsapp;
  final String? telefonoSucursalWhatsapp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colores = Theme.of(context).extension<ColoresEstadoApp>()!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nombreServicio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TipografiaApp.headlineSm.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                EtiquetaEstado(
                  texto: textoEstadoCita(cita.estado),
                  color: colorParaEstadoCita(cita.estado, colores),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  formatoFechaHora(cita.fechaHora.toLocal()),
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.content_cut,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  nombreBarbero,
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if ((cita.estado == EstadoCita.pendiente ||
                    cita.estado == EstadoCita.confirmada) &&
                (telefonoBarberoWhatsapp != null ||
                    telefonoSucursalWhatsapp != null)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (telefonoBarberoWhatsapp != null)
                    Expanded(
                      child: BotonContactoWhatsapp(
                        telefono: telefonoBarberoWhatsapp!,
                        etiqueta: 'Contactar a mi barbero',
                        icono: Icons.chat,
                        chipsMensaje: const [
                          'Voy en camino',
                          'Llego ~10 min tarde',
                          'Tengo una duda',
                        ],
                      ),
                    ),
                  if (telefonoBarberoWhatsapp != null &&
                      telefonoSucursalWhatsapp != null)
                    const SizedBox(width: 8),
                  if (telefonoSucursalWhatsapp != null)
                    Expanded(
                      child: BotonContactoWhatsapp(
                        telefono: telefonoSucursalWhatsapp!,
                        etiqueta: 'Contactar a la barbería',
                        icono: Icons.storefront,
                        chipsMensaje: const ['Tengo una consulta'],
                      ),
                    ),
                ],
              ),
            ],
            if (pieDePago != null) ...[const SizedBox(height: 8), pieDePago!],
            if (acciones != null) ...[const SizedBox(height: 8), acciones!],
            if (resena != null) ...[const SizedBox(height: 8), resena!],
          ],
        ),
      ),
    );
  }
}
