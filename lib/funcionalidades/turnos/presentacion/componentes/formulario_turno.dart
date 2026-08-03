import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administracion/dominio/modelo_servicio.dart';
import '../../../pagos/dominio/enum_metodo_pago.dart';
import '../../../pagos/presentacion/componentes/formulario_cobro.dart';
import '../../dominio/enum_modo_cobro_caja.dart';
import '../controladores/controlador_turnos.dart';
import 'aviso_disponibilidad_servicio.dart';

class FormularioTurno extends ConsumerStatefulWidget {
  const FormularioTurno({
    super.key,
    required this.sucursalId,
    required this.servicios,
  });

  final String sucursalId;
  final List<ModeloServicio> servicios;

  @override
  ConsumerState<FormularioTurno> createState() => _FormularioTurnoState();
}

class _FormularioTurnoState extends ConsumerState<FormularioTurno> {
  final _formularioKey = GlobalKey<FormState>();
  final _telefonoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _clienteConCuenta = false;
  String? _clienteIdEncontrado;
  String? _servicioSeleccionadoId;
  bool _buscando = false;
  bool _cargando = false;
  String? _errorMensaje;
  double _insetInferiorAnterior = 0;
  bool _bloqueandoDropdown = false;
  FocusScopeNode? _focusScopeNode;

  @override
  void initState() {
    super.initState();
    if (widget.servicios.isNotEmpty) {
      _servicioSeleccionadoId = widget.servicios.first.id;
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
    _telefonoCtrl.dispose();
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
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

  Future<void> _buscarCliente() async {
    setState(() {
      _buscando = true;
      _errorMensaje = null;
    });
    try {
      final controlador = ref.read(
        controladorTurnosProvider(widget.sucursalId).notifier,
      );
      if (_clienteConCuenta) {
        final resultado = await controlador.buscarClientePorEmail(
          _emailCtrl.text.trim().toLowerCase(),
        );
        setState(() {
          _clienteIdEncontrado = resultado?['id'];
          _nombreCtrl.text = resultado?['nombre'] ?? '';
        });
        if (resultado == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró un cliente con ese correo.'),
            ),
          );
        }
      } else {
        final resultado = await controlador.buscarClienteWalkinPorTelefono(
          _telefonoCtrl.text.trim(),
        );
        setState(() {
          if (resultado != null) _nombreCtrl.text = resultado.nombre;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMensaje = e.toString());
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  ModeloServicio get _servicioSeleccionado =>
      widget.servicios.firstWhere((s) => s.id == _servicioSeleccionadoId);

  Future<void> _guardarConCobro(double monto, MetodoPago metodo) {
    return _crearTurno(montoPrecobrado: monto, metodoPrecobrado: metodo);
  }

  Future<void> _crearTurno({
    double? montoPrecobrado,
    MetodoPago? metodoPrecobrado,
  }) async {
    final controlador = ref.read(
      controladorTurnosProvider(widget.sucursalId).notifier,
    );
    if (_clienteConCuenta) {
      if (_clienteIdEncontrado == null) {
        throw Exception('Busca un cliente con cuenta antes de guardar.');
      }
      await controlador.crearTurnoConCuenta(
        servicioId: _servicioSeleccionadoId!,
        clienteId: _clienteIdEncontrado!,
        montoPrecobrado: montoPrecobrado,
        metodoPrecobrado: metodoPrecobrado,
      );
    } else {
      await controlador.crearTurnoWalkin(
        servicioId: _servicioSeleccionadoId!,
        nombre: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        montoPrecobrado: montoPrecobrado,
        metodoPrecobrado: metodoPrecobrado,
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formularioKey.currentState!.validate()) return;
    if (_servicioSeleccionadoId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un servicio.')));
      return;
    }
    if (_clienteConCuenta && _clienteIdEncontrado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Busca un cliente con cuenta antes de guardar.'),
        ),
      );
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final modoCobro = await ref.read(modoCobroCajaProvider.future);
      if (modoCobro == ModoCobroCaja.alLlegar) {
        final servicio = _servicioSeleccionado;
        if (mounted) Navigator.pop(context);
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => FormularioCobro(
              precioSugerido: servicio.precio,
              alConfirmar: _guardarConCobro,
            ),
          );
        }
        return;
      }

      await _crearTurno();
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
              const Text(
                'Registrar turno',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cliente con cuenta'),
                value: _clienteConCuenta,
                onChanged: (val) {
                  setState(() {
                    _clienteConCuenta = val;
                    _clienteIdEncontrado = null;
                    _nombreCtrl.clear();
                  });
                },
              ),
              if (_clienteConCuenta)
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo del cliente *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El correo es requerido'
                      : null,
                  onChanged: (_) {
                    if (_clienteIdEncontrado != null) {
                      setState(() {
                        _clienteIdEncontrado = null;
                        _nombreCtrl.clear();
                      });
                    }
                  },
                )
              else
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El teléfono es requerido'
                      : null,
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _buscando ? null : _buscarCliente,
                  icon: const Icon(Icons.search),
                  label: Text(_buscando ? 'Buscando...' : 'Buscar'),
                ),
              ),
              TextFormField(
                controller: _nombreCtrl,
                enabled: !_clienteConCuenta,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es requerido'
                    : null,
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
                    initialValue: _servicioSeleccionadoId,
                    decoration: const InputDecoration(
                      labelText: 'Servicio *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.content_cut),
                    ),
                    items: widget.servicios.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nombre),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _servicioSeleccionadoId = val),
                    validator: (v) =>
                        v == null ? 'Selecciona un servicio' : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AvisoDisponibilidadServicio(
                sucursalId: widget.sucursalId,
                servicios: widget.servicios,
                servicioSeleccionadoId: _servicioSeleccionadoId,
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
                    : const Text('Registrar turno'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}