import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../datos/repositorio_accesos_admin.dart';
import '../../dominio/catalogo_accesos_admin.dart';

/// Pantalla real (no modal) con el catálogo completo de secciones de
/// administración, agrupadas por categoría y con buscador en vivo. Al ser
/// una pantalla en la pila de navegación (en vez del bottom sheet que era
/// antes), volver atrás desde cualquier sección abierta desde acá regresa a
/// esta lista -- no directo al dashboard.
class PantallaMasAdministracion extends ConsumerStatefulWidget {
  const PantallaMasAdministracion({super.key});

  @override
  ConsumerState<PantallaMasAdministracion> createState() =>
      _PantallaMasAdministracionState();
}

class _PantallaMasAdministracionState
    extends ConsumerState<PantallaMasAdministracion> {
  final _controladorBusqueda = TextEditingController();

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  void _abrirAcceso(AccesoAdmin acceso) {
    ref.read(repositorioAccesosAdminProvider).registrarAcceso(acceso.ruta);
    context.push(acceso.ruta);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final busqueda = _controladorBusqueda.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Menú de Administración')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controladorBusqueda,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar sección... (ej. "barb")',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: busqueda.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _controladorBusqueda.clear());
                        },
                      ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: busqueda.isEmpty
                  ? _ListaAgrupada(onAccesoSeleccionado: _abrirAcceso)
                  : _ListaFiltrada(
                      consulta: busqueda,
                      onAccesoSeleccionado: _abrirAcceso,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista del catálogo completo agrupada por sección. Cada sección es un
/// acordeón colapsable (arranca cerrado) para que la lista no se vea larga
/// apenas se abre el menú -- el admin expande solo la sección que le
/// interesa.
class _ListaAgrupada extends StatelessWidget {
  const _ListaAgrupada({required this.onAccesoSeleccionado});

  final ValueChanged<AccesoAdmin> onAccesoSeleccionado;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final grupos = agruparAccesosPorCategoria(catalogoAccesosAdmin);

    return ListView.builder(
      shrinkWrap: true,
      itemCount: grupos.length,
      itemBuilder: (context, index) {
        final grupo = grupos[index];
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            iconColor: colorScheme.primary,
            collapsedIconColor: colorScheme.primary,
            title: Text(
              grupo.key,
              style: TipografiaApp.bodySm.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              for (final acceso in grupo.value)
                _ItemAcceso(
                  acceso: acceso,
                  onTap: () => onAccesoSeleccionado(acceso),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Lista plana filtrada por texto de búsqueda, sin encabezados de sección.
class _ListaFiltrada extends StatelessWidget {
  const _ListaFiltrada({
    required this.consulta,
    required this.onAccesoSeleccionado,
  });

  final String consulta;
  final ValueChanged<AccesoAdmin> onAccesoSeleccionado;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resultados = filtrarAccesosAdmin(consulta, catalogoAccesosAdmin);

    if (resultados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: colorScheme.outline,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No se encontraron secciones para "$consulta"',
              textAlign: TextAlign.center,
              style: TipografiaApp.bodySm.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: resultados.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final acceso = resultados[index];
        return _ItemAcceso(
          acceso: acceso,
          onTap: () => onAccesoSeleccionado(acceso),
        );
      },
    );
  }
}

class _ItemAcceso extends StatelessWidget {
  const _ItemAcceso({required this.acceso, required this.onTap});

  final AccesoAdmin acceso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainerHigh,
        child: Icon(acceso.icono, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        acceso.titulo,
        style: TipografiaApp.bodyMd.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        acceso.subtitulo,
        style: TipografiaApp.bodySm.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.outline,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}