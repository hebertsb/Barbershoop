import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../nucleo/componentes/selector_imagen.dart';
import '../../../../nucleo/configuracion/constantes.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../dominio/modelo_marca_barberia.dart';
import '../componentes/seccion_instrucciones_cita.dart';
import '../controladores/controlador_ajustes_marca.dart';

/// Una opción de color de acento de la paleta prearmada (no theming libre).
class _OpcionColorAcento {
  const _OpcionColorAcento(this.hex, this.color, this.nombre);

  final String hex;
  final Color color;
  final String nombre;
}

/// Paleta prearmada de colores de acento. La primera opción (dorado) es el
/// color por defecto de la app: seleccionarla equivale a no personalizar
/// nada (`colorAcentoHex: null`).
const _paletaColorAcento = [
  _OpcionColorAcento('#F2CA50', Color(0xFFF2CA50), 'Dorado'),
  _OpcionColorAcento('#8B1E1E', Color(0xFF8B1E1E), 'Rojo oscuro'),
  _OpcionColorAcento('#1B4332', Color(0xFF1B4332), 'Verde bosque'),
  _OpcionColorAcento('#14213D', Color(0xFF14213D), 'Azul marino'),
  _OpcionColorAcento('#6B1E3C', Color(0xFF6B1E3C), 'Granate'),
  _OpcionColorAcento('#1C1C1C', Color(0xFF1C1C1C), 'Carbón'),
  _OpcionColorAcento('#0F5257', Color(0xFF0F5257), 'Teal'),
];

/// Pantalla de admin para configurar la marca de la barbería: nombre,
/// slogan, logo y un color de acento simple (paleta prearmada).
class PantallaAjustesMarca extends ConsumerStatefulWidget {
  const PantallaAjustesMarca({super.key});

  @override
  ConsumerState<PantallaAjustesMarca> createState() =>
      _PantallaAjustesMarcaState();
}

class _PantallaAjustesMarcaState extends ConsumerState<PantallaAjustesMarca> {
  final _formKey = GlobalKey<FormState>();

  String? _nombre;
  String? _slogan;
  String? _urlLogo;
  String? _colorAcentoHex;
  bool _guardando = false;

  // Mismo criterio que PantallaAjustesPagos: una vez inicializado el
  // formulario con el primer dato del controlador, un AsyncLoading/AsyncError
  // posterior (disparado por el propio guardar()) ya no debe pisar los
  // campos ni tapar el formulario.
  bool _inicializado = false;

  void _inicializarSiHaceFalta(ModeloMarcaBarberia marca) {
    if (_inicializado) return;
    _nombre = marca.nombre;
    _slogan = marca.slogan;
    _urlLogo = marca.urlLogo;
    _colorAcentoHex = marca.colorAcentoHex;
    _inicializado = true;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    try {
      await ref
          .read(controladorAjustesMarcaProvider.notifier)
          .guardar(
            ModeloMarcaBarberia(
              nombre: _nombre!.trim(),
              slogan: _slogan?.trim().isEmpty ?? true ? null : _slogan!.trim(),
              logoUrl: _urlLogo,
              colorAcentoHex: _colorAcentoHex,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Marca guardada.')));
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
    final marcaState = ref.watch(controladorAjustesMarcaProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!_inicializado) {
      if (marcaState.hasValue) {
        _inicializarSiHaceFalta(marcaState.value!);
      } else if (marcaState.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Marca de la barbería')),
          body: Center(
            child: Text(
              marcaState.error.toString(),
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        );
      } else {
        return Scaffold(
          appBar: AppBar(title: const Text('Marca de la barbería')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Marca de la barbería')),
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
                    'Logo',
                    style: TipografiaApp.labelMd.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectorImagen(
                    bucket: Constantes.bucketImagenesApp,
                    carpeta: 'logos',
                    urlActual: _urlLogo,
                    alSubir: (url) => setState(() => _urlLogo = url),
                    altura: 220,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const ValueKey('nombre'),
                    initialValue: _nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la barbería',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _nombre = v,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresa un nombre'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('slogan'),
                    initialValue: _slogan,
                    decoration: const InputDecoration(
                      labelText: 'Slogan (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _slogan = v,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Color de acento',
                    style: TipografiaApp.labelMd.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: _paletaColorAcento
                        .map(
                          (opcion) => _SwatchColorAcento(
                            opcion: opcion,
                            seleccionado: _colorEsElSeleccionado(opcion),
                            alPresionar: () => setState(() {
                              // El dorado es el color por defecto de la app:
                              // elegirlo equivale a no personalizar nada.
                              _colorAcentoHex =
                                  opcion.hex == _paletaColorAcento.first.hex
                                  ? null
                                  : opcion.hex;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 32),
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
            const SeccionInstruccionesCita(),
          ],
        ),
      ),
    );
  }

  bool _colorEsElSeleccionado(_OpcionColorAcento opcion) {
    if (_colorAcentoHex == null) {
      // null significa "usar el default", que es la primera opción.
      return opcion.hex == _paletaColorAcento.first.hex;
    }
    return _colorAcentoHex == opcion.hex;
  }
}

class _SwatchColorAcento extends StatelessWidget {
  const _SwatchColorAcento({
    required this.opcion,
    required this.seleccionado,
    required this.alPresionar,
  });

  final _OpcionColorAcento opcion;
  final bool seleccionado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: opcion.nombre,
      child: GestureDetector(
        onTap: alPresionar,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: opcion.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: seleccionado ? colorScheme.onSurface : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: seleccionado
              ? Icon(
                  Icons.check,
                  color:
                      ThemeData.estimateBrightnessForColor(opcion.color) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                )
              : null,
        ),
      ),
    );
  }
}