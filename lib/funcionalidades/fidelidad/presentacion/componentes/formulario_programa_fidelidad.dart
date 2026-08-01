import 'package:flutter/material.dart';

import '../../../administracion/dominio/modelo_servicio.dart';
import '../../dominio/modelo_programa_fidelidad.dart';

class FormularioProgramaFidelidad extends StatefulWidget {
  const FormularioProgramaFidelidad({
    super.key,
    this.programa,
    required this.servicios,
    required this.alGuardar,
  });

  final ModeloProgramaFidelidad? programa;
  final List<ModeloServicio> servicios;
  final Future<void> Function(ModeloProgramaFidelidad) alGuardar;

  @override
  State<FormularioProgramaFidelidad> createState() =>
      _FormularioProgramaFidelidadState();
}

class _FormularioProgramaFidelidadState
    extends State<FormularioProgramaFidelidad> {
  final _formularioKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _metaCitasCtrl;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.programa?.titulo ?? '');
    _metaCitasCtrl = TextEditingController(
      text: widget.programa?.metaCitas.toString() ?? '5',
    );
    _fechaInicio = widget.programa?.fechaInicio;
    _fechaFin = widget.programa?.fechaFin;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _metaCitasCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: (esInicio ? _fechaInicio : _fechaFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = fecha;
      } else {
        _fechaFin = fecha;
      }
    });
  }

  Future<void> _guardar() async {
    if (!(_formularioKey.currentState?.validate() ?? false)) return;
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final programa = ModeloProgramaFidelidad(
        id: widget.programa?.id ?? '',
        barberiaId: widget.programa?.barberiaId ?? '',
        titulo: _tituloCtrl.text.trim(),
        metaCitas: int.parse(_metaCitasCtrl.text),
        activo: widget.programa?.activo ?? true,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
      await widget.alGuardar(programa);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errorMensaje = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formularioKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.programa == null
                  ? 'Nuevo programa de fidelidad'
                  : 'Editar programa de fidelidad',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _metaCitasCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Meta de citas',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n <= 0) ? 'Ingresa un número válido' : null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _elegirFecha(esInicio: true),
                    child: Text(
                      _fechaInicio == null
                          ? 'Fecha inicio (opcional)'
                          : 'Inicio: ${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _elegirFecha(esInicio: false),
                    child: Text(
                      _fechaFin == null
                          ? 'Fecha fin (opcional)'
                          : 'Fin: ${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}',
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMensaje != null) ...[
              const SizedBox(height: 16),
              Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                child: _cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
