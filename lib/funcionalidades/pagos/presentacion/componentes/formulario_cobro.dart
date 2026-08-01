import 'package:flutter/material.dart';

import '../../dominio/enum_metodo_pago.dart';

/// Formulario chico para cobrar un turno en caja: monto (precargado con
/// [precioSugerido], editable) + método de pago.
class FormularioCobro extends StatefulWidget {
  const FormularioCobro({
    super.key,
    required this.precioSugerido,
    this.etiquetaMonto,
    required this.alConfirmar,
  });

  final double precioSugerido;
  final String? etiquetaMonto;
  final void Function(double monto, MetodoPago metodo) alConfirmar;

  @override
  State<FormularioCobro> createState() => _FormularioCobroState();
}

class _FormularioCobroState extends State<FormularioCobro> {
  late final TextEditingController _montoCtrl;
  MetodoPago _metodo = MetodoPago.efectivo;

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(
      text: widget.precioSugerido.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cobrar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.etiquetaMonto ?? 'Monto a cobrar (Bs.)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MetodoPago>(
            initialValue: _metodo,
            decoration: const InputDecoration(labelText: 'Método de pago'),
            items: MetodoPago.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.aTexto())))
                .toList(),
            onChanged: (v) => setState(() => _metodo = v ?? _metodo),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final monto = double.tryParse(_montoCtrl.text);
                if (monto == null || monto <= 0) return;
                widget.alConfirmar(monto, _metodo);
                Navigator.of(context).pop();
              },
              child: const Text('Confirmar cobro'),
            ),
          ),
        ],
      ),
    );
  }
}
