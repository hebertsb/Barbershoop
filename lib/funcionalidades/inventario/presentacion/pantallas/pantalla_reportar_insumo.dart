import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/selector_imagen.dart';
import '../../../../nucleo/configuracion/constantes.dart';
import '../../dominio/enum_tipo_reporte_insumo.dart';
import '../controladores/controlador_mis_insumos.dart';
import '../controladores/controlador_reportar_insumo.dart';

class PantallaReportarInsumo extends ConsumerStatefulWidget {
  const PantallaReportarInsumo({super.key});

  @override
  ConsumerState<PantallaReportarInsumo> createState() =>
      _PantallaReportarInsumoState();
}

class _PantallaReportarInsumoState
    extends ConsumerState<PantallaReportarInsumo> {
  final _formularioKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _descripcionCtrl = TextEditingController();
  String? _insumoIdSeleccionado;
  double _cantidadDisponible = 0;
  TipoReporteInsumo _tipo = TipoReporteInsumo.danado;
  String? _urlFoto;
  bool _cargando = false;
  String? _errorMensaje;
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
  /// alguno toma foco (teclado abrindose) bloquea los dos dropdowns YA,
  /// antes de que el usuario llegue a tocarlos. As el hit-test de un toque
  /// posterior sobre cualquiera de ellos ve `absorbing == true` y su men
  /// nunca se abre con el layout todava en posicin "con teclado abierto".
  /// Al perder el foco del todo, espera a que termine la animacin de cierre
  /// del teclado (~300ms) antes de reactivarlos. Ambos dropdowns comparten
  /// el mismo `_bloqueandoDropdown`/`_focusScopeNode`.
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
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formularioKey.currentState!.validate()) return;
    if (_insumoIdSeleccionado == null) {
      setState(() => _errorMensaje = 'Eleg un insumo.');
      return;
    }
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      await ref
          .read(controladorReportarInsumoProvider.notifier)
          .reportar(
            insumoId: _insumoIdSeleccionado!,
            tipo: _tipo,
            cantidad: int.parse(_cantidadCtrl.text.trim()),
            descripcion: _descripcionCtrl.text.trim().isEmpty
                ? null
                : _descripcionCtrl.text.trim(),
            urlFoto: _urlFoto,
          );
      ref.invalidate(controladorMisInsumosProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _errorMensaje = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final misInsumos = ref.watch(controladorMisInsumosProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar insumo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formularioKey,
          child: ListView(
            children: [
              Listener(
                onPointerDown: (_) {
                  if (_focusScopeNode?.hasFocus ?? false) {
                    FocusScope.of(context).unfocus();
                  }
                },
                child: AbsorbPointer(
                  absorbing: _bloqueandoDropdown,
                  child: DropdownButtonFormField<String>(
                    initialValue: _insumoIdSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Insumo *',
                      border: OutlineInputBorder(),
                    ),
                    items: misInsumos
                        .map(
                          (i) => DropdownMenuItem(
                            value: i.insumoId,
                            child: Text(
                              '${i.nombreInsumo} (tens ${i.cantidadAsignada})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() {
                      _insumoIdSeleccionado = val;
                      _cantidadDisponible = misInsumos
                          .firstWhere((i) => i.insumoId == val)
                          .cantidadAsignada;
                    }),
                  ),
                ),
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
                  child: DropdownButtonFormField<TipoReporteInsumo>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo *',
                      border: OutlineInputBorder(),
                    ),
                    items: TipoReporteInsumo.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.etiqueta),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _tipo = val ?? _tipo),
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
                  if (parsed == null || parsed <= 0) return 'Debe ser > 0';
                  if (_insumoIdSeleccionado != null &&
                      parsed > _cantidadDisponible) {
                    return 'No tens esa cantidad asignada';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripcin',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SelectorImagen(
                bucket: Constantes.bucketImagenesApp,
                carpeta: 'reportes-insumo',
                urlActual: _urlFoto,
                alSubir: (url) => setState(() => _urlFoto = url),
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 16),
                Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Enviar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
