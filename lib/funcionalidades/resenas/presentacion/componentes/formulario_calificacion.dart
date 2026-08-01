import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';

class FormularioCalificacion extends StatefulWidget {
  const FormularioCalificacion({super.key, required this.alConfirmar});

  final Future<void> Function(int calificacion, String? comentario) alConfirmar;

  @override
  State<FormularioCalificacion> createState() => _FormularioCalificacionState();
}

class _FormularioCalificacionState extends State<FormularioCalificacion> {
  final _comentarioCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int _calificacion = 0;
  bool _cargando = false;
  String? _errorMensaje;
  double _insetInferiorAnterior = 0;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Cuando el teclado se cierra (el inset inferior pasa de >0 a 0), el
  /// `SingleChildScrollView` puede quedar con el scroll desplazado hacia
  /// arriba (bug conocido de Flutter: el ScrollPosition no se reajusta solo
  /// al crecer el viewport). Detectamos la transición y devolvemos el scroll
  /// a 0 en el siguiente frame.
  void _reajustarScrollSiSeCerroElTeclado(double insetInferiorActual) {
    final tecladoSeAcabaDeCerrar =
        _insetInferiorAnterior > 0 && insetInferiorActual == 0;
    _insetInferiorAnterior = insetInferiorActual;
    if (!tecladoSeAcabaDeCerrar) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _confirmar() async {
    if (_calificacion == 0) {
      setState(() => _errorMensaje = 'Elegí una calificación.');
      return;
    }
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final comentario = _comentarioCtrl.text.trim();
      await widget.alConfirmar(
        _calificacion,
        comentario.isEmpty ? null : comentario,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _errorMensaje = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insetInferior = MediaQuery.of(context).viewInsets.bottom;
    _reajustarScrollSiSeCerroElTeclado(insetInferior);
    return Padding(
      padding: EdgeInsets.only(
        bottom: insetInferior,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Cómo estuvo tu corte?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 36,
                    onPressed: () => setState(() => _calificacion = i),
                    icon: Icon(
                      i <= _calificacion ? Icons.star : Icons.star_border,
                      color: ColoresApp.primario,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _comentarioCtrl,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (_errorMensaje != null) ...[
              const SizedBox(height: 16),
              Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargando ? null : _confirmar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _cargando
                  ? const CircularProgressIndicator()
                  : const Text('Enviar calificación'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
