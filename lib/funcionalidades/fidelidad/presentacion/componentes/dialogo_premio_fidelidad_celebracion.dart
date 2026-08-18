import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../nucleo/configuracion/tipografia_app.dart';
import '../../../promociones/dominio/modelo_promocion.dart';
import '../../../reservas/presentacion/controladores/controlador_reserva.dart';

class DialogoPremioFidelidadCelebracion extends ConsumerWidget {
  const DialogoPremioFidelidadCelebracion({
    super.key,
    required this.promocion,
    required this.nombrePrograma,
  });

  final ModeloPromocion promocion;
  final String nombrePrograma;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF2CA50), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF2CA50).withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF2CA50).withValues(alpha: 0.2),
                  ),
                ),
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFF2CA50),
                  size: 54,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '¡FELICIDADES! 🏆🎉',
              textAlign: TextAlign.center,
              style: TipografiaApp.headlineSm.copyWith(
                color: const Color(0xFFF2CA50),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completaste la meta en "$nombrePrograma"',
              textAlign: TextAlign.center,
              style: TipografiaApp.bodySm.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF2CA50).withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.confirmation_number_rounded,
                        color: Color(0xFFF2CA50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TICKET DE RECOMPENSA 100% GRATIS',
                        style: TipografiaApp.labelSm.copyWith(
                          color: const Color(0xFFF2CA50),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promocion.titulo.isNotEmpty
                        ? promocion.titulo
                        : 'Corte de Cabello / Servicio Gratis',
                    textAlign: TextAlign.center,
                    style: TipografiaApp.headlineSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Premio listo para canjear al agendar tu cita.',
                    textAlign: TextAlign.center,
                    style: TipografiaApp.bodySm.copyWith(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(controladorReservaProvider.notifier)
                      .iniciarReservaConPromocion(promocion);
                  context.push('/reservas/sucursal');
                },
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.black,
                ),
                label: const Text(
                  'AGENDAR CITA GRATIS AHORA',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF2CA50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Guardar en mi billetera para después',
                style: TipografiaApp.labelSm.copyWith(
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
