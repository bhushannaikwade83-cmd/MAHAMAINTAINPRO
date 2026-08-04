import { useAuth } from './useAuth';
import { PermissionService } from '@/lib/permissions/permission-service';
import { Permission, UserRole } from '@/types/common';

export function usePermission() {
  const { user } = useAuth();

  const can = (permission: Permission): boolean => {
    if (!user) return false;
    return PermissionService.can(user.role, permission);
  };

  const canAny = (permissions: Permission[]): boolean => {
    return permissions.some((permission) => can(permission));
  };

  const canAll = (permissions: Permission[]): boolean => {
    return permissions.every((permission) => can(permission));
  };

  const isRole = (role: UserRole): boolean => {
    return user?.role === role;
  };

  const isAnyRole = (roles: UserRole[]): boolean => {
    return roles.includes(user?.role as UserRole);
  };

  return {
    can,
    canAny,
    canAll,
    isRole,
    isAnyRole,
    userRole: user?.role,
  };
}
