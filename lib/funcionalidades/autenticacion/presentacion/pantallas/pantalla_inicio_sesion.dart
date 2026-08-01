import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
