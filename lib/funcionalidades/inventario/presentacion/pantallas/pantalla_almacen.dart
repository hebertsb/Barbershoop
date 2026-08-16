import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../administracion/presentacion/controladores/controlador_sucursales.dart';
import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../componentes/alerta_stock_minimo.dart';
import '../componentes/formulario_asignar_insumo.dart';
import '../componentes/formulario_insumo.dart';
import '../componentes/tarjeta_insumo.dart';
import '../controladores/controlador_almacen.dart';

class PantallaAlmacen extends ConsumerStatefulWidget {
  const PantallaAlmacen({super.key});

  @override
  ConsumerState<PantallaAlmacen> createState() => _PantallaAlmacenState();
}

class _PantallaAlmacenState extends ConsumerState<PantallaAlmacen> {
  String? _sucursalSeleccionadaId;
  String? _sucursalIdVisible;
  String _busqueda = '';
  Timer? _timerRefresco;

  @override
  void initState() {
    super.initState();
    _timerRefresco = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      final sucursalId = _sucursalIdVisible;
      if (sucursalId == null) return;
      ref.invalidate(controladorAlmacenProvider(sucursalId));
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
    final sucursalesState = ref.watch(controladorSucursalesProvider);
    final sucursalesActivas = (sucursalesState.value ?? [])
        .where((s) => s.activo)
        .toList();

    if (_sucursalSeleccionadaId != null &&
        !sucursalesActivas.any((s) => s.id == _sucursalSeleccionadaId)) {
      _sucursalSeleccionadaId = null;
    }
    final primeraActivaId = sucursalesActivas.isEmpty
        ? null
        : sucursalesActivas.first.id;
    final sucursalId = _sucursalSeleccionadaId ?? primeraActivaId;

    if (sucursalId == null) {
      if (sucursalesState.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const Scaffold(
        body: Center(child: Text('No hay una sucursal disponible.')),
      );
    }
    _sucursalIdVisible = sucursalId;

    final insumosState = ref.watch(controladorAlmacenProvider(sucursalId));

    ref.listen(controladorAlmacenProvider(sucursalId), (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Almacén e Inventario'),
        actions: [
          if (sucursalesActivas.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sucursalId,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    style: TipografiaApp.labelMd.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    items: sucursalesActivas
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.store_outlined,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(s.nombre),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _sucursalSeleccionadaId = val),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(controladorAlmacenProvider(sucursalId).future),
        child: insumosState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (insumosOriginales) {
            final insumos = insumosOriginales.where((i) {
              if (_busqueda.trim().isEmpty) return true;
              final q = _busqueda.trim().toLowerCase();
              return i.nombre.toLowerCase().contains(q) ||
                  (i.categoria != null && i.categoria!.toLowerCase().contains(q));
            }).toList();

            final bajoMinimo = insumosOriginales.where((i) => i.bajoMinimo).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Barra de búsqueda
                TextField(
                  onChanged: (val) => setState(() => _busqueda = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar insumo por nombre o categoría...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                AlertaStockMinimo(insumos: bajoMinimo),

                if (insumos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        _busqueda.trim().isEmpty
                            ? 'No hay insumos registrados en esta sucursal.'
                            : 'No se encontraron insumos para "$_busqueda".',
                        style: TipografiaApp.bodyMd.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                for (final insumo in insumos)
                  Dismissible(
                    key: Key('insumo-${insumo.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: colorScheme.onError,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      final confirmar = await _confirmarEliminarInsumo(
                        context,
                        insumo.nombre,
                      );
                      if (!confirmar) return false;
                      try {
                        await ref
                            .read(
                              controladorAlmacenProvider(sucursalId).notifier,
                            )
                            .eliminarInsumo(insumo.id);
                        return true;
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                        return false;
                      }
                    },
                    child: TarjetaInsumo(
                      insumo: insumo,
                      onTap: () => _abrirFormularioInsumo(
                        context,
                        perfil?.barberiaId ?? '',
                        sucursalId,
                        insumo: insumo,
                      ),
                      onEditar: () => _abrirFormularioInsumo(
                        context,
                        perfil?.barberiaId ?? '',
                        sucursalId,
                        insumo: insumo,
                      ),
                      onAsignar: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => FormularioAsignarInsumo(
                            insumo: insumo,
                            alAsignar:
                                ({required barberoId, required cantidad}) =>
                                    ref
                                        .read(
                                          controladorAlmacenProvider(
                                            sucursalId,
                                          ).notifier,
                                        )
                                        .asignarABarbero(
                                          insumoId: insumo.id,
                                          barberoId: barberoId,
                                          cantidad: cantidad,
                                        ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormularioInsumo(
          context,
          perfil?.barberiaId ?? '',
          sucursalId,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Insumo'),
      ),
    );
  }

  void _abrirFormularioInsumo(
    BuildContext context,
    String barberiaId,
    String sucursalId, {
    dynamic insumo,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioInsumo(
        insumo: insumo,
        barberiaId: barberiaId,
        sucursalId: sucursalId,
        alGuardar: (nuevo) => ref
            .read(controladorAlmacenProvider(sucursalId).notifier)
            .guardarInsumo(nuevo),
      ),
    );
  }

  Future<bool> _confirmarEliminarInsumo(
    BuildContext context,
    String nombreInsumo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar insumo?'),
        content: Text(
          'Se va a eliminar "$nombreInsumo" y también sus asignaciones a '
          'barberos y su historial de reportes (dañado/agotado/perdido). '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return confirmar ?? false;
  }
}
