import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_sucursal.dart';
import '../componentes/formulario_sucursal.dart';
import '../controladores/controlador_sucursales.dart';

class PantallaGestionSucursales extends ConsumerStatefulWidget {
  const PantallaGestionSucursales({super.key});

  @override
  ConsumerState<PantallaGestionSucursales> createState() =>
      _PantallaGestionSucursalesState();
}

class _PantallaGestionSucursalesState
    extends ConsumerState<PantallaGestionSucursales> {
  bool _modoGrilla = true;
  String _busqueda = '';

  void _abrirFormulario([ModeloSucursal? sucursal]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormularioSucursal(
        sucursal: sucursal,
        alGuardar: (nuevaSucursal) {
          return ref
              .read(controladorSucursalesProvider.notifier)
              .guardarSucursal(nuevaSucursal);
        },
      ),
    );
  }

  String _formatearHorario(String? inicio, String? fin) {
    if (inicio == null || fin == null || inicio.isEmpty || fin.isEmpty) {
      return 'Sin horario configurado';
    }
    final iniStr = inicio.length >= 5 ? inicio.substring(0, 5) : inicio;
    final finStr = fin.length >= 5 ? fin.substring(0, 5) : fin;
    return '$iniStr - $finStr';
  }

  @override
  Widget build(BuildContext context) {
    final sucursalesState = ref.watch(controladorSucursalesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(controladorSucursalesProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(siguiente.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Sucursales'),
        actions: [
          IconButton(
            icon: Icon(_modoGrilla ? Icons.view_list : Icons.grid_view),
            tooltip: _modoGrilla ? 'Cambiar a Lista' : 'Cambiar a Grilla',
            onPressed: () => setState(() => _modoGrilla = !_modoGrilla),
          ),
        ],
      ),
      body: sucursalesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (sucursales) {
          final filtradas = sucursales
              .where(
                (s) =>
                    s.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
                    (s.direccion ?? '')
                        .toLowerCase()
                        .contains(_busqueda.toLowerCase()) ||
                    (s.managerNombre ?? '')
                        .toLowerCase()
                        .contains(_busqueda.toLowerCase()),
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
                        hintText: 'Buscar sucursal por nombre, dirección...',
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
                            '${filtradas.length} Sucursales registradas',
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

              // Contenido principal: Grilla o Lista
              Expanded(
                child: filtradas.isEmpty
                    ? Center(
                        child: Text(
                          'No hay sucursales para mostrar.',
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
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 260,
                        ),
                        itemCount: filtradas.length,
                        itemBuilder: (context, index) {
                          final sucursal = filtradas[index];
                          return _TarjetaSucursalCuadro(
                            sucursal: sucursal,
                            horarioStr: _formatearHorario(
                              sucursal.horarioApertura,
                              sucursal.horarioCierre,
                            ),
                            onTapEditar: () => _abrirFormulario(sucursal),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filtradas.length,
                        itemBuilder: (context, index) {
                          final sucursal = filtradas[index];
                          return _TarjetaSucursalLista(
                            sucursal: sucursal,
                            horarioStr: _formatearHorario(
                              sucursal.horarioApertura,
                              sucursal.horarioCierre,
                            ),
                            onTapEditar: () => _abrirFormulario(sucursal),
                          );
                        },
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
          onPressed: () => _abrirFormulario(),
          icon: const Icon(Icons.add_location_alt_outlined, size: 22),
          label: const Text(
            'NUEVA SUCURSAL / REGISTRAR',
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

class _TarjetaSucursalCuadro extends StatelessWidget {
  const _TarjetaSucursalCuadro({
    required this.sucursal,
    required this.horarioStr,
    required this.onTapEditar,
  });

  final ModeloSucursal sucursal;
  final String horarioStr;
  final VoidCallback onTapEditar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = sucursal.urlImagen;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner/Foto de sucursal
          Stack(
            children: [
              Container(
                height: 90,
                width: double.infinity,
                color: colorScheme.surfaceContainerHigh,
                child: url != null && url.isNotEmpty
                    ? Image.network(url, fit: BoxFit.cover)
                    : Icon(
                        Icons.storefront_outlined,
                        size: 44,
                        color: colorScheme.primary,
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (sucursal.activo ? Colors.green : Colors.red)
                        .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sucursal.activo ? 'Activa' : 'Inactiva',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sucursal.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TipografiaApp.bodyMd.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        sucursal.direccion ?? 'Sin dirección',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaApp.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        horarioStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TipografiaApp.bodySm.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: onTapEditar,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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

class _TarjetaSucursalLista extends StatelessWidget {
  const _TarjetaSucursalLista({
    required this.sucursal,
    required this.horarioStr,
    required this.onTapEditar,
  });

  final ModeloSucursal sucursal;
  final String horarioStr;
  final VoidCallback onTapEditar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = sucursal.urlImagen;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: url != null && url.isNotEmpty
              ? Image.network(url, fit: BoxFit.cover)
              : Icon(Icons.storefront_outlined, color: colorScheme.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sucursal.nombre,
                style: TipografiaApp.bodyMd.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (sucursal.activo ? Colors.green : Colors.red)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sucursal.activo ? 'Activa' : 'Inactiva',
                style: TextStyle(
                  color: sucursal.activo ? Colors.green : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📍 ${sucursal.direccion ?? "Sin dirección"}',
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '🕒 $horarioStr',
                style: TipografiaApp.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_note),
          color: colorScheme.primary,
          onPressed: onTapEditar,
        ),
      ),
    );
  }
}
