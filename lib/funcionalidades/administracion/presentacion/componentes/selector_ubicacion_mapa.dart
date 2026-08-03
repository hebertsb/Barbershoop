import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../nucleo/configuracion/colores_app.dart';
import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../../nucleo/utilidades/abrir_mapa_externo.dart';

class SelectorUbicacionMapa extends StatefulWidget {
  const SelectorUbicacionMapa({
    super.key,
    this.latitudInicial,
    this.longitudInicial,
    this.alSeleccionarUbicacion,
  });

  final double? latitudInicial;
  final double? longitudInicial;
  final Function(double lat, double lng)? alSeleccionarUbicacion;

  @override
  State<SelectorUbicacionMapa> createState() => SelectorUbicacionMapaState();
}

class SelectorUbicacionMapaState extends State<SelectorUbicacionMapa> {
  double _lat = -16.5000;
  double _lng = -68.1500;
  bool _obteniendoUbicacion = false;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  @override
  void initState() {
    super.initState();
    _lat = widget.latitudInicial ?? -16.5000;
    _lng = widget.longitudInicial ?? -68.1500;
    _latCtrl = TextEditingController(text: _lat.toStringAsFixed(6));
    _lngCtrl = TextEditingController(text: _lng.toStringAsFixed(6));
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  ({double latitude, double longitude})? obtenerCentro() {
    return (latitude: _lat, longitude: _lng);
  }

  void _actualizarUbicacion(double lat, double lng) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _latCtrl.text = lat.toStringAsFixed(6);
      _lngCtrl.text = lng.toStringAsFixed(6);
    });
    widget.alSeleccionarUbicacion?.call(lat, lng);
  }

  Future<void> _usarUbicacionActual() async {
    setState(() => _obteniendoUbicacion = true);
    try {
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.whileInUse ||
          permiso == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        _actualizarUbicacion(pos.latitude, pos.longitude);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de ubicación denegado.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Canvas gráfico de mapa interactivo con PIN
          GestureDetector(
            onPanUpdate: (details) {
              final deltaLat = -details.delta.dy * 0.0001;
              final deltaLng = details.delta.dx * 0.0001;
              _actualizarUbicacion(_lat + deltaLat, _lng + deltaLng);
            },
            child: Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFF1E242B),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 48,
                          color: ColoresApp.primario,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(190),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ColoresApp.primario),
                          ),
                          child: Text(
                            'Desliza para mover pin de ubicación',
                            style: TipografiaApp.labelSm.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      icon: _obteniendoUbicacion
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 20),
                      tooltip: 'Usar mi ubicación actual',
                      onPressed: _obteniendoUbicacion ? null : _usarUbicacionActual,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Campos de Latitud y Longitud manuales + Botón Mapa Externo
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Latitud',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            setState(() => _lat = parsed);
                            widget.alSeleccionarUbicacion?.call(_lat, _lng);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Longitud',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            setState(() => _lng = parsed);
                            widget.alSeleccionarUbicacion?.call(_lat, _lng);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => abrirMapaExterno(_lat, _lng),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Abrir en Google Maps'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
