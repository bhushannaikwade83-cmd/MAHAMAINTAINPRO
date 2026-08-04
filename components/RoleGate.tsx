'use client';

import { ReactNode } from 'react';
import { usePermission } from '@/hooks/usePermission';
import { Permission } from '@/types/common';

interface RoleGateProps {
  permission?: Permission;
  permissions?: Permission[];
  requireAll?: boolean;
  children: ReactNode;
  fallback?: ReactNode;
}

export function RoleGate({
  permission,
  permissions = [],
  requireAll = false,
  children,
  fallback = <div className="p-6 text-center text-gray-500">You don't have permission to view this</div>,
}: RoleGateProps) {
  const { can, canAll, canAny } = usePermission();

  const hasAccess = (() => {
    if (permission) {
      return can(permission);
    }
    if (permissions.length === 0) {
      return true;
    }
    return requireAll ? canAll(permissions) : canAny(permissions);
  })();

  if (!hasAccess) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}
