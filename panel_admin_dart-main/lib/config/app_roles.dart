/// Constantes de roles de usuario del sistema.
/// Usar siempre estas constantes en lugar de strings literales.
class AppRoles {
  AppRoles._(); // No instanciable

  static const String root = 'ROOT';
  static const String owner = 'OWNER';
  static const String supervisor = 'SUPERVISOR';
  static const String agent = 'AGENT';

  /// ROOT o OWNER — acceso total al sistema
  static bool isRootOrOwner(String role) =>
      role == root || role == owner;

  /// SUPERVISOR, ROOT u OWNER — acceso a reportes y proyectos
  static bool isSupervisorOrHigher(String role) =>
      isRootOrOwner(role) || role == supervisor;

  /// Etiqueta legible del rol
  static String label(String role) {
    switch (role) {
      case root:        return 'Root';
      case owner:       return 'Propietario';
      case supervisor:  return 'Supervisor';
      case agent:       return 'Agente';
      default:          return role;
    }
  }
}
