import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/selector_imagen.dart';
import '../../../../nucleo/configuracion/constantes.dart';
import '../../../../nucleo/utilidades/contacto_whatsapp.dart';
import '../../../autenticacion/presentacion/controladores/controlador_autenticacion.dart';
import '../controladores/controlador_barberos.dart';

/// Pantalla donde el barbero edita su propio perfil pblico: foto,
/// descripcin y especialidades. `controladorBarberosProvider` trae todos
/// los barberos del tenant (RLS de `barberos` solo exige mismo
/// `barberia_id`, no rol admin) y ac se filtra a la propia fila por
/// `perfilId`.
class PantallaMiPerfilBarbero extends ConsumerStatefulWidget {
  const PantallaMiPerfilBarbero({super.key});

  @override
  ConsumerState<PantallaMiPerfilBarbero> createState() =>
      _PantallaMiPerfilBarberoState();
}

class _PantallaMiPerfilBarberoState
    extends ConsumerState<PantallaMiPerfilBarbero> {
  final _descripcionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _especialidadCtrl = TextEditingController();
  final List<String> _especialidades = [];
  String? _urlFoto;
  bool _cargando = false;
  bool _inicializado = false;
  String? _errorMensaje;

  void _agregarEspecialidad() {
    final texto = _especialidadCtrl.text.trim().toLowerCase();
    if (texto.isNotEmpty && !_especialidades.contains(texto)) {
      setState(() {
        _especialidades.add(texto);
        _especialidadCtrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _telefonoCtrl.dispose();
    _especialidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final telefonoTexto = _telefonoCtrl.text.trim();
    final telefonoNormalizado = telefonoTexto.isEmpty
        ? null
        : normalizarTelefonoWhatsapp(telefonoTexto);
    if (telefonoTexto.isNotEmpty && telefonoNormalizado == null) {
      setState(() => _errorMensaje = 'El nmero de celular no es vlido.');
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      await ref
          .read(controladorBarberosProvider.notifier)
          .guardarMiPerfil(
            descripcion: _descripcionCtrl.text.trim().isEmpty
                ? null
                : _descripcionCtrl.text.trim(),
            especialidades: _especialidades,
            urlFoto: _urlFoto,
            telefono: telefonoNormalizado,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
      }
    } catch (e) {
      if (mounted) setState(() => _errorMensaje = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(controladorAutenticacionProvider).value;
    final miBarbero = (ref.watch(controladorBarberosProvider).value ?? [])
        .where((b) => b.perfilId == perfil?.id)
        .toList();

    // Precarga una sola vez, cuando los datos del propio barbero llegan por
    // primera vez -- si se hiciera en cada build, pisara lo que el usuario
    // ya escribi cada vez que el provider se refresca de fondo.
    if (!_inicializado && miBarbero.isNotEmpty) {
      _inicializado = true;
      _descripcionCtrl.text = miBarbero.first.descripcion ?? '';
      _telefonoCtrl.text = miBarbero.first.telefonoPerfil ?? '';
      // Se fusionan las especialidades de TODAS las filas (una por sucursal)
      // en vez de tomar solo la primera: "Guardar" sobreescribe todas las
      // filas a la vez, as que quedarse con .first perdera en silencio
      // las especialidades cargadas en otra sucursal.
      final especialidadesUnicas = <String>{};
      for (final b in miBarbero) {
        especialidadesUnicas.addAll(b.especialidades);
      }
      _especialidades.addAll(especialidadesUnicas);
      _urlFoto = perfil?.urlFoto;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectorImagen(
              bucket: Constantes.bucketImagenesApp,
              carpeta: 'perfiles',
              urlActual: _urlFoto,
              alSubir: (url) => setState(() => _urlFoto = url),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripcin',
                hintText: 'Ej. Especialista en fades y diseo de barba',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Celular (WhatsApp)',
                hintText: 'Ej. +591 71234567',
                helperText:
                    'Opcional. Si lo cargs, tus clientes van a poder '
                    'contactarte por WhatsApp desde su cita.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _especialidadCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Especialidades',
                      border: OutlineInputBorder(),
                      hintText: 'Ej. barba, degrades, cejas',
                    ),
                    onFieldSubmitted: (_) => _agregarEspecialidad(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _agregarEspecialidad,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _especialidades.map((esp) {
                return InputChip(
                  label: Text(esp),
                  onDeleted: () {
                    setState(() => _especialidades.remove(esp));
                  },
                );
              }).toList(),
            ),
            if (_errorMensaje != null) ...[
              const SizedBox(height: 16),
              Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _cargando
                  ? const CircularProgressIndicator()
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
