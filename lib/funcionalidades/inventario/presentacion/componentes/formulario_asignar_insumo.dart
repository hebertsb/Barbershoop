import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../administracion/presentacion/controladores/controlador_barberos.dart';
import '../../dominio/modelo_insumo.dart';

class FormularioAsignarInsumo extends ConsumerStatefulWidget {
  const FormularioAsignarInsumo({
    super.key,
    required this.insumo,
    required this.alAsignar,
  });

  final ModeloInsumo insumo;
  final Future<void> Function({
    required String barberoId,
    required int cantidad,
  })
  alAsignar;

  @override
  ConsumerState<FormularioAsignarInsumo> createState() =>
      _FormularioAsignarInsumoState();
}

class _FormularioAsignarInsumoState
    extends ConsumerState<FormularioAsignarInsumo> {
  final _formularioKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _scrollCtrl = ScrollController();
  String? _barberoId;
  bool _cargando = false;
  String? _errorMensaje;
  double _insetInferiorAnterior = 0;
  bool _bloqueandoDropdown = false;
  FocusScopeNode? _focusScopeNode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nuevoScope = FocusScope.of(context);
    if (!identical(_focusScopeNode, nuevoScope)) {
      _focusScopeNode?.removeListener(_alCambiarFoco);
      _focusScopeNode = nuevoScope;
      _focusScopeNode!.addListener(_alCambiarFoco);
    }
  }

  void _alCambiarFoco() {
    final tieneFoco = _focusScopeNode?.hasFocus ?? false;
    if (tieneFoco && !_bloqueandoDropdown) {
      setState(() => _bloqueandoDropdown = true);
    } else if (!tieneFoco && _bloqueandoDropdown) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _bloqueandoDropdown = false);
      });
    }
  }

  @override
  void dispose() {
    _focusScopeNode?.removeListener(_alCambiarFoco);
    _cantidadCtrl.dispose();
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

  Future<void> _asignar() async {
    if (!_formularioKey.currentState!.validate()) return;
    if (_barberoId == null) {
      setState(() => _errorMensaje = 'Elige un barbero.');
      return;
    }
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      await widget.alAsignar(
        barberoId: _barberoId!,
        cantidad: int.parse(_cantidadCtrl.text.trim()),
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
    final colorScheme = Theme.of(context).colorScheme;
    final barberos = (ref.watch(controladorBarberosProvider).value ?? [])
        .where((b) => b.activo)
        .toList();
    final insetInferior = MediaQuery.of(context).viewInsets.bottom;
    _reajustarScrollSiSeCerroElTeclado(insetInferior);

    return Container(
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
        child: SingleChildScrollView(
          controller: _scrollCtrl,
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
                'Asignar "${widget.insumo.nombre}"',
                style: TipografiaApp.headlineSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Stock en almacén: ${widget.insumo.stockFormateado}',
                    style: TipografiaApp.bodySm.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Listener(
                onPointerDown: (_) {
                  if (_focusScopeNode?.hasFocus ?? false) {
                    FocusScope.of(context).unfocus();
                  }
                },
                child: AbsorbPointer(
                  absorbing: _bloqueandoDropdown,
                  child: DropdownButtonFormField<String>(
                    initialValue: _barberoId,
                    decoration: InputDecoration(
                      labelText: 'Seleccionar Barbero *',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: barberos
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.nombrePerfil ?? 'Sin nombre'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _barberoId = val),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cantidadCtrl,
                decoration: InputDecoration(
                  labelText: 'Cantidad a Asignar *',
                  prefixIcon: const Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final parsed = int.tryParse(v ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Debe ser > 0';
                  }
                  if (parsed > widget.insumo.stock) {
                    return 'No hay suficiente stock en almacén';
                  }
                  return null;
                },
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMensaje!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cargando ? null : _asignar,
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
                        'ASIGNAR INSUMO A BARBERO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
