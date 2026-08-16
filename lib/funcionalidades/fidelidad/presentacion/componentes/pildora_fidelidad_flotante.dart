import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/elegir_programa_para_pildora.dart';
import '../controladores/controlador_progreso_fidelidad.dart';
import 'detalle_fidelidad_modal.dart';

class PildoraFidelidadFlotante extends ConsumerStatefulWidget {
  const PildoraFidelidadFlotante({super.key});

  @override
  ConsumerState<PildoraFidelidadFlotante> createState() =>
      _PildoraFidelidadFlotanteState();
}

class _PildoraFidelidadFlotanteState
    extends ConsumerState<PildoraFidelidadFlotante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rebote;
  Timer? _timerRefresco;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _rebote = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _timerRefresco = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      ref.invalidate(controladorProgresoFidelidadProvider);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timerRefresco?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorProgresoFidelidadProvider);
    final programas = estado.value ?? const [];
    final elegido = elegirProgramaParaPildora(programas);

    if (elegido == null) return const SizedBox.shrink();

    final avisar = elegido.estaPorCumplirMeta || elegido.puedeReclamar;

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 14, bottom: 90),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const DetalleFidelidadModal(),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, avisar ? _rebote.value : 0),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFFF2CA50),
                  width: avisar ? 2 : 1.5,
                ),
                boxShadow: avisar
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFF2CA50,
                          ).withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.loyalty,
                    size: 16,
                    color: Color(0xFFF2CA50),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${elegido.progresoActual}/${elegido.metaCitas}',
                    style: const TextStyle(
                      color: Color(0xFFF2CA50),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
