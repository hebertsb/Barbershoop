import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber_app/nucleo/configuracion/tipografia_app.dart';
import 'package:barber_app/nucleo/utilidades/formato_moneda.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_servicio.dart';
import 'package:barber_app/funcionalidades/administracion/presentacion/controladores/controlador_servicios.dart';
import 'package:barber_app/funcionalidades/turnos/presentacion/controladores/controlador_turnos.dart';

/// Bottom-sheet para crear un turno de mostrador (walk-in).
/// Permite buscar un cliente registrado por email o crear uno walk-in
/// con nombre + telfono.
class DialogoNuevoTurno extends ConsumerStatefulWidget {
  const DialogoNuevoTurno({super.key, required this.sucursalId});

  final String sucursalId;

  @override
  ConsumerState<DialogoNuevoTurno> createState() => _DialogoNuevoTurnoState();
}

class _DialogoNuevoTurnoState extends ConsumerState<DialogoNuevoTurno> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  ModeloServicio? _servicioSeleccionado;
  bool _esWalkin = true;
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final serviciosState = ref.watch(controladorServiciosProvider);
    final servicios =
        (serviciosState.value ?? []).where((s) => s.activo).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ttulo
              Row(
                children: [
                  Text(
                    'Nuevo turno de caja',
                    style: TipografiaApp.headlineSm
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Toggle: Walk-in vs. cliente registrado
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Walk-in'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Registrado'),
                    icon: Icon(Icons.person_search),
                  ),
                ],
                selected: {_esWalkin},
                onSelectionChanged: (seleccion) {
                  setState(() {
                    _esWalkin = seleccion.first;
                    _errorMensaje = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Campos segn tipo
              if (_esWalkin) ...[
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telfono (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ] else ...[
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email del cliente *',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    helperText: 'Se busca por email en la base de datos',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ],
              const SizedBox(height: 12),

              // Seleccin de servicio
              DropdownButtonFormField<ModeloServicio>(
                decoration: const InputDecoration(
                  labelText: 'Servicio *',
                  prefixIcon: Icon(Icons.content_cut_outlined),
                  border: OutlineInputBorder(),
                ),
                items: servicios
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.nombre}  ${formatoMoneda(s.precio)}'),
                      ),
                    )
                    .toList(),
                onChanged: (s) => setState(() => _servicioSeleccionado = s),
                validator: (_) => _servicioSeleccionado == null
                    ? 'Seleccion un servicio'
                    : null,
              ),
              const SizedBox(height: 12),

              // Error
              if (_errorMensaje != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMensaje!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Botn confirmar
              FilledButton.icon(
                onPressed: _cargando ? null : _confirmar,
                icon: _cargando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.queue),
                label: const Text('Agregar a la cola'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final controlador = ref.read(
        controladorTurnosProvider(widget.sucursalId).notifier,
      );

      if (_esWalkin) {
        await controlador.crearTurnoWalkin(
          servicioId: _servicioSeleccionado!.id,
          nombre: _nombreCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
        );
      } else {
        final cliente =
            await controlador.buscarClientePorEmail(_emailCtrl.text.trim());
        if (cliente == null) {
          setState(() {
            _errorMensaje = 'No se encontr ningn cliente con ese email.';
            _cargando = false;
          });
          return;
        }
        await controlador.crearTurnoConCuenta(
          servicioId: _servicioSeleccionado!.id,
          clienteId: cliente['id']!,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMensaje = 'Error al crear el turno: $e';
        _cargando = false;
      });
    }
  }
}
