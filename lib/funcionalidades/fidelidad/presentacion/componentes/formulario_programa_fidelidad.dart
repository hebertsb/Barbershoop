import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
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
  late final TextEditingController _metaCtrl;
  final _scrollCtrl = ScrollController();
  double _insetInferiorAnterior = 0;
  List<String> _serviciosSeleccionados = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _activo = true;
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.programa?.titulo ?? '');
    _metaCtrl = TextEditingController(
      text: widget.programa?.metaCitas.toString() ?? '10',
    );
    _serviciosSeleccionados = List<String>.from(
      widget.programa?.serviciosIds ?? const [],
    );
    _fechaInicio = widget.programa?.fechaInicio;
    _fechaFin = widget.programa?.fechaFin;
    _activo = widget.programa?.activo ?? true;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _metaCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Cuando el teclado se cierra, el `SingleChildScrollView` puede quedar
  /// con el scroll desplazado hacia arriba (bug conocido de Flutter, mismo
  /// fix ya aplicado en el resto de formularios de esta app).
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

  Future<void> _seleccionarFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _fechaInicio = picked);
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _fechaFin ??
          _fechaInicio ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _fechaFin = picked);
    }
  }

  Future<void> _guardar() async {
    if (!_formularioKey.currentState!.validate()) return;
    if (_serviciosSeleccionados.isEmpty) {
      setState(
        () => _errorMensaje = 'Elegí al menos un servicio para el programa.',
      );
      return;
    }
    if (_fechaInicio != null &&
        _fechaFin != null &&
        _fechaFin!.isBefore(_fechaInicio!)) {
      setState(
        () => _errorMensaje =
            'La fecha fin no puede ser anterior a la fecha inicio.',
      );
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final programa = ModeloProgramaFidelidad(
        id: widget.programa?.id ?? '',
        barberiaId: widget.programa?.barberiaId ?? '',
        titulo: _tituloCtrl.text.trim(),
        serviciosIds: _serviciosSeleccionados,
        metaCitas: int.parse(_metaCtrl.text.trim()),
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        activo: _activo,
      );
      await widget.alGuardar(programa);
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
      child: Form(
        key: _formularioKey,
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.programa == null
                    ? 'Nuevo Programa de Fidelidad'
                    : 'Editar Programa de Fidelidad',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  helperText: 'Ej. "10 cortes, el 11vo gratis"',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El título es requerido'
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Servicios que cuentan para el contador *',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.servicios.map((s) {
                  final seleccionado = _serviciosSeleccionados.contains(s.id);
                  return FilterChip(
                    label: Text(s.nombre),
                    selected: seleccionado,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _serviciosSeleccionados.add(s.id);
                        } else {
                          _serviciosSeleccionados.remove(s.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _metaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Meta de citas *',
                  helperText: 'Cuántas citas hacen falta para ganar el premio',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = int.tryParse(v?.trim() ?? '');
                  if (val == null || val <= 0) {
                    return 'Debe ser un número entero mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Vigencia del premio (opcional)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Rango de fechas en que el premio reclamado es válido. '
                'Vacío = sin restricción de fecha.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarFechaInicio,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _fechaInicio == null
                            ? 'Fecha inicio'
                            : formatoFechaCorta(_fechaInicio!),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarFechaFin,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _fechaFin == null
                            ? 'Fecha fin'
                            : formatoFechaCorta(_fechaFin!),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Programa Activo'),
                value: _activo,
                onChanged: (val) => setState(() => _activo = val),
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 16),
                Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.primario,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Guardar'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}