import 'package:flutter/material.dart';

import '../../dominio/modelo_sucursal.dart';

class FormularioSecretaria extends StatefulWidget {
  const FormularioSecretaria({
    super.key,
    required this.sucursales,
    required this.alGuardar,
  });

  final List<ModeloSucursal> sucursales;
  final Future<void> Function(String email, String sucursalId) alGuardar;

  @override
  State<FormularioSecretaria> createState() => _FormularioSecretariaState();
}

class _FormularioSecretariaState extends State<FormularioSecretaria> {
  final _formularioKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  String? _sucursalId;
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    if (widget.sucursales.isNotEmpty) {
      _sucursalId = widget.sucursales.first.id;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formularioKey.currentState?.validate() ?? false)) return;
    if (_sucursalId == null) return;

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      await widget.alGuardar(_emailCtrl.text.trim(), _sucursalId!);
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
            const Text(
              'Invitar secretaria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Ingresa un email válido'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _sucursalId,
              decoration: const InputDecoration(
                labelText: 'Sucursal',
                border: OutlineInputBorder(),
              ),
              items: widget.sucursales
                  .map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.nombre)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _sucursalId = v),
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
                    : const Text('Invitar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
