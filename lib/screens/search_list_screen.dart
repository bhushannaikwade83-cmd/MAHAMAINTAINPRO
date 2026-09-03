import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  final String? imagePath;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  _SearchEntry({
    required this.emoji,
    this.iconPath,
    this.imagePath,
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
  List<_SearchEntry> _allEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-services.php');
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['categories'] != null) {
          final categories = List<Map<String, dynamic>>.from(data['categories']);

          final entries = <_SearchEntry>[];
          for (final category in categories) {
            final categoryName = category['name'] as String? ?? '';
            final emoji = category['emoji'] as String? ?? '🔧';
            final imagePath = category['image_path'] as String?;
            final services = (category['services'] as List<dynamic>?)
                ?.map((s) => Map<String, dynamic>.from(s as Map))
                .toList() ?? [];

            entries.add(
              _SearchEntry(
                emoji: emoji,
                imagePath: imagePath,
                title: categoryName,
                subtitle: '',
                builder: (context) => ServiceCategoryScreen(
                  categoryName: categoryName,
                  categoryEmoji: emoji,
                  categoryImagePath: imagePath,
                  description: getCategoryDescription(categoryName),
                  services: services,
                ),
              ),
            );
          }

          if (mounted) {
            setState(() {
              _allEntries = entries;
              _allEntries.addAll([
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
              ]);
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.saffron),
            )
          : SafeArea(
              child: Column(
                children: [
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
                        const SizedBox(height: 8),
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
            if (entry.imagePath != null && entry.imagePath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://digitrixmedia.com/mahamaintainpro/assets/services/${entry.imagePath}',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Text(entry.emoji, style: const TextStyle(fontSize: 28)),
                ),
              )
            else if (entry.iconPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(entry.iconPath!, width: 48, height: 48, fit: BoxFit.cover),
              )
            else
              Text(entry.emoji, style: const TextStyle(fontSize: 28)),
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
