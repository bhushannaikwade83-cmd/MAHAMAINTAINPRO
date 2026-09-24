import '../models/user_role.dart';

/// Single source of truth for "who can do what".
/// Add new permissions to [UserRole] enum's Permission list and wire them
/// here — never inline a role check in a screen.
class PermissionService {
  PermissionService._();

  static final Map<UserRole, Set<Permission>> _matrix = {
    UserRole.superAdmin: {
      Permission.manageUsers,
      Permission.manageRoles,
      Permission.viewAllLeads,
      Permission.manageOwnLeads,
      Permission.assignLeads,
      Permission.deleteLead,
      Permission.manageCustomers,
      Permission.manageSociety,
      Permission.createServiceRequest,
      Permission.assignTechnician,
      Permission.completeServiceRequest,
      Permission.viewDashboardKpis,
      Permission.viewFinancials,
    },
    UserRole.admin: {
      Permission.manageUsers,
      Permission.viewAllLeads,
      Permission.manageOwnLeads,
      Permission.assignLeads,
      Permission.deleteLead,
      Permission.manageCustomers,
      Permission.manageSociety,
      Permission.createServiceRequest,
      Permission.assignTechnician,
      Permission.completeServiceRequest,
      Permission.viewDashboardKpis,
      Permission.viewFinancials,
    },
    UserRole.salesManager: {
      Permission.viewAllLeads,
      Permission.manageOwnLeads,
      Permission.assignLeads,
      Permission.manageCustomers,
      Permission.manageSociety,
      Permission.viewDashboardKpis,
    },
    UserRole.salesExecutive: {
      Permission.manageOwnLeads,
      Permission.manageCustomers,
    },
    UserRole.technician: {
      Permission.completeServiceRequest,
    },
    UserRole.customer: {},
  };

  static bool can(UserRole role, Permission permission) {
    return _matrix[role]?.contains(permission) ?? false;
  }

  static Set<Permission> permissionsFor(UserRole role) => _matrix[role] ?? {};
}
