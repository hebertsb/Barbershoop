import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nucleo/configuracion/cliente_supabase.dart';
import 'nucleo/configuracion/tema_app.dart';
import 'nucleo/enrutador/enrutador_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ClienteSupabase.inicializar();
  runApp(const ProviderScope(child: BarberApp()));
}

class BarberApp extends StatelessWidget {
  const BarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BarberApp',
      theme: TemaApp.claro,
      routerConfig: enrutadorApp,
      debugShowCheckedModeBanner: false,
    );
  }
}
