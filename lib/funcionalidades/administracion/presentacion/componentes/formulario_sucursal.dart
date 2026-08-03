import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/selector_imagen.dart';
import '../../../../nucleo/configuracion/constantes.dart';
import '../../dominio/modelo_sucursal.dart';
import 'selector_ubicacion_mapa.dart';

class FormularioSucursal extends StatefulWidget {
  const FormularioSucursal({super.key, this.sucursal, required this.alGuardar});

  final ModeloSucursal? sucursal;
  final Future<void> Function(ModeloSucursal) alGuardar;

  @override
  State<FormularioSucursal> createState() => _FormularioSucursalState();
}

class _FormularioSucursalState extends State<FormularioSucursal> {
  final _formularioKey = GlobalKey<FormState>();
  final _mapaKey = GlobalKey<SelectorUbicacionMapaState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _aperturaCtrl;
  late final TextEditingController _cierreCtrl;
  late final TextEditingController _managerCtrl;
  final _scrollCtrl = ScrollController();
  late bool _activo;
  bool _cargando = false;
  String? _errorMensaje;
  String? _urlImagen;
  double _insetInferiorAnterior = 0;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.sucursal?.nombre ?? '');
    _direccionCtrl = TextEditingController(
      text: widget.sucursal?.direccion ?? '',
    );
    _telefonoCtrl = TextEditingController(
      text: widget.sucursal?.telefono ?? '',
    );
    _aperturaCtrl = TextEditingController(
      text: widget.sucursal?.horarioApertura ?? '09:00',
    );
    _cierreCtrl = TextEditingController(
      text: widget.sucursal?.horarioCierre ?? '20:00',
    );
    _managerCtrl = TextEditingController(
      text: widget.sucursal?.managerNombre ?? '',
    );
    _activo = widget.sucursal?.activo ?? true;
    _urlImagen = widget.sucursal?.urlImagen;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _aperturaCtrl.dispose();
    _cierreCtrl.dispose();
    _managerCtrl.dispose();
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

  Future<void> _seleccionarHora(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final horaInicial = TimeOfDay.now();
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );
    if (horaSeleccionada != null && mounted) {
      final horaStr =
          '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}';
      controller.text = horaStr;
    }
  }

  Future<void> _guardar() async {
    if (!_formularioKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final centroMapa = _mapaKey.currentState?.obtenerCentro();
      String formatearHora(String val) {
        final v = val.trim();
        if (v.isEmpty) return '09:00:00';
        final partes = v.split(':');
        if (partes.length == 2) return '$v:00';
        return v;
      }

      final sucursal = ModeloSucursal(
        id: widget.sucursal?.id ?? '',
        barberiaId: widget.sucursal?.barberiaId ?? '',
        nombre: _nombreCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty
            ? null
            : _direccionCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        horarioApertura: formatearHora(_aperturaCtrl.text),
        horarioCierre: formatearHora(_cierreCtrl.text),
        activo: _activo,
        urlImagen: _urlImagen,
        managerNombre: _managerCtrl.text.trim().isEmpty
            ? null
            : _managerCtrl.text.trim(),
        latitud: centroMapa?.latitude,
        longitud: centroMapa?.longitude,
      );

      await widget.alGuardar(sucursal);
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
                widget.sucursal == null ? 'Nueva Sucursal' : 'Editar Sucursal',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SelectorImagen(
                bucket: Constantes.bucketImagenesApp,
                carpeta: 'sucursales',
                urlActual: _urlImagen,
                alSubir: (url) => setState(() => _urlImagen = url),
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
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _managerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Manager (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _aperturaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Horario Apertura *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () => _seleccionarHora(context, _aperturaCtrl),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cierreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Horario Cierre *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () => _seleccionarHora(context, _cierreCtrl),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Sucursal Activa'),
                value: _activo,
                onChanged: (val) => setState(() => _activo = val),
              ),
              const SizedBox(height: 16),
              Text(
                'Ubicación en el mapa',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SelectorUbicacionMapa(
                key: _mapaKey,
                latitudInicial: widget.sucursal?.latitud,
                longitudInicial: widget.sucursal?.longitud,
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