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
  final _scrollCtrl = ScrollController();
  String? _sucursalSeleccionadaId;
  final List<String> _especialidades = [];
  bool _cargando = false;
  String? _errorMensaje;
  double _insetInferiorAnterior = 0;
  bool _bloqueandoDropdown = false;
  FocusScopeNode? _focusScopeNode;

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
    _emailCtrl.dispose();
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
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v.trim())) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
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
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nombre),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _sucursalSeleccionadaId = val);
                    },
                    validator: (v) =>
                        v == null ? 'Selecciona una sucursal' : null,
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