import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/enum_rol_usuario.dart';
import '../componentes/boton_facebook.dart';
import '../componentes/boton_google.dart';
import '../controladores/controlador_autenticacion.dart';

class PantallaInicioSesion extends ConsumerWidget {
  const PantallaInicioSesion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorAutenticacionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(controladorAutenticacionProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(siguiente.error.toString())));
      }
    });

    final cargando = estado.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.content_cut, size: 40, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'BARBERAPP',
                  style: TipografiaApp.headlineSm.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Bienvenido de nuevo',
                  textAlign: TextAlign.center,
                  style: TipografiaApp.headlineLgMobile.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa a tu cuenta para gestionar tus citas',
                  textAlign: TextAlign.center,
                  style: TipografiaApp.bodyMd.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                BotonGoogle(
                  cargando: cargando,
                  alPresionar: () => ref
                      .read(controladorAutenticacionProvider.notifier)
                      .iniciarSesionConGoogle(),
                ),
                const SizedBox(height: 16),
                BotonFacebook(
                  cargando: cargando,
                  alPresionar: () => ref
                      .read(controladorAutenticacionProvider.notifier)
                      .iniciarSesionConFacebook(),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'O ingresa directamente como:',
                  style: TipografiaApp.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 18),
                      label: const Text('Admin'),
                      onPressed: cargando
                          ? null
                          : () => ref
                              .read(controladorAutenticacionProvider.notifier)
                              .ingresarComoRol(RolUsuario.admin),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.content_cut, size: 18),
                      label: const Text('Barbero'),
                      onPressed: cargando
                          ? null
                          : () => ref
                              .read(controladorAutenticacionProvider.notifier)
                              .ingresarComoRol(RolUsuario.barbero),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.badge, size: 18),
                      label: const Text('Secretaria'),
                      onPressed: cargando
                          ? null
                          : () => ref
                              .read(controladorAutenticacionProvider.notifier)
                              .ingresarComoRol(RolUsuario.secretaria),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.person, size: 18),
                      label: const Text('Cliente'),
                      onPressed: cargando
                          ? null
                          : () => ref
                              .read(controladorAutenticacionProvider.notifier)
                              .ingresarComoRol(RolUsuario.cliente),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
