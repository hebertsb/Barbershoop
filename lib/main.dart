import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'nucleo/configuracion/cliente_supabase.dart';
import 'nucleo/configuracion/constantes.dart';
import 'nucleo/configuracion/tema_app.dart';
import 'nucleo/enrutador/enrutador_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ClienteSupabase.inicializar();
  await GoogleSignIn.instance.initialize(serverClientId: Constantes.googleWebClientId);
  runApp(const ProviderScope(child: BarberApp()));
}

class BarberApp extends ConsumerWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrutador = ref.watch(enrutadorAppProvider);
    return MaterialApp.router(
      title: 'BarberApp',
      theme: TemaApp.claro,
      routerConfig: enrutador,
      debugShowCheckedModeBanner: false,
    );
  }
}
