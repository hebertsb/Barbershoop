import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../administracion/dominio/modelo_servicio.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../dominio/modelo_programa_fidelidad.dart';
import '../componentes/formulario_programa_fidelidad.dart';
import '../controladores/controlador_programas_fidelidad.dart';

class PantallaGestionProgramasFidelidad extends ConsumerWidget {
  const PantallaGestionProgramasFidelidad({super.key});

  void _abrirFormulario(
    BuildContext context,
    WidgetRef ref,
    List<ModeloServicio> servicios,
    ModeloProgramaFidelidad? programa,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioProgramaFidelidad(
        programa: programa,
        servicios: servicios,
        alGuardar: (p) => ref
            .read(controladorProgramasFidelidadProvider.notifier)
            .guardarPrograma(p),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorProgramasFidelidadProvider);
    final serviciosState = ref.watch(controladorServiciosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Programas de Fidelidad')),
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (programas) {
          if (programas.isEmpty) {
            return const Center(
              child: Text('Todava no creaste ningn programa de fidelidad.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: programas.length,
            itemBuilder: (context, index) {
              final programa = programas[index];
              final rangoFechas =
                  programa.fechaInicio == null && programa.fechaFin == null
                  ? null
                  : '${programa.fechaInicio != null ? formatoFechaCorta(programa.fechaInicio!) : "Inicio"} '
                        'a ${programa.fechaFin != null ? formatoFechaCorta(programa.fechaFin!) : "Indefinido"}';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(programa.titulo),
                  subtitle: Text(
                    'Meta: ${programa.metaCitas} citas'
                    '${rangoFechas != null ? '  Vlido $rangoFechas' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: programa.activo,
                        onChanged: (val) => ref
                            .read(
                              controladorProgramasFidelidadProvider.notifier,
                            )
                            .cambiarEstadoPrograma(programa.id, val),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _abrirFormulario(
                          context,
                          ref,
                          serviciosState.value ?? [],
                          programa,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColoresApp.primario,
        onPressed: () =>
            _abrirFormulario(context, ref, serviciosState.value ?? [], null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
