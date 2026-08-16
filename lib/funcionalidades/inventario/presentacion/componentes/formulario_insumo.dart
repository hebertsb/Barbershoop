import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_insumo.dart';

const List<String> _unidadesComunes = [
  'unidad',
  'ml',
  'litros',
  'gramos',
  'kg',
  'frasco',
  'caja',
  'tubo',
  'paquete',
];

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
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _categoriaCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _stockMinimoCtrl;
  late final TextEditingController _costoCtrl;
  late String _unidadMedida;
  final _scrollCtrl = ScrollController();
  bool _cargando = false;
  String? _errorMensaje;
  double _insetInferiorAnterior = 0;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.insumo?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: widget.insumo?.descripcion ?? '');
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
    _unidadMedida = widget.insumo?.unidadMedida ?? 'unidad';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _categoriaCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _costoCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

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
        descripcion: _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        categoria: _categoriaCtrl.text.trim().isEmpty
            ? null
            : _categoriaCtrl.text.trim(),
        stock: double.parse(_stockCtrl.text.trim()),
        stockMinimo: double.parse(_stockMinimoCtrl.text.trim()),
        unidadMedida: _unidadMedida,
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
    final colorScheme = Theme.of(context).colorScheme;
    final insetInferior = MediaQuery.of(context).viewInsets.bottom;
    _reajustarScrollSiSeCerroElTeclado(insetInferior);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: insetInferior + 16,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Form(
        key: _formularioKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.insumo == null ? 'Nuevo Insumo' : 'Editar Insumo',
              style: TipografiaApp.headlineSm.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Insumo *',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'El nombre es requerido'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _categoriaCtrl,
                            decoration: InputDecoration(
                              labelText: 'Categoría',
                              prefixIcon: const Icon(Icons.category_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _unidadesComunes.contains(_unidadMedida)
                                ? _unidadMedida
                                : 'unidad',
                            decoration: InputDecoration(
                              labelText: 'Unidad de Medida',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _unidadesComunes
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _unidadMedida = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockCtrl,
                            decoration: InputDecoration(
                              labelText: 'Stock Actual *',
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final parsed = double.tryParse(v ?? '');
                              if (parsed == null || parsed < 0) {
                                return 'Debe ser >= 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockMinimoCtrl,
                            decoration: InputDecoration(
                              labelText: 'Stock Mínimo *',
                              prefixIcon: const Icon(Icons.warning_amber_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final parsed = double.tryParse(v ?? '');
                              if (parsed == null || parsed < 0) {
                                return 'Debe ser >= 0';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _costoCtrl,
                      decoration: InputDecoration(
                        labelText: 'Costo Unitario (Bs.)',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _descripcionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Descripción / Notas',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                    ),

                    if (_errorMensaje != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _errorMensaje!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _cargando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresApp.primario,
                foregroundColor: colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _cargando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'GUARDAR INSUMO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
