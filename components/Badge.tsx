import { LeadStage, UserRole, LeadStageConfig } from '@/types/common';
import { PermissionService } from '@/lib/permissions/permission-service';

interface BadgeProps {
  variant?: 'stage' | 'role' | 'default';
  value: LeadStage | UserRole | string;
  className?: string;
}

export function Badge({ variant = 'default', value, className = '' }: BadgeProps) {
  let colorClass = 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200';

  if (variant === 'stage' && Object.values(LeadStage).includes(value as LeadStage)) {
    colorClass = LeadStageConfig[value as LeadStage].color;
  } else if (variant === 'role' && Object.values(UserRole).includes(value as UserRole)) {
    colorClass = PermissionService.getRoleColor(value as UserRole);
  }

  const label =
    variant === 'stage' && Object.values(LeadStage).includes(value as LeadStage)
      ? LeadStageConfig[value as LeadStage].label
      : variant === 'role' && Object.values(UserRole).includes(value as UserRole)
        ? PermissionService.getRoleLabel(value as UserRole)
        : value;

  return <span className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${colorClass} ${className}`}>{label}</span>;
}
