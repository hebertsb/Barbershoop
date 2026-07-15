import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../componentes/boton_facebook.dart';
import '../componentes/boton_google.dart';
import '../controladores/controlador_autenticacion.dart';

class PantallaInicioSesion extends ConsumerWidget {
  const PantallaInicioSesion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorAutenticacionProvider);

    ref.listen(controladorAutenticacionProvider, (anterior, siguiente) {
      if (siguiente.hasError && !siguiente.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(siguiente.error.toString())),
        );
      }
    });

    final cargando = estado.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'BarberApp',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),
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
