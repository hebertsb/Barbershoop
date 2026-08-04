import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../componentes/lista_citas_atendidas_dia.dart';
import '../componentes/lista_clientes_nuevos_dia.dart';
import '../controladores/controlador_actividad_diaria.dart';

/// Pantalla para que el dueño (que suele viajar) revise, día por día, qué
/// citas se atendieron y qué clientes nuevos se registraron en cualquier
/// día pasado. Separada de `PantallaReportesIngresos` (esa es de KPIs
/// agregados por rango; esta es el detalle crudo de un solo día).
class PantallaActividadDiaria extends ConsumerWidget {
  const PantallaActividadDiaria({super.key});

  Future<void> _seleccionarFecha(BuildContext context, WidgetRef ref) async {
    final estado = ref.read(controladorActividadDiariaProvider);

    final elegida = await showDatePicker(
      context: context,
      initialDate: estado.fecha,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (elegida != null) {
      ref
          .read(controladorActividadDiariaProvider.notifier)
          .cambiarFecha(elegida);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorActividadDiariaProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Actividad del ${formatoFechaCorta(estado.fecha)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Elegir día',
            onPressed: () => _seleccionarFecha(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(controladorActividadDiariaProvider.notifier).cargar(),
        child: estado.cargando
            ? const Center(child: CircularProgressIndicator())
            : estado.error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: Center(
                      child: Text(
                        estado.error!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _EncabezadoSeccion(
                    icono: Icons.check_circle_outline,
                    titulo: 'Citas Atendidas',
                  ),
                  const SizedBox(height: 10),
                  ListaCitasAtendidasDia(citas: estado.citasAtendidas),
                  const SizedBox(height: 24),
                  _EncabezadoSeccion(
                    icono: Icons.person_add_outlined,
                    titulo: 'Clientes Nuevos',
                  ),
                  const SizedBox(height: 10),
                  ListaClientesNuevosDia(clientes: estado.clientesNuevos),
                ],
              ),
      ),
    );
  }
}

class _EncabezadoSeccion extends StatelessWidget {
  const _EncabezadoSeccion({required this.icono, required this.titulo});

  final IconData icono;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icono, color: colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TipografiaApp.headlineSm.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}