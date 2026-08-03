import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
  late double _lat;
  late double _lng;
  bool _obteniendoUbicacion = false;
  late final MapController _mapController;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  @override
  void initState() {
    super.initState();
    _lat = widget.latitudInicial ?? -16.5000;
    _lng = widget.longitudInicial ?? -68.1500;
    _mapController = MapController();
    _latCtrl = TextEditingController(text: _lat.toStringAsFixed(6));
    _lngCtrl = TextEditingController(text: _lng.toStringAsFixed(6));
  }

  @override
  void dispose() {
    _mapController.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  ({double latitude, double longitude})? obtenerCentro() {
    return (latitude: _lat, longitude: _lng);
  }

  void _actualizarUbicacion(double lat, double lng, {bool moverMapa = false}) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _latCtrl.text = lat.toStringAsFixed(6);
      _lngCtrl.text = lng.toStringAsFixed(6);
    });
    if (moverMapa) {
      _mapController.move(LatLng(lat, lng), 15.0);
    }
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
        _actualizarUbicacion(pos.latitude, pos.longitude, moverMapa: true);
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
          // Mapa Interactivo Real OpenStreetMap
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_lat, _lng),
                    initialZoom: 15.0,
                    onTap: (tapPosition, point) {
                      _actualizarUbicacion(point.latitude, point.longitude);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.barber_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_lat, _lng),
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Badge indicador táctil
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(210),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ColoresApp.primario),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Toca el mapa para mover marcador',
                          style: TipografiaApp.labelSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botón GPS Mi Ubicación Actual
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    heroTag: 'btn_gps_mapa',
                    backgroundColor: Colors.white,
                    foregroundColor: ColoresApp.primario,
                    onPressed:
                        _obteniendoUbicacion ? null : _usarUbicacionActual,
                    child: _obteniendoUbicacion
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),

          // Campos de Latitud y Longitud manuales + Botón Google Maps
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
                            _actualizarUbicacion(parsed, _lng, moverMapa: true);
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
                            _actualizarUbicacion(_lat, parsed, moverMapa: true);
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
