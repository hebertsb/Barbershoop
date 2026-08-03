import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/selector_imagen.dart';
import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/constantes.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../administracion/dominio/modelo_servicio.dart';
import '../../../administracion/presentacion/controladores/controlador_servicios.dart';
import '../../dominio/enum_tipo_descuento.dart';
import '../../dominio/modelo_promocion.dart';

class FormularioPromocion extends ConsumerStatefulWidget {
  const FormularioPromocion({
    super.key,
    this.promocion,
    required this.barberiaId,
    required this.alGuardar,
  });

  final ModeloPromocion? promocion;
  final String barberiaId;
  final Future<void> Function(ModeloPromocion) alGuardar;

  @override
  ConsumerState<FormularioPromocion> createState() =>
      _FormularioPromocionState();
}

class _FormularioPromocionState extends ConsumerState<FormularioPromocion> {
  final _formularioKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _descuentoCtrl;
  late final TextEditingController _limiteUsosCtrl;
  late final TextEditingController _capacidadMaximaCtrl;
  final _scrollCtrl = ScrollController();
  double _insetInferiorAnterior = 0;

  /// IDs de los servicios seleccionados para esta promoción.
  /// Vacío = aplica a todos los servicios.
  List<String> _serviciosSeleccionados = [];

  TipoDescuento _tipoDescuento = TipoDescuento.porcentaje;
  String? _imagenUrl;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _activo = true;
  bool _cargando = false;
  String? _errorMensaje;
  bool _bloqueandoDropdown = false;
  FocusScopeNode? _focusScopeNode;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.promocion?.titulo ?? '');
    _descripcionCtrl = TextEditingController(
      text: widget.promocion?.descripcion ?? '',
    );
    _descuentoCtrl = TextEditingController(
      text: widget.promocion?.descuento.toStringAsFixed(0) ?? '10',
    );
    _limiteUsosCtrl = TextEditingController(
      text: widget.promocion?.limiteUsosPorCliente?.toString() ?? '',
    );
    _capacidadMaximaCtrl = TextEditingController(
      text: widget.promocion?.capacidadMaxima?.toString() ?? '',
    );

    // Cargar servicios existentes al editar
    if (widget.promocion != null) {
      _serviciosSeleccionados = List<String>.from(
        widget.promocion!.serviciosIds,
      );
      if (_serviciosSeleccionados.isEmpty &&
          widget.promocion!.servicioId != null) {
        _serviciosSeleccionados = [widget.promocion!.servicioId!];
      }
    }

    _tipoDescuento =
        widget.promocion?.tipoDescuento ?? TipoDescuento.porcentaje;
    _imagenUrl = widget.promocion?.imagen;
    _fechaInicio = widget.promocion?.fechaInicio;
    _fechaFin = widget.promocion?.fechaFin;
    _activo = widget.promocion?.activo ?? true;
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
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _descuentoCtrl.dispose();
    _limiteUsosCtrl.dispose();
    _capacidadMaximaCtrl.dispose();
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

  Future<void> _seleccionarFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _fechaInicio = picked);
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _fechaFin ??
          _fechaInicio ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _fechaFin = picked);
    }
  }

  /// Abre el selector multi-servicio en un bottom sheet.
  Future<void> _seleccionarServicios(List<ModeloServicio> servicios) async {
    final seleccion = List<String>.from(_serviciosSeleccionados);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            final colorScheme = Theme.of(ctx).colorScheme;
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Servicios del Combo',
                          style: TipografiaApp.headlineSm.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Badge indicador de selección
                      if (seleccion.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ColoresApp.primario,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${seleccion.length} selec.',
                            style: TipografiaApp.labelSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona uno o más servicios. Con 2+ creas un combo '
                    '(ej. Corte + Barba).',
                    style: TipografiaApp.bodySm.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Opción "Todos los servicios"
                  CheckboxListTile(
                    value: seleccion.isEmpty,
                    title: Text(
                      'Todos los servicios',
                      style: TipografiaApp.bodyMd,
                    ),
                    subtitle: Text(
                      'La promo aplica sin importar el servicio',
                      style: TipografiaApp.bodySm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    activeColor: ColoresApp.primario,
                    onChanged: (v) {
                      setInner(() => seleccion.clear());
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  // Lista de servicios con checkbox
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: servicios.length,
                      itemBuilder: (_, i) {
                        final s = servicios[i];
                        final checked = seleccion.contains(s.id);
                        return CheckboxListTile(
                          value: checked,
                          title: Text(s.nombre, style: TipografiaApp.bodyMd),
                          subtitle: Text(
                            'Bs. ${s.precio.toStringAsFixed(0)} · ${s.duracionMin} min',
                            style: TipografiaApp.bodySm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          activeColor: ColoresApp.primario,
                          onChanged: (v) {
                            setInner(() {
                              if (v == true) {
                                seleccion.add(s.id);
                              } else {
                                seleccion.remove(s.id);
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresApp.primario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() => _serviciosSeleccionados = seleccion);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'CONFIRMAR SELECCIÓN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _guardar() async {
    if (!_formularioKey.currentState!.validate()) return;
    if (_fechaInicio != null &&
        _fechaFin != null &&
        _fechaFin!.isBefore(_fechaInicio!)) {
      setState(
        () => _errorMensaje =
            'La fecha fin no puede ser anterior a la fecha inicio.',
      );
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      // Obtener nombres de los servicios seleccionados
      final servicios = (ref.read(controladorServiciosProvider).value ?? []);
      final nombresSeleccionados = _serviciosSeleccionados
          .map((id) {
            final candidatos = servicios.where((s) => s.id == id).toList();
            return candidatos.isEmpty ? null : candidatos.first.nombre;
          })
          .whereType<String>()
          .toList();

      final primerServicioId = _serviciosSeleccionados.isNotEmpty
          ? _serviciosSeleccionados.first
          : null;

      final promo = ModeloPromocion(
        id: widget.promocion?.id ?? '',
        barberiaId: widget.barberiaId,
        servicioId: primerServicioId,
        nombreServicio: nombresSeleccionados.isNotEmpty
            ? nombresSeleccionados.first
            : null,
        serviciosIds: _serviciosSeleccionados,
        nombresServicios: nombresSeleccionados,
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        imagen: _imagenUrl,
        tipoDescuento: _tipoDescuento,
        descuento: double.parse(_descuentoCtrl.text.trim()),
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        activo: _activo,
        limiteUsosPorCliente: _limiteUsosCtrl.text.trim().isEmpty
            ? null
            : int.parse(_limiteUsosCtrl.text.trim()),
        capacidadMaxima: _capacidadMaximaCtrl.text.trim().isEmpty
            ? null
            : int.parse(_capacidadMaximaCtrl.text.trim()),
      );
      await widget.alGuardar(promo);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _errorMensaje = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Texto del botón de selección de servicios.
  String _textoBotonServicios(List<ModeloServicio> servicios) {
    if (_serviciosSeleccionados.isEmpty) return 'Todos los servicios';
    if (_serviciosSeleccionados.length == 1) {
      final candidatos = servicios
          .where((s) => s.id == _serviciosSeleccionados.first)
          .toList();
      return candidatos.isEmpty ? '1 servicio' : candidatos.first.nombre;
    }
    // Combo: "Corte + Barba (y 1 más)" si son muchos
    final nombres = _serviciosSeleccionados
        .take(2)
        .map((id) {
          final candidatos = servicios.where((s) => s.id == id).toList();
          return candidatos.isEmpty ? '?' : candidatos.first.nombre;
        })
        .join(' + ');
    final extra = _serviciosSeleccionados.length - 2;
    return extra > 0 ? '$nombres (+$extra)' : nombres;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final servicios = (ref.watch(controladorServiciosProvider).value ?? [])
        .where((s) => s.activo)
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
              // Título del formulario
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.promocion == null
                          ? 'Nueva Promoción'
                          : 'Editar Promoción',
                      style: TipografiaApp.headlineSm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Badge COMBO si tiene más de un servicio
                  if (_serviciosSeleccionados.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColoresApp.primario,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'COMBO',
                            style: TipografiaApp.labelSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título de la promoción *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El título es requerido'
                    : null,
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Términos',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // ── SELECTOR DE SERVICIOS (combo) ──────────────────────────
              InkWell(
                onTap: () => _seleccionarServicios(servicios),
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Servicios aplicables',
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
                    ),
                    helperText: _serviciosSeleccionados.length > 1
                        ? '🎁 COMBO: ${_serviciosSeleccionados.length} servicios'
                        : null,
                    helperStyle: TipografiaApp.labelSm.copyWith(
                      color: ColoresApp.primario,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(
                    _textoBotonServicios(servicios),
                    style: TipografiaApp.bodyMd.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Preview del combo seleccionado (chips)
              if (_serviciosSeleccionados.length > 1) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _serviciosSeleccionados.map((id) {
                    final candidatos = servicios
                        .where((s) => s.id == id)
                        .toList();
                    final nombre = candidatos.isEmpty
                        ? id
                        : candidatos.first.nombre;
                    return Chip(
                      label: Text(
                        nombre,
                        style: TipografiaApp.labelSm.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: ColoresApp.primario.withValues(
                        alpha: 0.85,
                      ),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                      onDeleted: () {
                        setState(() => _serviciosSeleccionados.remove(id));
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),

              // ── TIPO DE DESCUENTO + MONTO (en columna para evitar overflow) ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Listener(
                    onPointerDown: (_) {
                      if (_focusScopeNode?.hasFocus ?? false) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    child: AbsorbPointer(
                      absorbing: _bloqueandoDropdown,
                      child: DropdownButtonFormField<TipoDescuento>(
                        value: _tipoDescuento,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de descuento',
                          border: OutlineInputBorder(),
                        ),
                        items: TipoDescuento.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.etiqueta),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(
                          () => _tipoDescuento = val ?? _tipoDescuento,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descuentoCtrl,
                    decoration: InputDecoration(
                      labelText: _tipoDescuento == TipoDescuento.porcentaje
                          ? 'Descuento (%) *'
                          : 'Descuento (Bs.) *',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        _tipoDescuento == TipoDescuento.porcentaje
                            ? Icons.percent
                            : Icons.attach_money,
                        size: 20,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Debe ser > 0';
                      if (_tipoDescuento == TipoDescuento.porcentaje &&
                          val > 100) {
                        return 'Máx 100%';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── FECHAS ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarFechaInicio,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _fechaInicio == null
                            ? 'Fecha inicio'
                            : formatoFechaCorta(_fechaInicio!),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarFechaFin,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _fechaFin == null
                            ? 'Fecha fin'
                            : formatoFechaCorta(_fechaFin!),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── LÍMITE DE USOS POR CLIENTE ──────────────────────────────
              TextFormField(
                controller: _limiteUsosCtrl,
                decoration: const InputDecoration(
                  labelText: 'Límite de usos por cliente (opcional)',
                  helperText:
                      'Vacío = sin límite. Cuántas veces máximo puede '
                      'reservar UN MISMO cliente con esta promo.',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final val = int.tryParse(v.trim());
                  if (val == null || val <= 0) {
                    return 'Debe ser un número entero mayor a 0, o vacío '
                        'para sin límite';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── CAPACIDAD MÁXIMA TOTAL ──────────────────────────────────
              TextFormField(
                controller: _capacidadMaximaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Capacidad máxima total (opcional)',
                  helperText:
                      'Vacío = sin límite. Cuántos usos en TOTAL tiene esta '
                      'promo, sumando TODOS los clientes (ej. "solo para '
                      'los primeros 50 que la pidan").',
                  helperMaxLines: 3,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final val = int.tryParse(v.trim());
                  if (val == null || val <= 0) {
                    return 'Debe ser un número entero mayor a 0, o vacío '
                        'para sin límite';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── IMAGEN ────────────────────────────────────────────────────
              SelectorImagen(
                bucket: Constantes.bucketImagenesApp,
                carpeta: 'promociones',
                urlActual: _imagenUrl,
                alSubir: (url) => setState(() => _imagenUrl = url),
              ),
              const SizedBox(height: 12),

              // ── ESTADO ────────────────────────────────────────────────────
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Promoción Activa'),
                subtitle: const Text(
                  'Si se desactiva, los clientes no la verán',
                ),
                value: _activo,
                onChanged: (val) => setState(() => _activo = val),
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 12),
                Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.primario,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar Promoción',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}