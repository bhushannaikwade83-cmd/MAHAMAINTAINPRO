import { UserRole, Permission } from '@/types/common';

const rolePermissionsMap: Record<UserRole, Set<Permission>> = {
  [UserRole.SuperAdmin]: new Set([
    Permission.ManageUsers,
    Permission.ManageRoles,
    Permission.ViewAllLeads,
    Permission.ManageOwnLeads,
    Permission.AssignLeads,
    Permission.DeleteLead,
    Permission.ManageCustomers,
    Permission.ManageSociety,
    Permission.CreateServiceRequest,
    Permission.AssignTechnician,
    Permission.CompleteServiceRequest,
    Permission.ViewDashboardKpis,
    Permission.ViewFinancials,
  ]),
  [UserRole.Admin]: new Set([
    Permission.ViewAllLeads,
    Permission.ManageOwnLeads,
    Permission.AssignLeads,
    Permission.DeleteLead,
    Permission.ManageCustomers,
    Permission.ManageSociety,
    Permission.ManageUsers,
    Permission.CreateServiceRequest,
    Permission.AssignTechnician,
    Permission.CompleteServiceRequest,
    Permission.ViewDashboardKpis,
    Permission.ViewFinancials,
  ]),
  [UserRole.SalesManager]: new Set([
    Permission.ViewAllLeads,
    Permission.ManageOwnLeads,
    Permission.AssignLeads,
    Permission.ManageCustomers,
    Permission.ManageSociety,
    Permission.ViewDashboardKpis,
  ]),
  [UserRole.SalesExecutive]: new Set([
    Permission.ManageOwnLeads,
    Permission.ManageCustomers,
  ]),
  [UserRole.Technician]: new Set([
    Permission.CompleteServiceRequest,
  ]),
  [UserRole.Customer]: new Set([]),
};

export class PermissionService {
  static can(role: UserRole, permission: Permission): boolean {
    return rolePermissionsMap[role]?.has(permission) ?? false;
  }

  static permissionsFor(role: UserRole): Set<Permission> {
    return rolePermissionsMap[role] ?? new Set();
  }

  static getRoleLabel(role: UserRole): string {
    const labels: Record<UserRole, string> = {
      [UserRole.SuperAdmin]: 'Super Admin',
      [UserRole.Admin]: 'Admin',
      [UserRole.SalesManager]: 'Sales Manager',
      [UserRole.SalesExecutive]: 'Sales Executive',
      [UserRole.Technician]: 'Technician',
      [UserRole.Customer]: 'Customer',
    };
    return labels[role];
  }

  static getRoleColor(role: UserRole): string {
    const colors: Record<UserRole, string> = {
      [UserRole.SuperAdmin]: 'bg-purple-100 text-purple-800',
      [UserRole.Admin]: 'bg-red-100 text-red-800',
      [UserRole.SalesManager]: 'bg-blue-100 text-blue-800',
      [UserRole.SalesExecutive]: 'bg-green-100 text-green-800',
      [UserRole.Technician]: 'bg-yellow-100 text-yellow-800',
      [UserRole.Customer]: 'bg-gray-100 text-gray-800',
    };
    return colors[role];
  }
}
