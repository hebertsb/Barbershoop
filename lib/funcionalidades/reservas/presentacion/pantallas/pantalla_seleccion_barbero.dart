import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../administracion/dominio/modelo_barbero.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../controladores/controlador_reserva.dart';

const _etiquetasNivel = {
  'junior': 'Junior',
  'senior': 'Senior',
  'master': 'Master',
};

class PantallaSeleccionBarbero extends ConsumerWidget {
  const PantallaSeleccionBarbero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barberosState = ref.watch(barberosPublicosProvider);
    final sucursalId = ref.watch(controladorReservaProvider).sucursalId;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Elige tu Barbero')),
      body: barberosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (barberos) {
          final activosDeLaSucursal = barberos
              .where((b) => b.activo && b.sucursalId == sucursalId)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TarjetaCualquierBarbero(
                onTap: () {
                  ref
                      .read(controladorReservaProvider.notifier)
                      .seleccionarCualquiera();
                  context.push('/reservar/horario');
                },
              ),
              const SizedBox(height: 20),
              if (activosDeLaSucursal.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay barberos específicos asignados en esta sucursal — utiliza "Cualquiera disponible".',
                    style: TipografiaApp.bodySm.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...activosDeLaSucursal.map(
                  (barbero) => _TarjetaBarberoGrande(
                    barbero: barbero,
                    onTap: () {
                      ref
                          .read(controladorReservaProvider.notifier)
                          .seleccionarBarberoEspecifico(barbero.id);
                      context.push('/reservar/horario');
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaCualquierBarbero extends StatelessWidget {
  const _TarjetaCualquierBarbero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: colorScheme.primaryContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary,
                child: Icon(
                  Icons.shuffle,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cualquier barbero',
                      style: TipografiaApp.headlineSm.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mayor disponibilidad hoy',
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaBarberoGrande extends StatelessWidget {
  const _TarjetaBarberoGrande({required this.barbero, required this.onTap});

  final ModeloBarbero barbero;
  final VoidCallback onTap;

  String get _descripcion {
    if (barbero.especialidades.isEmpty) return 'Barbero profesional';
    return 'Especialista en ${barbero.especialidades.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nivelTexto = _etiquetasNivel[barbero.nivel];

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: barbero.urlFotoPerfil != null
                    ? CachedNetworkImage(
                        imageUrl: barbero.urlFotoPerfil!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: colorScheme.surfaceContainerHigh,
                          child: Icon(
                            Icons.person,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Container(
                        color: colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.person,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              if (nivelTexto != null)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColoresApp.primario,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      nivelTexto,
                      style: TipografiaApp.labelSm.copyWith(
                        color: ColoresApp.onPrimario,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barbero.nombrePerfil ?? 'Barbero',
                  style: TipografiaApp.headlineSm.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _descripcion,
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('SELECCIONAR'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
