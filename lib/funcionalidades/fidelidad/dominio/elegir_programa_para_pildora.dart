import 'modelo_progreso_fidelidad.dart';

/// Elige qué programa mostrar en la píldora flotante cuando el cliente
/// participa en más de uno: prioriza el que ya se puede reclamar (para que
/// el cliente no se pierda un premio disponible); si ninguno, el de mayor
/// progreso relativo (progresoActual / metaCitas), para mostrar siempre el
/// más cerca de completarse.
ModeloProgresoFidelidad? elegirProgramaParaPildora(
  List<ModeloProgresoFidelidad> programas,
) {
  if (programas.isEmpty) return null;

  final reclamables = programas.where((p) => p.puedeReclamar).toList();
  if (reclamables.isNotEmpty) {
    reclamables.sort((a, b) => b.progresoActual.compareTo(a.progresoActual));
    return reclamables.first;
  }

  final ordenados = List<ModeloProgresoFidelidad>.from(programas)
    ..sort((a, b) {
      final ratioA = a.progresoActual / a.metaCitas;
      final ratioB = b.progresoActual / b.metaCitas;
      return ratioB.compareTo(ratioA);
    });
  return ordenados.first;
}