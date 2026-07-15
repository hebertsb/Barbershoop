import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';

class PantallaAdministracionDashboard extends ConsumerWidget {
  const PantallaAdministracionDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(controladorAutenticacionProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text(
                        '¿Estás seguro de que deseas salir?',
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
                                .read(controladorAutenticacionProvider.notifier)
                                .cerrarSesion();
                          },
                          child: const Text('Salir'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${perfil?.nombre ?? "Administrador"}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Gestiona los datos y la configuración de tu barbería.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _TarjetaMenu(
                      titulo: 'Sucursales',
                      descripcion: 'Direcciones y horarios',
                      icono: Icons.storefront,
                      color: Colors.blueGrey,
                      alPresionar:
                          () => context.push('/administracion/sucursales'),
                    ),
                    _TarjetaMenu(
                      titulo: 'Servicios',
                      descripcion: 'Precios y duración',
                      icono: Icons.content_cut,
                      color: Colors.teal,
                      alPresionar:
                          () => context.push('/administracion/servicios'),
                    ),
                    _TarjetaMenu(
                      titulo: 'Barberos',
                      descripcion: 'Personal y disponibilidad',
                      icono: Icons.people,
                      color: Colors.indigo,
                      alPresionar:
                          () => context.push('/administracion/barberos'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaMenu extends StatelessWidget {
  const _TarjetaMenu({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.alPresionar,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withAlpha(40),
                child: Icon(icono, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
