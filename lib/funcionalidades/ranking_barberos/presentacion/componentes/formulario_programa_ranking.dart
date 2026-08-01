import 'package:flutter/material.dart';

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

class _FormularioProgramaRankingState
    extends State<FormularioProgramaRanking> {
  final _formularioKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _pesoCitasCtrl;
  late final TextEditingController _pesoIngresosCtrl;
  late final TextEditingController _pesoClientesCtrl;
  late final TextEditingController _pesoPuntualidadCtrl;
  late final TextEditingController _pesoCalificacionCtrl;
  late final TextEditingController _descripcionPremioCtrl;
  String? _sucursalId;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  late TipoPremioRanking _tipoPremio;
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    final p = widget.programa;
    _tituloCtrl = TextEditingController(text: p?.titulo ?? '');
    _pesoCitasCtrl = TextEditingController(text: (p?.pesoCitas ?? 20).toString());
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
    _sucursalId = p?.sucursalId ?? widget.sucursales.firstOrNull?.id;
    _fechaInicio = p?.fechaInicio;
    _fechaFin = p?.fechaFin;
    _tipoPremio = p?.tipoPremio ?? TipoPremioRanking.dinero;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _pesoCitasCtrl.dispose();
    _pesoIngresosCtrl.dispose();
    _pesoClientesCtrl.dispose();
    _pesoPuntualidadCtrl.dispose();
    _pesoCalificacionCtrl.dispose();
    _descripcionPremioCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: (esInicio ? _fechaInicio : _fechaFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = fecha;
      } else {
        _fechaFin = fecha;
      }
    });
  }

  Future<void> _guardar() async {
    if (!(_formularioKey.currentState?.validate() ?? false)) return;
    if (_sucursalId == null || _fechaInicio == null || _fechaFin == null) {
      setState(() => _errorMensaje = 'Completa sucursal y fechas.');
      return;
    }

    final pesoCitas = int.parse(_pesoCitasCtrl.text);
    final pesoIngresos = int.parse(_pesoIngresosCtrl.text);
    final pesoClientes = int.parse(_pesoClientesCtrl.text);
    final pesoPuntualidad = int.parse(_pesoPuntualidadCtrl.text);
    final pesoCalificacion = int.parse(_pesoCalificacionCtrl.text);

    if (!pesosRankingSuman100(
      pesoCitas: pesoCitas,
      pesoIngresos: pesoIngresos,
      pesoClientes: pesoClientes,
      pesoPuntualidad: pesoPuntualidad,
      pesoCalificacion: pesoCalificacion,
    )) {
      setState(() => _errorMensaje = 'Los 5 pesos deben sumar 100.');
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
      if (mounted) Navigator.of(context).pop();
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
        decoration: InputDecoration(labelText: etiqueta, isDense: true),
        validator: (v) =>
            (int.tryParse(v ?? '') == null) ? 'Inválido' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formularioKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.programa == null
                    ? 'Nuevo programa de ranking'
                    : 'Editar programa de ranking',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa un título'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sucursalId,
                decoration: const InputDecoration(labelText: 'Sucursal'),
                items: widget.sucursales
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.nombre)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _sucursalId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _elegirFecha(esInicio: true),
                      child: Text(
                        _fechaInicio == null
                            ? 'Fecha inicio'
                            : '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _elegirFecha(esInicio: false),
                      child: Text(
                        _fechaFin == null
                            ? 'Fecha fin'
                            : '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Pesos (deben sumar 100)'),
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
              _campoPeso('Calificación %', _pesoCalificacionCtrl),
              const SizedBox(height: 16),
              DropdownButtonFormField<TipoPremioRanking>(
                initialValue: _tipoPremio,
                decoration: const InputDecoration(labelText: 'Tipo de premio'),
                items: TipoPremioRanking.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.etiqueta()),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _tipoPremio = v ?? _tipoPremio),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionPremioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción del premio',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Describe el premio'
                    : null,
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMensaje!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _guardar,
                  child: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
