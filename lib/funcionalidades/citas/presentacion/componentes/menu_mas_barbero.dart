import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';

class ElementoMenuBarbero {
  const ElementoMenuBarbero({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.ruta,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final String ruta;
}

class MenuMasBarbero extends StatelessWidget {
  const MenuMasBarbero({super.key});

  static const List<ElementoMenuBarbero> elementos = [
    ElementoMenuBarbero(
      titulo: 'Mis Reseas',
      subtitulo: 'Calificaciones y comentarios de tus clientes',
      icono: Icons.star_outline,
      ruta: '/mis-resenas',
    ),
    ElementoMenuBarbero(
      titulo: 'Ranking',
      subtitulo: 'Tu posicin, premios e insignias',
      icono: Icons.emoji_events_outlined,
      ruta: '/mi-ranking',
    ),
    ElementoMenuBarbero(
      titulo: 'Mi Perfil',
      subtitulo: 'Tu foto, descripcin y especialidades',
      icono: Icons.person_outline,
      ruta: '/mi-perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.grid_view_outlined, color: ColoresApp.primario),
              const SizedBox(width: 8),
              Text(
                'Ms opciones',
                style: TipografiaApp.headlineSm.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: elementos.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final elem = elementos[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    child: Icon(
                      elem.icono,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    elem.titulo,
                    style: TipografiaApp.bodyMd.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    elem.subtitulo,
                    style: TipografiaApp.bodySm.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.outline,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(elem.ruta);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
