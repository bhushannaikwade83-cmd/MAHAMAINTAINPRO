import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../data/service_catalog.dart';
import 'add_complaint_screen.dart';
import 'announcements_screen.dart';
import 'bills_maintenance_screen.dart';
import 'parking_management_screen.dart';
import 'service_category_screen.dart';
import 'tenant_management_screen.dart';
import 'visitor_gate_screen.dart';

class _SearchEntry {
  final String emoji;
  final String? iconPath;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  _SearchEntry({
    required this.emoji,
    this.iconPath,
    required this.title,
    required this.subtitle,
    required this.builder,
  });
}

class SearchListScreen extends StatefulWidget {
  final bool isCommittee;

  const SearchListScreen({this.isCommittee = false, Key? key}) : super(key: key);

  @override
  State<SearchListScreen> createState() => _SearchListScreenState();
}

class _SearchListScreenState extends State<SearchListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  late final List<_SearchEntry> _allEntries = [
    for (final service in personalServices)
      _SearchEntry(
        emoji: service['emoji'] as String,
        iconPath: getCategoryIcon(service['name'] as String),
        title: service['name'] as String,
        subtitle: getCategoryDescription(service['name'] as String),
        builder: (context) => ServiceCategoryScreen(
          categoryName: service['name'] as String,
          categoryEmoji: service['emoji'] as String,
          categoryIconPath: getCategoryIcon(service['name'] as String),
          description: getCategoryDescription(service['name'] as String),
          services: getServicesForCategory(service['name'] as String, service['emoji'] as String),
        ),
      ),
    _SearchEntry(
      emoji: '🛵',
      title: 'Visitor Gate',
      subtitle: 'Register and manage society visitors',
      builder: (context) => const VisitorGateScreen(),
    ),
    _SearchEntry(
      emoji: '🚗',
      title: 'Parking Management',
      subtitle: 'Request and track guest parking',
      builder: (context) => const ParkingManagementScreen(),
    ),
    _SearchEntry(
      emoji: '👥',
      title: 'Tenant Management',
      subtitle: 'Register and manage society tenants',
      builder: (context) => const TenantManagementScreen(),
    ),
    _SearchEntry(
      emoji: '📋',
      title: 'Bills & Maintenance',
      subtitle: 'View and add maintenance bills',
      builder: (context) => BillsMaintenanceScreen(isCommittee: widget.isCommittee),
    ),
    _SearchEntry(
      emoji: '📢',
      title: 'Announcements',
      subtitle: 'Society announcements and notices',
      builder: (context) => AnnouncementsScreen(isCommittee: widget.isCommittee),
    ),
    _SearchEntry(
      emoji: '✍️',
      title: 'Add Complaint',
      subtitle: 'Raise a complaint with your society',
      builder: (context) => const AddComplaintScreen(),
    ),
  ];

  List<_SearchEntry> get _filteredEntries {
    if (_query.trim().isEmpty) return _allEntries;
    final query = _query.trim().toLowerCase();
    return _allEntries
        .where((entry) =>
            entry.title.toLowerCase().contains(query) ||
            entry.subtitle.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;
    final results = _filteredEntries;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Orange Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.saffron, AppTheme.saffronDark],
                ),
              ),
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                      Text(
                        'Search',
                        style: TextStyle(
                          fontSize: isSmall ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find services, society features & more',
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    autofocus: false,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search services, society',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close, color: Colors.grey.shade400),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Results Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.saffron,
              child: Text(
                _query.trim().isEmpty ? 'All Services' : 'Results for "${_query.trim()}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Results List
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No results found for "${_query.trim()}"',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = results[index];
                        return _buildResultItem(context, entry);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, _SearchEntry entry) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: entry.builder),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            entry.iconPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(entry.iconPath!, width: 36, height: 36, fit: BoxFit.cover),
                  )
                : Text(entry.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
