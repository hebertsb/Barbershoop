import 'package:flutter/material.dart';

import '../../dominio/modelo_sucursal.dart';

class FormularioSucursal extends StatefulWidget {
  const FormularioSucursal({super.key, this.sucursal, required this.alGuardar});

  final ModeloSucursal? sucursal;
  final Future<void> Function(ModeloSucursal) alGuardar;

  @override
  State<FormularioSucursal> createState() => _FormularioSucursalState();
}

class _FormularioSucursalState extends State<FormularioSucursal> {
  final _formularioKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _aperturaCtrl;
  late final TextEditingController _cierreCtrl;
  late bool _activo;
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.sucursal?.nombre ?? '');
    _direccionCtrl = TextEditingController(
      text: widget.sucursal?.direccion ?? '',
    );
    _telefonoCtrl = TextEditingController(text: widget.sucursal?.telefono ?? '');
    _aperturaCtrl = TextEditingController(
      text: widget.sucursal?.horarioApertura ?? '09:00',
    );
    _cierreCtrl = TextEditingController(
      text: widget.sucursal?.horarioCierre ?? '20:00',
    );
    _activo = widget.sucursal?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _aperturaCtrl.dispose();
    _cierreCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarHora(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final horaInicial = TimeOfDay.now();
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );
    if (horaSeleccionada != null && mounted) {
      final horaStr =
          '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}';
      controller.text = horaStr;
    }
  }

  Future<void> _guardar() async {
    if (!_formularioKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final sucursal = ModeloSucursal(
        id: widget.sucursal?.id ?? '', // Upsert resolverá el ID vacío en Supabase
        barberiaId: widget.sucursal?.barberiaId ?? '',
        nombre: _nombreCtrl.text.trim(),
        direccion:
            _direccionCtrl.text.trim().isEmpty
                ? null
                : _direccionCtrl.text.trim(),
        telefono:
            _telefonoCtrl.text.trim().isEmpty
                ? null
                : _telefonoCtrl.text.trim(),
        horarioApertura: '${_aperturaCtrl.text.trim()}:00',
        horarioCierre: '${_cierreCtrl.text.trim()}:00',
        activo: _activo,
      );

      await widget.alGuardar(sucursal);
      if (mounted) Navigator.pop(context);
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
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formularioKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.sucursal == null ? 'Nueva Sucursal' : 'Editar Sucursal',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'El nombre es requerido'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _aperturaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Horario Apertura *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () => _seleccionarHora(context, _aperturaCtrl),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cierreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Horario Cierre *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () => _seleccionarHora(context, _cierreCtrl),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Sucursal Activa'),
                value: _activo,
                onChanged: (val) => setState(() => _activo = val),
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMensaje!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _cargando
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
