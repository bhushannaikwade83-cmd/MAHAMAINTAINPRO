/// The six roles defined for Phase 1 of Maha Maintain Pro.
enum UserRole {
  superAdmin,
  admin,
  salesManager,
  salesExecutive,
  technician,
  customer;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.customer,
    );
  }

  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.salesManager:
        return 'Sales Manager';
      case UserRole.salesExecutive:
        return 'Sales Executive';
      case UserRole.technician:
        return 'Technician';
      case UserRole.customer:
        return 'Customer';
    }
  }
}

/// Fine-grained permissions checked throughout the app.
/// Keeping these as named booleans (rather than scattering role checks
/// through the UI) means Sprint 2+ features only ever call
/// `PermissionService.can(...)`, not `role == UserRole.admin`.
enum Permission {
  manageUsers,
  manageRoles,
  viewAllLeads,
  manageOwnLeads,
  assignLeads,
  deleteLead,
  manageCustomers,
  manageSociety,
  createServiceRequest,
  assignTechnician,
  completeServiceRequest,
  viewDashboardKpis,
  viewFinancials,
}
