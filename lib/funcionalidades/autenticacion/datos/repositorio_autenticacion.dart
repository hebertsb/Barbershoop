import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../nucleo/configuracion/cliente_supabase.dart';
import '../../../nucleo/errores/excepciones_app.dart';
import '../dominio/modelo_barberia_resumen.dart';
import '../dominio/modelo_perfil.dart';

abstract class RepositorioAutenticacion {
  Future<void> iniciarSesionConGoogle();
  Future<void> iniciarSesionConFacebook();
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
      if (idToken == null) {
        throw const ExcepcionDesconocida();
      }
      await _cliente.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      debugPrint('GoogleSignInException: ${e.description}');
      throw const ExcepcionDesconocida();
    } on SocketException {
      throw const ExcepcionRed();
    } on AuthException catch (e) {
      debugPrint('AuthException Google: ${e.message}');
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> iniciarSesionConFacebook() async {
    try {
      final resultado = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
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
    } on AuthException catch (e) {
      debugPrint('AuthException Facebook: ${e.message}');
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<ModeloPerfil?> obtenerPerfilActual() async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final fila = await _cliente.from('perfiles').select().eq('id', uid).maybeSingle();
      if (fila == null) return null;
      return ModeloPerfil.desdeJson(fila);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<List<ModeloBarberiaResumen>> obtenerBarberiasActivas() async {
    try {
      final filas = await _cliente
          .from('barberias')
          .select('id, nombre')
          .eq('activo', true)
          .order('nombre');
      return filas.map(ModeloBarberiaResumen.desdeJson).toList();
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException {
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> asignarBarberia(String barberiaId) async {
    final uid = _cliente.auth.currentUser?.id;
    if (uid == null) throw const ExcepcionPermiso();
    try {
      await _cliente.from('perfiles').update({'barberia_id': barberiaId}).eq('id', uid);
    } on SocketException {
      throw const ExcepcionRed();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw const ExcepcionPermiso();
      throw const ExcepcionDesconocida();
    }
  }

  @override
  Future<void> cerrarSesion() async {
    await _cliente.auth.signOut();
    await GoogleSignIn.instance.signOut();
    await FacebookAuth.instance.logOut();
  }
}
