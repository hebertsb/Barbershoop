import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelo_barbero.dart';
import '../../dominio/modelo_sucursal.dart';
import '../controladores/controlador_barberos.dart';

/// Formulario para editar la sucursal y las especialidades de un barbero ya
/// existente, sin necesidad de reinvitarlo. Mismo look que `FormularioBarbero`
/// (usado para invitar) para mantener consistencia visual.
class FormularioEditarBarbero extends ConsumerStatefulWidget {
  const FormularioEditarBarbero({
    super.key,
    required this.barbero,
    required this.sucursales,
  });

  final ModeloBarbero barbero;
  final List<ModeloSucursal> sucursales;

  @override
  ConsumerState<FormularioEditarBarbero> createState() =>
      _FormularioEditarBarberoState();
}

class _FormularioEditarBarberoState
    extends ConsumerState<FormularioEditarBarbero> {
  final _especialidadCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late String _sucursalSeleccionadaId;
  late List<String> _especialidades;
  bool _cargando = false;
  String? _errorMensaje;
  double _insetInferiorAnterior = 0;
  bool _bloqueandoDropdown = false;
  FocusScopeNode? _focusScopeNode;

  @override
  void initState() {
    super.initState();
    _sucursalSeleccionadaId = widget.barbero.sucursalId;
    _especialidades = List<String>.from(widget.barbero.especialidades);
  }

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
    _especialidadCtrl.dispose();
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
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      await ref
          .read(controladorBarberosProvider.notifier)
          .guardarSucursalYEspecialidades(
            barberoId: widget.barbero.id,
            sucursalId: _sucursalSeleccionadaId,
            especialidades: _especialidades,
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
    final insetInferior = MediaQuery.of(context).viewInsets.bottom;
    _reajustarScrollSiSeCerroElTeclado(insetInferior);

    return Padding(
      padding: EdgeInsets.only(
        bottom: insetInferior,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Editar ${widget.barbero.nombrePerfil ?? "Barbero"}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  initialValue: _sucursalSeleccionadaId,
                  decoration: const InputDecoration(
                    labelText: 'Sucursal de Asignación *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.storefront),
                  ),
                  items: sucursalesActivas.map((s) {
                    return DropdownMenuItem(value: s.id, child: Text(s.nombre));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _sucursalSeleccionadaId = val);
                    }
                  },
                ),
              ),
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
              children: _especialidades.map((esp) {
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
                  : const Text('Guardar cambios'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
