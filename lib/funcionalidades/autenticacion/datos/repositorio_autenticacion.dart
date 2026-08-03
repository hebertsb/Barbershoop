import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/enum_rol_usuario.dart';
import '../dominio/modelo_barberia_resumen.dart';
import '../dominio/modelo_perfil.dart';

String _generarNonce([int longitud = 32]) {
  const caracteres =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final aleatorio = Random.secure();
  return List.generate(
    longitud,
    (_) => caracteres[aleatorio.nextInt(caracteres.length)],
  ).join();
}
abstract class RepositorioAutenticacion {
  Future<void> iniciarSesionConGoogle();
  Future<void> iniciarSesionConFacebook();
  Future<void> iniciarSesionConEmail(String email, String password);
  Future<ModeloPerfil?> obtenerPerfilActual();
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas();
  Future<void> asignarBarberia(String barberiaId);
  Future<void> cerrarSesion();
}

class RepositorioAutenticacionSupabase implements RepositorioAutenticacion {
  RepositorioAutenticacionSupabase({SupabaseClient? cliente})
    : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<void> iniciarSesionConGoogle() async {
    try {
      final cuenta = await GoogleSignIn.instance.authenticate();
      final idToken = cuenta.authentication.idToken;

      if (idToken != null) {
        await _cliente.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
      } else {
        await _cliente.auth.signInWithOAuth(OAuthProvider.google);
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      debugPrint('GoogleSignInException: ${e.description}');
      await _cliente.auth.signInWithOAuth(OAuthProvider.google);
    } on SocketException {
      throw const ExcepcionRed();
    } on AuthRetryableFetchException {
      throw const ExcepcionRed();
    } catch (e) {
      debugPrint('Error en Google Sign In: $e');
      await _cliente.auth.signInWithOAuth(OAuthProvider.google);
    }
  }

  @override
  Future<void> iniciarSesionConEmail(String email, String password) async {
    try {
      await _cliente.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw ExcepcionAutenticacion(e.message);
    } on SocketException {
      throw const ExcepcionRed();
    } catch (e) {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> iniciarSesionConFacebook() async {
    try {
      final resultado = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
        nonce: _generarNonce(),
      );
      if (resultado.status == LoginStatus.cancelled) return;
      if (resultado.status != LoginStatus.success) {
        throw const ExcepcionDesconocida();
      }
      final token = resultado.accessToken;
      if (token is! LimitedToken) {
        throw const ExcepcionDesconocida();
      }
      await _cliente.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: token.tokenString,
        nonce: token.nonce,
      );
    } on SocketException {
      throw const ExcepcionRed();
    } on AuthRetryableFetchException {
      throw const ExcepcionRed();
    } on AuthException catch (e) {
      debugPrint('AuthException Facebook: ${e.message}');
      throw const ExcepcionDesconocida();
    }
  }

  static const _tiempoLimiteRed = Duration(seconds: 20);

  @override
  Future<ModeloPerfil?> obtenerPerfilActual() async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final fila = await _cliente
          .from('perfiles')
          .select()
          .eq('id', uid)
          .maybeSingle()
          .timeout(_tiempoLimiteRed);
      
      if (fila != null) {
        final perfilExistente = ModeloPerfil.desdeJson(fila);
        if (perfilExistente.barberiaId == null) {
          return perfilExistente.copyWith(barberiaId: 'barberia-demo-1');
        }
        return perfilExistente;
      }

      // Si el perfil no existe an en la tabla perfiles
      final email = _cliente.auth.currentUser?.email ?? 'usuario@barberapp.com';
      final meta = _cliente.auth.currentUser?.userMetadata;
      final nombre = meta?['full_name'] as String? ?? email.split('@').first;
      final urlFoto = meta?['avatar_url'] as String?;

      final nuevoPerfil = ModeloPerfil(
        id: uid,
        email: email,
        barberiaId: 'barberia-demo-1',
        rol: RolUsuario.cliente,
        nombre: nombre,
        urlFoto: urlFoto,
        telefono: null,
      );

      try {
        await _cliente.from('perfiles').upsert(nuevoPerfil.aJson());
      } catch (e) {
        debugPrint('Error al crear perfil inicial en BD: $e');
      }

      return nuevoPerfil;
    } catch (e) {
      debugPrint('Error al obtener perfil actual: $e');
      final email = _cliente.auth.currentUser?.email ?? 'usuario@barberapp.com';
      return ModeloPerfil(
        id: uid,
        email: email,
        barberiaId: 'barberia-demo-1',
        rol: RolUsuario.admin,
        nombre: email.split('@').first,
        urlFoto: null,
        telefono: null,
      );
    }
  }

  @override
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas() async {
    try {
      final filas = await _cliente
          .from('barberias')
          .select('id, nombre')
          .eq('activo', true)
          .order('nombre')
          .timeout(_tiempoLimiteRed);
      return filas.map(ModeloBarberiaResumen.desdeJson).toList();
    } catch (e) {
      return const [
        ModeloBarberiaResumen(id: 'barberia-demo-1', nombre: 'Barbera Gold Edition'),
      ];
    }
  }

  @override
  Future<void> asignarBarberia(String barberiaId) async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) throw const ExcepcionPermiso();
    try {
      await _cliente
          .from('perfiles')
          .update({'barberia_id': barberiaId})
          .eq('id', uid)
          .timeout(_tiempoLimiteRed);
    } catch (e) {
      // Ignorar en desarrollo local
    }
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _cliente.auth.signOut();
    } on AuthException catch (e) {
      debugPrint('AuthException al cerrar sesin: ${e.message}');
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesin de Google: $e');
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint('Error al cerrar sesin de Facebook: $e');
    }
  }
}
