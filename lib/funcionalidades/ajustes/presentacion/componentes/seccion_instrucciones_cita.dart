import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../controladores/controlador_instrucciones_cita.dart';

/// Sección de Ajustes de marca para configurar el texto que el cliente ve
/// al tocar "Instrucciones" en la tarjeta de su próxima cita. Independiente
/// del formulario de marca de la pantalla que la contiene: propio
/// controlador, propio Form, propio botón "Guardar" -- mismo criterio que
/// `SeccionToleranciaNoAsistio`.
class SeccionInstruccionesCita extends ConsumerStatefulWidget {
  const SeccionInstruccionesCita({super.key});

  @override
  ConsumerState<SeccionInstruccionesCita> createState() =>
      _SeccionInstruccionesCitaState();
}

class _SeccionInstruccionesCitaState
    extends ConsumerState<SeccionInstruccionesCita> {
  final _formKey = GlobalKey<FormState>();

  String? _texto;
  bool _inicializado = false;
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    try {
      await ref
          .read(controladorInstruccionesCitaProvider.notifier)
          .guardar(_texto!.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instrucciones guardadas.')),
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
    final estado = ref.watch(controladorInstruccionesCitaProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!_inicializado && estado.hasValue) {
      _texto = estado.value;
      _inicializado = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Instrucciones para el cliente',
          style: TipografiaApp.labelMd.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Texto que ve el cliente al tocar "Instrucciones" en su próxima cita.',
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
                  key: const ValueKey('instruccionesCita'),
                  initialValue: _texto,
                  decoration: const InputDecoration(
                    labelText: 'Instrucciones',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (v) => _texto = v,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa un texto'
                      : null,
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
                      : const Text('Guardar instrucciones'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}