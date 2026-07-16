import 'package:flutter/material.dart';

import '../../dominio/modelo_sucursal.dart';

class FormularioBarbero extends StatefulWidget {
  const FormularioBarbero({
    super.key,
    required this.sucursales,
    required this.alGuardar,
  });

  final List<ModeloSucursal> sucursales;
  final Future<void> Function(
    String email,
    String sucursalId,
    List<String> especialidades,
  )
  alGuardar;

  @override
  State<FormularioBarbero> createState() => _FormularioBarberoState();
}

class _FormularioBarberoState extends State<FormularioBarbero> {
  final _formularioKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _especialidadCtrl = TextEditingController();
  String? _sucursalSeleccionadaId;
  final List<String> _especialidades = [];
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    // Pre-seleccionar la primera sucursal activa si existe
    final activas = widget.sucursales.where((s) => s.activo).toList();
    if (activas.isNotEmpty) {
      _sucursalSeleccionadaId = activas.first.id;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _especialidadCtrl.dispose();
    super.dispose();
  }

  void _agregarEspecialidad() {
    final texto = _especialidadCtrl.text.trim().toLowerCase();
    if (texto.isNotEmpty && !_especialidades.contains(texto)) {
      setState(() {
        _especialidades.add(texto);
        _especialidadCtrl.clear();
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formularioKey.currentState!.validate()) return;
    if (_sucursalSeleccionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una sucursal.')),
      );
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      await widget.alGuardar(
        _emailCtrl.text.trim().toLowerCase(),
        _sucursalSeleccionadaId!,
        _especialidades,
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
    final sucursalesActivas = widget.sucursales.where((s) => s.activo).toList();

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
              const Text(
                'Invitar/Registrar Barbero',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa el correo del usuario (debe estar ya registrado con Google o Facebook en la app).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El correo es requerido';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(
                    v.trim(),
                  )) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sucursalSeleccionadaId,
                decoration: const InputDecoration(
                  labelText: 'Sucursal de Asignación *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storefront),
                ),
                items:
                    sucursalesActivas.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.nombre));
                    }).toList(),
                onChanged: (val) {
                  setState(() => _sucursalSeleccionadaId = val);
                },
                validator:
                    (v) => v == null ? 'Selecciona una sucursal' : null,
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
                children:
                    _especialidades.map((esp) {
                      return InputChip(
                        label: Text(esp),
                        onDeleted: () {
                          setState(() {
                            _especialidades.remove(esp);
                          });
                        },
                      );
                    }).toList(),
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
                        : const Text('Invitar Barbero'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
