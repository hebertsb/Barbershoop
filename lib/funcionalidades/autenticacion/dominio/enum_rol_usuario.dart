enum RolUsuario {
  superadmin,
  admin,
  barbero,
  secretaria,
  cliente;

  static RolUsuario desdeTexto(String texto) {
    return RolUsuario.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => RolUsuario.cliente,
    );
  }
}
