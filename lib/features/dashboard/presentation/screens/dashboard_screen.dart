import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../role_access/models/user_role.dart';
import '../../../role_access/services/permission_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(currentAppUserProvider).valueOrNull;
    final role = appUser?.role ?? UserRole.customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              ref.read(currentAppUserProvider.notifier).clear();
            },
          ),
        ],
      ),
      drawer: _DashboardDrawer(role: role, userName: appUser?.name ?? ''),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome back${appUser != null ? ', ${appUser.name}' : ''}',
                style: AppTextStyles.headingLarge),
            const SizedBox(height: 4),
            Text(role.label, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            if (PermissionService.can(role, Permission.viewDashboardKpis))
              _KpiGrid(role: role)
            else
              const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Your dashboard content will appear here.'),
                ),
              ),
            const SizedBox(height: 24),
            Text('Quick actions', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            _QuickActions(role: role),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final UserRole role;
  const _KpiGrid({required this.role});

  @override
  Widget build(BuildContext context) {
    // Sprint 4 will wire these to live Firestore aggregates.
    // Placeholder zero-state values keep the layout final now.
    final kpis = <_KpiData>[
      _KpiData('Open Leads', '0', Icons.leaderboard_outlined, AppColors.stageNew),
      _KpiData('Active Customers', '0', Icons.groups_outlined, AppColors.secondary),
      _KpiData('Pending Service Requests', '0', Icons.build_outlined, AppColors.warning),
      _KpiData('Completed This Month', '0', Icons.check_circle_outline, AppColors.success),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: kpis.map((k) => _KpiCard(data: k)).toList(),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _KpiData(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.color),
          const Spacer(),
          Text(data.value, style: AppTextStyles.displayLarge),
          Text(data.label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final UserRole role;
  const _QuickActions({required this.role});

  @override
  Widget build(BuildContext context) {
    final actions = <(String, IconData, String, Permission?)>[
      ('Leads', Icons.leaderboard_outlined, RouteNames.leads, Permission.manageOwnLeads),
      ('Customers', Icons.groups_outlined, RouteNames.customers, Permission.manageCustomers),
      ('Societies', Icons.apartment_outlined, RouteNames.societies, Permission.manageSociety),
      ('Service Requests', Icons.build_outlined, RouteNames.serviceRequests, null),
      ('User Management', Icons.admin_panel_settings_outlined, RouteNames.userManagement,
          Permission.manageUsers),
    ];

    final visible = actions
        .where((a) => a.$4 == null || PermissionService.can(role, a.$4!))
        .toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: visible
          .map((a) => ActionChip(
                avatar: Icon(a.$2, size: 18, color: AppColors.primary),
                label: Text(a.$1),
                onPressed: () => context.push(a.$3),
              ))
          .toList(),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  final UserRole role;
  final String userName;
  const _DashboardDrawer({required this.role, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(userName, style: AppTextStyles.headingSmall),
                  Text(role.label, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Divider(height: 1),
            _drawerTile(context, Icons.dashboard_outlined, 'Dashboard', RouteNames.dashboard),
            if (PermissionService.can(role, Permission.manageOwnLeads))
              _drawerTile(context, Icons.leaderboard_outlined, 'Leads', RouteNames.leads),
            if (PermissionService.can(role, Permission.manageCustomers))
              _drawerTile(context, Icons.groups_outlined, 'Customers', RouteNames.customers),
            if (PermissionService.can(role, Permission.manageSociety))
              _drawerTile(context, Icons.apartment_outlined, 'Societies', RouteNames.societies),
            _drawerTile(
                context, Icons.build_outlined, 'Service Requests', RouteNames.serviceRequests),
            if (PermissionService.can(role, Permission.manageUsers))
              _drawerTile(context, Icons.admin_panel_settings_outlined, 'User Management',
                  RouteNames.userManagement),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        context.push(route);
      },
    );
  }
}
