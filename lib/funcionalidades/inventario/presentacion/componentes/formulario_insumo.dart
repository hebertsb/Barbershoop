import 'package:flutter/material.dart';

import '../../dominio/modelo_insumo.dart';

class FormularioInsumo extends StatefulWidget {
  const FormularioInsumo({
    super.key,
    this.insumo,
    required this.barberiaId,
    required this.sucursalId,
    required this.alGuardar,
  });

  final ModeloInsumo? insumo;
  final String barberiaId;
  final String sucursalId;
  final Future<void> Function(ModeloInsumo) alGuardar;

  @override
  State<FormularioInsumo> createState() => _FormularioInsumoState();
}

class _FormularioInsumoState extends State<FormularioInsumo> {
  final _formularioKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _categoriaCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _stockMinimoCtrl;
  late final TextEditingController _costoCtrl;
  final _scrollCtrl = ScrollController();
  bool _cargando = false;
  String? _errorMensaje;
  double _insetInferiorAnterior = 0;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.insumo?.nombre ?? '');
    _categoriaCtrl = TextEditingController(
      text: widget.insumo?.categoria ?? '',
    );
    _stockCtrl = TextEditingController(
      text: widget.insumo?.stock.toString() ?? '0',
    );
    _stockMinimoCtrl = TextEditingController(
      text: widget.insumo?.stockMinimo.toString() ?? '5',
    );
    _costoCtrl = TextEditingController(
      text: widget.insumo?.costoUnitario?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _categoriaCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _costoCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Cuando el teclado se cierra (el inset inferior pasa de >0 a 0), el
  /// `SingleChildScrollView` puede quedar con el scroll desplazado hacia
  /// arriba (bug conocido de Flutter: el ScrollPosition no se reajusta solo
  /// al crecer el viewport). Detectamos la transicin y devolvemos el scroll
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

  Future<void> _guardar() async {
    if (!_formularioKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final insumo = ModeloInsumo(
        id: widget.insumo?.id ?? '',
        barberiaId: widget.barberiaId,
        sucursalId: widget.sucursalId,
        nombre: _nombreCtrl.text.trim(),
        categoria: _categoriaCtrl.text.trim().isEmpty
            ? null
            : _categoriaCtrl.text.trim(),
        stock: int.parse(_stockCtrl.text.trim()),
        stockMinimo: int.parse(_stockMinimoCtrl.text.trim()),
        costoUnitario: _costoCtrl.text.trim().isEmpty
            ? null
            : double.parse(_costoCtrl.text.trim()),
      );
      await widget.alGuardar(insumo);
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
                widget.insumo == null ? 'Nuevo Insumo' : 'Editar Insumo',
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
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El nombre es requerido'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoriaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Categora',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stock *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final parsed = int.tryParse(v ?? '');
                        if (parsed == null || parsed < 0) {
                          return 'Debe ser >= 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockMinimoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stock mnimo *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final parsed = int.tryParse(v ?? '');
                        if (parsed == null || parsed < 0) {
                          return 'Debe ser >= 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Costo unitario (Bs.)',
                  border: OutlineInputBorder(),
                  prefixText: 'Bs. ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed < 0) return 'Debe ser >= 0';
                  return null;
                },
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
