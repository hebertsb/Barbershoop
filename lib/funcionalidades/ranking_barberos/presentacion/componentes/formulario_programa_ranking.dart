import 'package:flutter/material.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/utilidades/formato_fecha.dart';
import '../../../administracion/dominio/modelo_sucursal.dart';
import '../../dominio/enum_tipo_premio_ranking.dart';
import '../../dominio/modelo_programa_ranking_barberos.dart';
import '../../dominio/pesos_ranking_suman_100.dart';

class FormularioProgramaRanking extends StatefulWidget {
  const FormularioProgramaRanking({
    super.key,
    this.programa,
    required this.sucursales,
    required this.alGuardar,
  });

  final ModeloProgramaRankingBarberos? programa;
  final List<ModeloSucursal> sucursales;
  final Future<void> Function(ModeloProgramaRankingBarberos) alGuardar;

  @override
  State<FormularioProgramaRanking> createState() =>
      _FormularioProgramaRankingState();
}

class _FormularioProgramaRankingState extends State<FormularioProgramaRanking> {
  final _formularioKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _pesoCitasCtrl;
  late final TextEditingController _pesoIngresosCtrl;
  late final TextEditingController _pesoClientesCtrl;
  late final TextEditingController _pesoPuntualidadCtrl;
  late final TextEditingController _pesoCalificacionCtrl;
  late final TextEditingController _descripcionPremioCtrl;
  final _scrollCtrl = ScrollController();
  double _insetInferiorAnterior = 0;
  String? _sucursalId;
  TipoPremioRanking _tipoPremio = TipoPremioRanking.dinero;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _cargando = false;
  String? _errorMensaje;
  bool _bloqueandoDropdown = false;
  FocusScopeNode? _focusScopeNode;

  @override
  void initState() {
    super.initState();
    final p = widget.programa;
    _tituloCtrl = TextEditingController(text: p?.titulo ?? '');
    _pesoCitasCtrl = TextEditingController(
      text: (p?.pesoCitas ?? 20).toString(),
    );
    _pesoIngresosCtrl = TextEditingController(
      text: (p?.pesoIngresos ?? 20).toString(),
    );
    _pesoClientesCtrl = TextEditingController(
      text: (p?.pesoClientes ?? 20).toString(),
    );
    _pesoPuntualidadCtrl = TextEditingController(
      text: (p?.pesoPuntualidad ?? 20).toString(),
    );
    _pesoCalificacionCtrl = TextEditingController(
      text: (p?.pesoCalificacion ?? 20).toString(),
    );
    _descripcionPremioCtrl = TextEditingController(
      text: p?.descripcionPremio ?? '',
    );
    _sucursalId =
        p?.sucursalId ??
        (widget.sucursales.isNotEmpty ? widget.sucursales.first.id : null);
    _tipoPremio = p?.tipoPremio ?? TipoPremioRanking.dinero;
    _fechaInicio = p?.fechaInicio;
    _fechaFin = p?.fechaFin;
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
  /// alguno toma foco (teclado abriéndose) bloquea los dropdowns YA, antes
  /// de que el usuario llegue a tocarlos. Así el hit-test de un toque
  /// posterior sobre el dropdown ve `absorbing == true` y su menú nunca se
  /// abre con el layout todavía en posición "con teclado abierto". Al
  /// perder el foco del todo, espera a que termine la animación de cierre
  /// del teclado (~300ms) antes de reactivarlo.
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
    _pesoCitasCtrl.dispose();
    _pesoIngresosCtrl.dispose();
    _pesoClientesCtrl.dispose();
    _pesoPuntualidadCtrl.dispose();
    _pesoCalificacionCtrl.dispose();
    _descripcionPremioCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Cuando el teclado se cierra, el `SingleChildScrollView` puede quedar
  /// con el scroll desplazado hacia arriba (bug conocido de Flutter, mismo
  /// fix ya aplicado en el resto de formularios de esta app).
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
    if (picked != null) setState(() => _fechaInicio = picked);
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
    if (picked != null) setState(() => _fechaFin = picked);
  }

  int _leerPeso(TextEditingController ctrl) =>
      int.tryParse(ctrl.text.trim()) ?? 0;

