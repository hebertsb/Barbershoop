import 'package:flutter/material.dart';

import '../../../../nucleo/componentes/selector_imagen.dart';
import '../../../../nucleo/configuracion/constantes.dart';
import '../../dominio/modelo_servicio.dart';

class FormularioServicio extends StatefulWidget {
  const FormularioServicio({super.key, this.servicio, required this.alGuardar});

  final ModeloServicio? servicio;
  final Future<void> Function(ModeloServicio) alGuardar;

  @override
  State<FormularioServicio> createState() => _FormularioServicioState();
}

class _FormularioServicioState extends State<FormularioServicio> {
  final _formularioKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _duracionCtrl;
  late final TextEditingController _precioCtrl;
  final _scrollCtrl = ScrollController();
  late bool _activo;
  bool _cargando = false;
  String? _errorMensaje;
  String? _urlImagen;
  double _insetInferiorAnterior = 0;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.servicio?.nombre ?? '');
    _descripcionCtrl = TextEditingController(
      text: widget.servicio?.descripcion ?? '',
    );
    _duracionCtrl = TextEditingController(
      text: widget.servicio?.duracionMin.toString() ?? '30',
    );
    _precioCtrl = TextEditingController(
      text: widget.servicio?.precio.toString() ?? '50.00',
    );
    _activo = widget.servicio?.activo ?? true;
    _urlImagen = widget.servicio?.urlImagen;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _duracionCtrl.dispose();
    _precioCtrl.dispose();
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
      final servicio = ModeloServicio(
        id:
            widget.servicio?.id ??
            '', // Upsert resolver el ID vaco en Supabase
        barberiaId: widget.servicio?.barberiaId ?? '',
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        duracionMin: int.parse(_duracionCtrl.text.trim()),
        precio: double.parse(_precioCtrl.text.trim()),
        activo: _activo,
        urlImagen: _urlImagen,
      );

      await widget.alGuardar(servicio);
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
                widget.servicio == null ? 'Nuevo Servicio' : 'Editar Servicio',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SelectorImagen(
                bucket: Constantes.bucketImagenesApp,
                carpeta: 'servicios',
                urlActual: _urlImagen,
                alSubir: (url) => setState(() => _urlImagen = url),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Servicio *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El nombre es requerido'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripcin',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duracionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Duracin (min) *',
                        border: OutlineInputBorder(),
                        suffixText: 'min',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final parsed = int.tryParse(v);
                        if (parsed == null || parsed <= 0) {
                          return 'Debe ser > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio (Bs.) *',
                        border: OutlineInputBorder(),
                        prefixText: 'Bs. ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final parsed = double.tryParse(v);
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
              SwitchListTile(
                title: const Text('Servicio Activo'),
                value: _activo,
                onChanged: (val) => setState(() => _activo = val),
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
