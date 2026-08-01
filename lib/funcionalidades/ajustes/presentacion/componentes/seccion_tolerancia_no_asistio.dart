import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../controladores/controlador_tolerancia_no_asistio.dart';

/// Sección de Ajustes de pago para configurar los minutos de tolerancia tras
/// la hora de una cita `pendiente` antes de que el cron
/// `marcar_no_asistio_vencidas` (`0028`) la marque automáticamente como
/// `no_asistio`. Independiente del formulario de [ModeloConfiguracionPagos]
/// de la pantalla que la contiene: usa su propio controlador, su propio
/// `Form` y su propio botón "Guardar" para no complicar (ni arriesgar) el
/// guardado de pagos ya existente.
class SeccionToleranciaNoAsistio extends ConsumerStatefulWidget {
  const SeccionToleranciaNoAsistio({super.key});

  @override
  ConsumerState<SeccionToleranciaNoAsistio> createState() =>
      _SeccionToleranciaNoAsistioState();
}

class _SeccionToleranciaNoAsistioState
    extends ConsumerState<SeccionToleranciaNoAsistio> {
  final _formKey = GlobalKey<FormState>();

  int? _minutos;
  bool _inicializado = false;
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    try {
      await ref
          .read(controladorToleranciaNoAsistioProvider.notifier)
          .guardar(_minutos!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tolerancia de no-show guardada.')),
        );
      }
    } catch (e) {
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
    final estado = ref.watch(controladorToleranciaNoAsistioProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!_inicializado && estado.hasValue) {
      _minutos = estado.value;
      _inicializado = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Tolerancia de no-show',
          style: TipografiaApp.labelMd.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Minutos después de la hora de la cita antes de marcarla '
          'automáticamente como no asistida.',
          style: TipografiaApp.bodySm.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (!_inicializado && estado.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (estado.hasError && !_inicializado)
          Text(
            estado.error.toString(),
            style: TextStyle(color: colorScheme.error),
          )
        else
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: const ValueKey('minutosToleranciaNoAsistio'),
                  initialValue: _minutos?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Minutos de tolerancia',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _minutos = int.tryParse(v) ?? _minutos,
                  validator: (v) {
                    final valor = int.tryParse(v ?? '');
                    if (valor == null) return 'Ingresa un número válido';
                    if (valor < 1) return 'Debe ser al menos 1';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar tolerancia'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
