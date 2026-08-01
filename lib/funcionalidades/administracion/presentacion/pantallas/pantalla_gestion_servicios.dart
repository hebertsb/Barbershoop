import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_servicio.dart';
import '../componentes/formulario_servicio.dart';
import '../componentes/tarjeta_servicio.dart';
import '../controladores/controlador_servicios.dart';

class PantallaGestionServicios extends ConsumerStatefulWidget {
  const PantallaGestionServicios({super.key});

  @override
  ConsumerState<PantallaGestionServicios> createState() =>
      _PantallaGestionServiciosState();
}

class _PantallaGestionServiciosState
    extends ConsumerState<PantallaGestionServicios> {
  bool _modoGrilla = true;
  String _busqueda = '';

  void _abrirFormulario([ModeloServicio? servicio]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioServicio(
        servicio: servicio,
        alGuardar: (nuevoServicio) {
          return ref
              .read(controladorServiciosProvider.notifier)
              .guardarServicio(nuevoServicio);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviciosState = ref.watch(controladorServiciosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(controladorServiciosProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios y Tarifas'),
        actions: [
          IconButton(
            icon: Icon(_modoGrilla ? Icons.view_list : Icons.grid_view),
            tooltip: _modoGrilla ? 'Cambiar a Lista' : 'Cambiar a Grilla',
            onPressed: () => setState(() => _modoGrilla = !_modoGrilla),
          ),
        ],
      ),
      body: serviciosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (servicios) {
          final filtrados = servicios
              .where(
                (s) => s.nombre.toLowerCase().contains(_busqueda.toLowerCase()),
              )
              .toList();

          return Column(
            children: [
              // Barra de búsqueda y Filtros arriba
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar servicio...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) => setState(() => _busqueda = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${filtrados.length} Servicios registrados',
                            style: TipografiaApp.bodySm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        // Segmented Toggle Grilla / Lista
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              icon: Icon(Icons.grid_view, size: 18),
                              label: Text('Cuadros'),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              icon: Icon(Icons.view_list, size: 18),
                              label: Text('Lista'),
                            ),
                          ],
                          selected: {_modoGrilla},
                          onSelectionChanged: (set) {
                            setState(() => _modoGrilla = set.first);
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: ColoresApp.primario
                                .withValues(alpha: 0.2),
                            selectedForegroundColor: ColoresApp.primario,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenido principal (Grilla o Lista)
              Expanded(
                child: filtrados.isEmpty
                    ? Center(
                        child: Text(
                          'No hay servicios para mostrar.',
                          style: TipografiaApp.bodyMd.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : _modoGrilla
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        // Alto fijo (no `childAspectRatio`): un aspect ratio
                        // fijo estira la altura de la celda cuando hay pocas
                        // columnas y la celda se ensancha (pantallas anchas),
                        // dejando una franja vacía enorme debajo del texto
                        // (bug real reportado en tablet horizontal).
                        // `maxCrossAxisExtent` fija el ancho ideal por tarjeta
                        // y Flutter decide solo cuántas columnas entran.
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              mainAxisExtent: 220,
                            ),
                        itemCount: filtrados.length,
                        itemBuilder: (context, index) {
                          final servicio = filtrados[index];
                          return TarjetaServicio(
                            servicio: servicio,
                            compacto: true,
                            onTap: () => _abrirFormulario(servicio),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filtrados.length,
                        itemBuilder: (context, index) {
                          final servicio = filtrados[index];
                          return TarjetaServicio(
                            servicio: servicio,
                            onTap: () => _abrirFormulario(servicio),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      // Botón Grande "Añadir Nuevo +"
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton.icon(
          onPressed: () => _abrirFormulario(),
          icon: const Icon(Icons.add, size: 22),
          label: const Text(
            'NUEVO SERVICIO',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColoresApp.primario,
            foregroundColor: colorScheme.onPrimaryContainer,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}
