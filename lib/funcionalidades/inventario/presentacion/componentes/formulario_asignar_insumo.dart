import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Reacciona de forma proactiva al foco de los campos de texto: apenas
  /// alguno toma foco (teclado abriéndose) bloquea el dropdown YA, antes de
  /// que el usuario llegue a tocarlo. Así el hit-test de un toque posterior
  /// sobre el dropdown ve `absorbing == true` y su menú nunca se abre con el
  /// layout todavía en posición "con teclado abierto". Al perder el foco del
  /// todo, espera a que termine la animación de cierre del teclado (~300ms)
  /// antes de reactivarlo.
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

  Future<void> _asignar() async {
    if (!_formularioKey.currentState!.validate()) return;
    if (_barberoId == null) {
      setState(() => _errorMensaje = 'Elegí un barbero.');
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
    final barberos = (ref.watch(controladorBarberosProvider).value ?? [])
        .where((b) => b.activo)
        .toList();
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
                'Asignar "${widget.insumo.nombre}"',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Stock disponible: ${widget.insumo.stock}',
                style: Theme.of(context).textTheme.bodySmall,
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
                    decoration: const InputDecoration(
                      labelText: 'Barbero *',
                      border: OutlineInputBorder(),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cantidad *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final parsed = int.tryParse(v ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Debe ser > 0';
                  }
                  if (parsed > widget.insumo.stock) {
                    return 'No hay suficiente stock';
                  }
                  return null;
                },
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 16),
                Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _asignar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Asignar'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
