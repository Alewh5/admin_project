class AppRoles {
  AppRoles._();

  static const String root = 'ROOT';
  static const String owner = 'OWNER';
  static const String supervisor = 'SUPERVISOR';
  static const String agent = 'AGENT';

  static bool isRootOrOwner(String role) => role == root || role == owner;

  static bool isSupervisorOrHigher(String role) =>
      isRootOrOwner(role) || role == supervisor;

  static String label(String role) {
    switch (role) {
      case root:
        return 'Root';
      case owner:
        return 'Propietario';
      case supervisor:
        return 'Supervisor';
      case agent:
        return 'Agente';
      default:
        return role;
    }
  }
}
