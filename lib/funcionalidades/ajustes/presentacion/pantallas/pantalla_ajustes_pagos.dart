import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/selector_imagen.dart';
import '../../../../nucleo/configuracion/constantes.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/enum_modo_pago.dart';
import '../../dominio/modelo_configuracion_pagos.dart';
import '../componentes/seccion_tolerancia_no_asistio.dart';
import '../controladores/controlador_ajustes_pagos.dart';

/// Pantalla de admin para configurar el modo de pago de la barbería: QR del
/// banco, modo (obligatorio/opcional/seña), % de seña y minutos de gracia.
class PantallaAjustesPagos extends ConsumerStatefulWidget {
  const PantallaAjustesPagos({super.key});

  @override
  ConsumerState<PantallaAjustesPagos> createState() =>
      _PantallaAjustesPagosState();
}

class _PantallaAjustesPagosState extends ConsumerState<PantallaAjustesPagos> {
  final _formKey = GlobalKey<FormState>();

  ModoPago? _modo;
  int? _porcentajeSena;
  int? _minutosGraciaPago;
  String? _urlQrBanco;
  bool _guardando = false;

  // Una vez que llegó el primer dato del controlador, los campos de arriba
  // pasan a ser la única fuente de verdad de este formulario: un
  // `AsyncLoading`/`AsyncError` posterior (los que dispara `guardar()` sobre
  // el propio provider) ya no debe volver a pisarlos ni tapar el formulario.
  bool _inicializado = false;

  void _inicializarSiHaceFalta(ModeloConfiguracionPagos config) {
    if (_inicializado) return;
    _modo = config.modo;
    _porcentajeSena = config.porcentajeSena;
    _minutosGraciaPago = config.minutosGraciaPago;
    _urlQrBanco = config.urlQrBanco;
    _inicializado = true;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    try {
      await ref
          .read(controladorAjustesPagosProvider.notifier)
          .guardar(
            ModeloConfiguracionPagos(
              modo: _modo!,
              porcentajeSena: _porcentajeSena!,
              minutosGraciaPago: _minutosGraciaPago!,
              urlQrBanco: _urlQrBanco,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada.')),
        );
      }
    } catch (e) {
      // El formulario (campos de estado local) no se toca: el admin no
      // pierde lo que ya tenía tipeado/seleccionado si el guardado falla.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(controladorAjustesPagosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Solo se usa el `AsyncValue` del provider para la carga INICIAL. Una vez
    // inicializado el formulario, `guardar()` puede volver a poner el
    // provider en loading/error (reasigna `state` entero sin conservar el
    // valor previo) pero eso ya no debe ocultar el formulario: se maneja acá
    // abajo con el `_guardando` local y el try/catch de `_guardar()`.
    if (!_inicializado) {
      if (configState.hasValue) {
        _inicializarSiHaceFalta(configState.value!);
      } else if (configState.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes de pago')),
          body: Center(
            child: Text(
              configState.error.toString(),
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        );
      } else {
        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes de pago')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de pago')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR del banco',
                    style: TipografiaApp.labelMd.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectorImagen(
                    bucket: Constantes.bucketImagenesApp,
                    carpeta: 'qr-banco',
                    urlActual: _urlQrBanco,
                    alSubir: (url) => setState(() => _urlQrBanco = url),
                    altura: 320,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Modo de pago',
                    style: TipografiaApp.labelMd.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  RadioGroup<ModoPago>(
                    groupValue: _modo,
                    onChanged: (v) => setState(() => _modo = v),
                    child: const Column(
                      children: [
                        RadioListTile<ModoPago>(
                          title: Text('Obligatorio'),
                          subtitle: Text('El cliente debe pagar para reservar'),
                          value: ModoPago.obligatorio,
                        ),
                        RadioListTile<ModoPago>(
                          title: Text('Opcional'),
                          subtitle: Text(
                            'El cliente puede pagar o hacerlo en el local',
                          ),
                          value: ModoPago.opcional,
                        ),
                        RadioListTile<ModoPago>(
                          title: Text('Solo seña'),
                          subtitle: Text('El cliente paga un % por adelantado'),
                          value: ModoPago.sena,
                        ),
                      ],
                    ),
                  ),
                  if (_modo == ModoPago.sena) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const ValueKey('porcentajeSena'),
                      initialValue: _porcentajeSena?.toString(),
                      decoration: const InputDecoration(
                        labelText: '% de seña',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          _porcentajeSena = int.tryParse(v) ?? _porcentajeSena,
                      validator: (v) {
                        final valor = int.tryParse(v ?? '');
                        if (valor == null) return 'Ingresa un número válido';
                        if (valor < 0 || valor > 100) {
                          return 'Debe estar entre 0 y 100';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_modo == ModoPago.obligatorio ||
                      _modo == ModoPago.sena) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const ValueKey('minutosGraciaPago'),
                      initialValue: _minutosGraciaPago?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Minutos de gracia antes de cancelar',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _minutosGraciaPago =
                          int.tryParse(v) ?? _minutosGraciaPago,
                      validator: (v) {
                        final valor = int.tryParse(v ?? '');
                        if (valor == null) return 'Ingresa un número válido';
                        if (valor < 1) return 'Debe ser al menos 1';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ),
            const SeccionToleranciaNoAsistio(),
          ],
        ),
      ),
    );
  }
}
