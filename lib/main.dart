import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'funcionalidades/actualizacion_app/dominio/modelo_version_app.dart';
import 'funcionalidades/actualizacion_app/presentacion/componentes/dialogo_actualizacion.dart';
import 'nucleo/configuracion/cliente_supabase.dart';
import 'nucleo/configuracion/constantes.dart';
import 'nucleo/configuracion/navegador_raiz.dart';
import 'nucleo/configuracion/tema_app.dart';
import 'nucleo/enrutador/enrutador_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ClienteSupabase.inicializar();
  try {
    await GoogleSignIn.instance
        .initialize(serverClientId: Constantes.googleWebClientId)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Google Sign In fallo/timeout: ');
  }
  runApp(const ProviderScope(child: BarberApp()));
}

class BarberApp extends ConsumerStatefulWidget {
  const BarberApp({super.key});

  @override
  ConsumerState<BarberApp> createState() => _BarberAppState();
}

class _BarberAppState extends ConsumerState<BarberApp> {
  bool _dialogoActualizacionMostrado = false;

  void _mostrarDialogoActualizacionSiCorresponde(
    ModeloVersionApp? version, {
    int intentosRestantes = 5,
  }) {
    if (version == null || _dialogoActualizacionMostrado) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dialogoActualizacionMostrado) return;
      final contexto = navegadorRaizKey.currentContext;
      if (contexto == null) {
        if (intentosRestantes > 0) {
          _mostrarDialogoActualizacionSiCorresponde(
            version,
            intentosRestantes: intentosRestantes - 1,
          );
        }
        return;
      }
      _dialogoActualizacionMostrado = true;
      showDialog<void>(
        context: contexto,
        barrierDismissible: !version.obligatoria,
        builder: (_) => DialogoActualizacion(version: version),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrutador = ref.watch(enrutadorAppProvider);
    return MaterialApp.router(
      title: 'BarberApp',
      routerConfig: enrutador,
      theme: TemaApp.claro(),
      darkTheme: TemaApp.oscuro(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