  Future<void> _guardar() async {
    if (!_formularioKey.currentState!.validate()) return;
    if (_sucursalId == null) {
      setState(() => _errorMensaje = 'Elegí una sucursal.');
      return;
    }
    if (_fechaInicio == null || _fechaFin == null) {
      setState(() => _errorMensaje = 'Elegí la fecha de inicio y fin.');
      return;
    }
    if (_fechaFin!.isBefore(_fechaInicio!)) {
      setState(
        () => _errorMensaje =
            'La fecha fin no puede ser anterior a la fecha inicio.',
      );
      return;
    }
    final pesoCitas = _leerPeso(_pesoCitasCtrl);
    final pesoIngresos = _leerPeso(_pesoIngresosCtrl);
    final pesoClientes = _leerPeso(_pesoClientesCtrl);
    final pesoPuntualidad = _leerPeso(_pesoPuntualidadCtrl);
    final pesoCalificacion = _leerPeso(_pesoCalificacionCtrl);
    if (!pesosRankingSuman100(
      pesoCitas: pesoCitas,
      pesoIngresos: pesoIngresos,
      pesoClientes: pesoClientes,
      pesoPuntualidad: pesoPuntualidad,
      pesoCalificacion: pesoCalificacion,
    )) {
      setState(
        () => _errorMensaje =
            'Los 5 pesos deben sumar 100 (hoy suman '
            '${pesoCitas + pesoIngresos + pesoClientes + pesoPuntualidad + pesoCalificacion}).',
      );
      return;
    }

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final programa = ModeloProgramaRankingBarberos(
        id: widget.programa?.id ?? '',
        barberiaId: widget.programa?.barberiaId ?? '',
        sucursalId: _sucursalId!,
        titulo: _tituloCtrl.text.trim(),
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        pesoCitas: pesoCitas,
        pesoIngresos: pesoIngresos,
        pesoClientes: pesoClientes,
        pesoPuntualidad: pesoPuntualidad,
        pesoCalificacion: pesoCalificacion,
        tipoPremio: _tipoPremio,
        descripcionPremio: _descripcionPremioCtrl.text.trim(),
        estado: widget.programa?.estado ?? 'activo',
        premioEntregado: widget.programa?.premioEntregado ?? false,
      );
      await widget.alGuardar(programa);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _errorMensaje = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _campoPeso(String etiqueta, TextEditingController ctrl) {
    return Expanded(
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          final val = int.tryParse(v?.trim() ?? '');
          if (val == null || val < 0 || val > 100) return '0-100';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insetInferior = MediaQuery.of(context).viewInsets.bottom;
    _reajustarScrollSiSeCerroElTeclado(insetInferior);
    final esCerrado = widget.programa?.estaCerrado ?? false;
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
                widget.programa == null
                    ? 'Nuevo Programa de Ranking'
                    : 'Editar Programa de Ranking',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloCtrl,
                enabled: !esCerrado,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  helperText: 'Ej. "Ranking de Julio"',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El título es requerido'
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
                    initialValue: _sucursalId,
                    decoration: const InputDecoration(
                      labelText: 'Sucursal *',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.sucursales
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: esCerrado
                        ? null
                        : (val) => setState(() => _sucursalId = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: esCerrado ? null : _seleccionarFechaInicio,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _fechaInicio == null
                            ? 'Fecha inicio *'
                            : formatoFechaCorta(_fechaInicio!),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: esCerrado ? null : _seleccionarFechaFin,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _fechaFin == null
                            ? 'Fecha fin *'
                            : formatoFechaCorta(_fechaFin!),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Peso de cada factor (deben sumar 100) *',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _campoPeso('Citas %', _pesoCitasCtrl),
                  const SizedBox(width: 8),
                  _campoPeso('Ingresos %', _pesoIngresosCtrl),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _campoPeso('Clientes %', _pesoClientesCtrl),
                  const SizedBox(width: 8),
                  _campoPeso('Puntualidad %', _pesoPuntualidadCtrl),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [_campoPeso('Calificación %', _pesoCalificacionCtrl)],
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
                  child: DropdownButtonFormField<TipoPremioRanking>(
                    initialValue: _tipoPremio,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de premio (1er lugar) *',
                      border: OutlineInputBorder(),
                    ),
                    items: TipoPremioRanking.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.etiqueta),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _tipoPremio = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionPremioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción del premio *',
                  helperText: 'Ej. "Bs 200", "Set de navajas", "Sorpresa"',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Describí el premio' : null,
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 16),
                Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.primario,
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