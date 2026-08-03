import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../configuracion/cliente_supabase.dart';
import '../errores/excepciones_app.dart';

abstract class RepositorioAlmacenamiento {
  Future<String> subirImagen({
    required String bucket,
    required String ruta,
    required File archivo,
    bool upsert = true,
  });
}

class RepositorioAlmacenamientoSupabase implements RepositorioAlmacenamiento {
  RepositorioAlmacenamientoSupabase({SupabaseClient? cliente})
      : _cliente = cliente ?? ClienteSupabase.instancia;

  final SupabaseClient _cliente;

  @override
  Future<String> subirImagen({
    required String bucket,
    required String ruta,
    required File archivo,
    bool upsert = true,
  }) async {
    try {
      await _cliente.storage
          .from(bucket)
          .upload(ruta, archivo, fileOptions: FileOptions(upsert: upsert));
      return _cliente.storage.from(bucket).getPublicUrl(ruta);
    } on SocketException {
      throw const ExcepcionRed();
    } on StorageException catch (e) {
      throw ExcepcionDesconocida(e.message);
    } catch (e) {
      throw ExcepcionDesconocida(e.toString());
    }
  }
}
