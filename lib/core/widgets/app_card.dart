import 'package:flutter/material.dart';
import '../../features/role_access/models/user_role.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Small colored pill showing a user's role — used on user lists,
/// lead assignment dropdowns, and profile headers.
class RoleBadge extends StatelessWidget {
  final UserRole role;
  const RoleBadge({super.key, required this.role});

  Color _colorFor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return AppColors.roleSuperAdmin;
      case UserRole.admin:
        return AppColors.roleAdmin;
      case UserRole.salesManager:
        return AppColors.roleSalesManager;
      case UserRole.salesExecutive:
        return AppColors.roleSalesExecutive;
      case UserRole.technician:
        return AppColors.roleTechnician;
      case UserRole.customer:
        return AppColors.roleCustomer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
