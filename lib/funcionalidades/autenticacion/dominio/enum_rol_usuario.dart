enum RolUsuario {
  cliente,
  barbero,
  admin,
  superadmin;

  static RolUsuario desdeTexto(String texto) {
    return RolUsuario.values.firstWhere(
      (valor) => valor.name == texto,
      orElse: () => RolUsuario.cliente,
    );
  }
}
