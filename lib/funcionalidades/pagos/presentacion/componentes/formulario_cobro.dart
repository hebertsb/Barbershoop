import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/visor_imagen_pantalla_completa.dart';
import '../../../ajustes/presentacion/controladores/controlador_ajustes_pagos.dart';
import '../../dominio/enum_metodo_pago.dart';

class FormularioCobro extends ConsumerStatefulWidget {
  const FormularioCobro({
    super.key,
    required this.precioSugerido,
    required this.alConfirmar,
    this.etiquetaMonto,
  });

  final double precioSugerido;
  final Future<void> Function(double monto, MetodoPago metodo) alConfirmar;

  /// Reemplaza el label por defecto del campo de monto (ej. "Saldo
  /// pendiente (Bs.) *" cuando la cita ya tiene una seña pagada).
  final String? etiquetaMonto;

  @override
  ConsumerState<FormularioCobro> createState() => _FormularioCobroState();
}

class _FormularioCobroState extends ConsumerState<FormularioCobro> {
  final _formularioKey = GlobalKey<FormState>();
  late final TextEditingController _montoCtrl;
  final _scrollCtrl = ScrollController();
  MetodoPago _metodoSeleccionado = MetodoPago.efectivo;
  bool _cargando = false;
  String? _errorMensaje;
  double _insetInferiorAnterior = 0;

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(
      text: widget.precioSugerido.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
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

  Future<void> _confirmar() async {
    if (!_formularioKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });
    try {
      final monto = double.parse(_montoCtrl.text.trim().replaceAll(',', '.'));
      await widget.alConfirmar(monto, _metodoSeleccionado);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _errorMensaje = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// QR del banco para que el cajero se lo muestre al cliente al cobrar en
  /// persona. Si todavía no hay configuración cargada (carga inicial, error)
  /// o el admin nunca subió un QR, se muestra un aviso en su lugar: esto es
  /// solo una ayuda visual y nunca debe bloquear el cobro.
  Widget _qrBanco(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final urlQrBanco = ref
        .watch(controladorAjustesPagosProvider)
        .valueOrNull
        ?.urlQrBanco;

    if (urlQrBanco == null) {
      return Text(
        'No hay QR configurado. Configuralo en Ajustes de pago.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      );
    }

    return GestureDetector(
      onTap: () => mostrarImagenPantallaCompleta(context, urlQrBanco),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 260,
          height: 260,
          child: CachedNetworkImage(
            imageUrl: urlQrBanco,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined, color: colorScheme.error),
                const SizedBox(height: 8),
                Text(
                  'No se pudo cargar el QR',
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                'Cobrar servicio',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoCtrl,
                decoration: InputDecoration(
                  labelText: widget.etiquetaMonto ?? 'Monto (Bs.) *',
                  border: const OutlineInputBorder(),
                  prefixText: 'Bs. ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final monto = double.tryParse(
                    (v ?? '').trim().replaceAll(',', '.'),
                  );
                  if (monto == null || monto <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<MetodoPago>(
                segments: const [
                  ButtonSegment(
                    value: MetodoPago.efectivo,
                    label: Text('Efectivo'),
                    icon: Icon(Icons.payments_outlined),
                  ),
                  ButtonSegment(
                    value: MetodoPago.qrManual,
                    label: Text('QR'),
                    icon: Icon(Icons.qr_code),
                  ),
                ],
                selected: {_metodoSeleccionado},
                onSelectionChanged: (seleccion) {
                  setState(() => _metodoSeleccionado = seleccion.first);
                },
              ),
              if (_metodoSeleccionado == MetodoPago.qrManual) ...[
                const SizedBox(height: 16),
                Center(child: _qrBanco(context)),
              ],
              if (_errorMensaje != null) ...[
                const SizedBox(height: 16),
                Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _confirmar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Confirmar cobro'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}