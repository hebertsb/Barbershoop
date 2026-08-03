import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_sucursal.dart';
import '../componentes/formulario_barbero.dart';
import '../componentes/tarjeta_barbero_cuadro.dart';
import '../componentes/tarjeta_barbero_lista.dart';
import '../controladores/controlador_barberos.dart';
import '../controladores/controlador_sucursales.dart';

class PantallaGestionBarberos extends ConsumerStatefulWidget {
  const PantallaGestionBarberos({super.key});

  @override
  ConsumerState<PantallaGestionBarberos> createState() =>
      _PantallaGestionBarberosState();
}

class _PantallaGestionBarberosState
    extends ConsumerState<PantallaGestionBarberos> {
  bool _modoGrilla = true;
  String _busqueda = '';
  bool _bloqueandoSelectores = false;
  FocusScopeNode? _focusScopeNode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nuevoScope = FocusScope.of(context);
    if (!identical(_focusScopeNode, nuevoScope)) {
      _focusScopeNode?.removeListener(_alCambiarFoco);
      _focusScopeNode = nuevoScope;
      _focusScopeNode!.addListener(_alCambiarFoco);
    }
  }

  /// Reacciona de forma proactiva al foco del buscador: apenas toma foco
  /// (teclado abriéndose) bloquea los `SelectorNivelBarbero` de las tarjetas
  /// YA, antes de que el usuario llegue a tocar alguno. Así el hit-test de un
  /// toque posterior sobre un selector ve `absorbing == true` y su menú nunca
  /// se abre con el layout todavía en posición "con teclado abierto". Al
  /// perder el foco del todo, espera a que termine la animación de cierre
  /// del teclado (~300ms) antes de reactivarlos.
  void _alCambiarFoco() {
    final tieneFoco = _focusScopeNode?.hasFocus ?? false;
    if (tieneFoco && !_bloqueandoSelectores) {
      setState(() => _bloqueandoSelectores = true);
    } else if (!tieneFoco && _bloqueandoSelectores) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _bloqueandoSelectores = false);
      });
    }
  }

  @override
  void dispose() {
    _focusScopeNode?.removeListener(_alCambiarFoco);
    super.dispose();
  }

  void _abrirFormulario(List<ModeloSucursal> sucursales) {
    if (sucursales.where((s) => s.activo).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas registrar al menos una sucursal activa.'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioBarbero(
        sucursales: sucursales,
        alGuardar: (email, sucursalId, especialidades) {
          return ref
              .read(controladorBarberosProvider.notifier)
              .invitarBarbero(
                email: email,
                sucursalId: sucursalId,
                especialidades: especialidades,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barberosState = ref.watch(controladorBarberosProvider);
    final sucursalesState = ref.watch(controladorSucursalesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(controladorBarberosProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    final sucursales = sucursalesState.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Barberos'),
        actions: [
          IconButton(
            icon: Icon(_modoGrilla ? Icons.view_list : Icons.grid_view),
            tooltip: _modoGrilla ? 'Cambiar a Lista' : 'Cambiar a Grilla',
            onPressed: () => setState(() => _modoGrilla = !_modoGrilla),
          ),
        ],
      ),
      body: barberosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (barberos) {
          final filtrados = barberos
              .where(
                (b) =>
                    (b.nombrePerfil ?? '').toLowerCase().contains(
                      _busqueda.toLowerCase(),
                    ) ||
                    (b.emailPerfil ?? '').toLowerCase().contains(
                      _busqueda.toLowerCase(),
                    ),
              )
              .toList();

          return Column(
            children: [
              // Barra de Búsqueda y Filtro de Vista
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar barbero por nombre o correo...',
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
                            '${filtrados.length} Barberos registrados',
                            style: TipografiaApp.bodySm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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

              // Lista o Grilla de Barberos
              Expanded(
                child: Listener(
                  // El buscador vive fuera de este bloque; los selectores de
                  // nivel de cada tarjeta viven acá adentro. Si el buscador
                  // tiene foco y el admin toca un selector, este toque debe
                  // sacarle el foco al buscador YA (antes de que el propio
                  // `PopupMenuButton` intente abrir su menú), porque mientras
                  // `_bloqueandoSelectores` sea true el `AbsorbPointer` de
                  // `SelectorNivelBarbero` absorbe el toque y su lógica
                  // interna (que de otro modo dispararía el unfocus solita al
                  // empujar su propia ruta) nunca llega a ejecutarse.
                  onPointerDown: (_) {
                    if (_focusScopeNode?.hasFocus ?? false) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: filtrados.isEmpty
                      ? Center(
                          child: Text(
                            'No hay barberos para mostrar.',
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
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            // Alto fijo (no `childAspectRatio`): contenido real de
                            // TarjetaBarberoCuadro ≈ padding 12*2 + avatar 72 + spacing
                            // 10 + nombre (~24) + spacing 2 + sucursal (~20) + spacing 6
                            // + selector de nivel (~24) + fila opcional de medallas
                            // (~19, solo si ganó alguna) + fila de acciones (~40) ≈
                            // 241px con medallas -- 300 deja margen real con texto
                            // escalado (260 se quedaba corto y desbordaba en tablet,
                            // bug real reportado). Un `childAspectRatio` fijo se probó
                            // antes y era incorrecto en pantallas anchas: con pocas
                            // columnas la celda se ensancha mucho y esa misma
                            // proporción estira la altura también, dejando una franja
                            // vacía enorme debajo del texto. `maxCrossAxisExtent` fija
                            // el ancho ideal por tarjeta y Flutter decide solo cuántas
                            // columnas entran, sin ese problema.
                            maxCrossAxisExtent: 200,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent: 300,
                          ),
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            final barbero = filtrados[index];
                            return TarjetaBarberoCuadro(
                              barbero: barbero,
                              sucursalNombre: _obtenerNombreSucursal(
                                barbero.sucursalId,
                                sucursales,
                              ),
                              sucursales: sucursales,
                              bloqueadoSelector: _bloqueandoSelectores,
                            );
                          },
                        )
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filtrados.length,
                              itemBuilder: (context, index) {
                                final barbero = filtrados[index];
                                return TarjetaBarberoLista(
                                  barbero: barbero,
                                  sucursalNombre: _obtenerNombreSucursal(
                                    barbero.sucursalId,
                                    sucursales,
                                  ),
                                  sucursales: sucursales,
                                  bloqueadoSelector: _bloqueandoSelectores,
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton.icon(
          onPressed: () => _abrirFormulario(sucursales),
          icon: const Icon(Icons.person_add_outlined, size: 22),
          label: const Text(
            'NUEVO BARBERO / INVITAR',
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

  String _obtenerNombreSucursal(
    String? sucursalId,
    List<ModeloSucursal> sucursales,
  ) {
    if (sucursalId == null) return 'Sin asignación';
    final candidatos = sucursales.where((s) => s.id == sucursalId).toList();
    return candidatos.isEmpty ? 'Sucursal' : candidatos.first.nombre;
  }
}