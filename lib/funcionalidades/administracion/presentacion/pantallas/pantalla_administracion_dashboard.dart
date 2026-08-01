import 'package:flutter/material.dart';

/// Dashboard de administración -- versión mínima reconstruida tras la
/// pérdida de datos del 2026-07-31 (ver FLUJO-RECUPERACION.md). La versión
/// original tenía tarjetas de ingresos/citas y un gráfico de tendencia
/// (`TarjetaGraficoTendencia`, ya recuperado intacto en
/// `presentacion/componentes/`) -- pendiente de re-conectar cuando
/// `RepositorioAdministracion` recupere `obtenerResumenIngresos`/
/// `obtenerTendenciaIngresos`.
class PantallaAdministracionDashboard extends StatelessWidget {
  const PantallaAdministracionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administración')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Dashboard en reconstrucción tras la pérdida de datos local '
            'del 31/07/2026. Usá el menú para acceder a cada sección '
            'mientras se restaura el panel de resumen.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
