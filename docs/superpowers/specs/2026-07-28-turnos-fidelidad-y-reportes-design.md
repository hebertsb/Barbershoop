# Especificación de Diseño: Turnos, Fidelidad, Ranking, Inventario y Reportes

> Fecha: 2026-07-28
> Estado: Aprobado

## Visión General
Especificación técnica para la gestión de turnos presenciales de mostrador (walk-in), programas de tarjetas de fidelidad digitales, inventario de insumos para barberos, ranking mensual de barberos y reportes ejecutivos.

## Componentes y Arquitectura
1. **Turnos & Walk-in:** `ModeloTurno`, `ModeloClienteWalkin`, `PantallaGestionTurnos`, `DialogoNuevoTurno`.
2. **Fidelidad:** `ModeloProgramaFidelidad`, `ModeloProgresoFidelidad`, `PantallaGestionProgramasFidelidad`.
3. **Inventario:** `ModeloInsumo`, `ModeloReporteInsumo`, `PantallaAlmacen`, `PantallaReportarInsumo`.
4. **Ranking & Reseñas:** `ModeloBarberoRanking`, `ModeloResena`, `PantallaGestionRankingBarberos`, `PantallaMisResenas`.
5. **Reportes:** `ModeloResumenIngresos`, `ModeloPuntoTendencia`, `PantallaReportesIngresos`.
