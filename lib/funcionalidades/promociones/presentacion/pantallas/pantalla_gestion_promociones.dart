import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../componentes/formulario_promocion.dart';
import '../componentes/tarjeta_promocion_admin.dart';
import '../controladores/controlador_promociones_admin.dart';
import '../../dominio/modelo_promocion.dart';
import 'pantalla_usos_promocion.dart';

class PantallaGestionPromociones extends ConsumerStatefulWidget {
  const PantallaGestionPromociones({super.key});

  @override
  ConsumerState<PantallaGestionPromociones> createState() =>
      _PantallaGestionPromocionesState();
}

class _PantallaGestionPromocionesState
    extends ConsumerState<PantallaGestionPromociones> {
  bool _modoGrilla = false;
  String _busqueda = '';

  void _abrirFormulario(String barberiaId, [ModeloPromocion? promo]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioPromocion(
        promocion: promo,
        barberiaId: barberiaId,
        alGuardar: (nueva) => ref
            .read(controladorPromocionesAdminProvider.notifier)
            .guardar(nueva),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(controladorAutenticacionProvider).value;
    final promocionesState = ref.watch(controladorPromocionesAdminProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(controladorPromocionesAdminProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    final barberiaId = perfil?.barberiaId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promociones y Eventos'),
        actions: [
          IconButton(
            icon: Icon(_modoGrilla ? Icons.view_list : Icons.grid_view),
            tooltip: _modoGrilla ? 'Cambiar a Lista' : 'Cambiar a Grilla',
            onPressed: () => setState(() => _modoGrilla = !_modoGrilla),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(controladorPromocionesAdminProvider.future),
        child: promocionesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (promociones) {
            final filtradas = promociones
                .where(
                  (p) =>
                      p.titulo.toLowerCase().contains(
                        _busqueda.toLowerCase(),
                      ) ||
                      (p.descripcion ?? '').toLowerCase().contains(
                        _busqueda.toLowerCase(),
                      ),
                )
                .toList();

            return Column(
              children: [
                // Buscador y Selector de Vista
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar promoción...',
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
                              '${filtradas.length} Promociones creadas',
                              style: TipografiaApp.bodySm.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.view_list, size: 18),
                                label: Text('Lista'),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.grid_view, size: 18),
                                label: Text('Cuadros'),
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

                // Lista de Promociones
                Expanded(
                  child: filtradas.isEmpty
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 64),
                              child: Center(
                                child: Text(
                                  'No hay promociones registradas.',
                                  style: TipografiaApp.bodyMd.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: filtradas.length,
                          itemBuilder: (context, index) {
                            final promo = filtradas[index];
                            return TarjetaPromocionAdmin(
                              promocion: promo,
                              onEditar: () =>
                                  _abrirFormulario(barberiaId, promo),
                              onVerUsos: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PantallaUsosPromocion(promocion: promo),
                                  ),
                                );
                              },
                              onCambiarEstado: (activo) => ref
                                  .read(
                                    controladorPromocionesAdminProvider
                                        .notifier,
                                  )
                                  .cambiarEstado(
                                    promocionId: promo.id,
                                    activo: activo,
                                  ),
                              onEliminar: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar promoción'),
                                    content: Text(
                                      '¿Seguro que deseas eliminar "${promo.titulo}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          ref
                                              .read(
                                                controladorPromocionesAdminProvider
                                                    .notifier,
                                              )
                                              .eliminar(promo.id);
                                        },
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton.icon(
          onPressed: () => _abrirFormulario(barberiaId),
          icon: const Icon(Icons.add, size: 22),
          label: const Text(
            'NUEVA PROMOCIÓN',
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