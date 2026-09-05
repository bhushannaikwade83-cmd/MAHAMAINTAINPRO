import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'add_complaint_screen.dart';
import 'announcements_screen.dart';
import 'bills_maintenance_screen.dart';
import 'parking_management_screen.dart';
import 'tenant_management_screen.dart';
import 'visitor_gate_screen.dart';
import 'photo_detail_screen.dart';
import 'category_photos_screen.dart';

/// Society Tab Screen - shown to society members when they click the Society tab
/// Displays the Society Dashboard with Dashboard, Photos, and Notices tabs
class SocietyDashboardScreen extends StatefulWidget {
  final bool isCommittee;
  final VoidCallback? onRefresh;

  const SocietyDashboardScreen({
    this.isCommittee = false,
    this.onRefresh,
    Key? key,
  }) : super(key: key);

  @override
  State<SocietyDashboardScreen> createState() => _SocietyDashboardScreenState();
}

class _SocietyDashboardScreenState extends State<SocietyDashboardScreen> with WidgetsBindingObserver {
  int _selectedTab = 0;
  DateTime? _lastRefreshTime;

  // Member info from database
  String? _memberName;
  String? _societyName;
  String? _designation;
  int? _userId;
  int? _societyId;
  bool _loadingMemberInfo = true;

  late final List<String> tabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Add Committee tab only if user is committee member
    tabs = widget.isCommittee
      ? ['Dashboard', 'Photos', 'Notices', 'Committee']
      : ['Dashboard', 'Photos', 'Notices'];

    _fetchMemberInfo();
  }

  Future<void> _fetchMemberInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null || userId <= 0) {
        print('⚠️ No userId found');
        setState(() => _loadingMemberInfo = false);
        return;
      }

      _userId = userId;

      // Fetch member details
      final response = await http.get(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/check-society-member.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['exists'] == true) {
          final member = data['member'];
          setState(() {
            _memberName = member['secretary_name'] ?? 'Member';
            _societyId = member['society_id'];
            _designation = member['designation'] ?? 'Member';
          });

          // Fetch society name
          if (_societyId != null) {
            await _fetchSocietyName(_societyId!);
          }
        }
      }
    } catch (e) {
      print('Error fetching member info: $e');
    } finally {
      setState(() => _loadingMemberInfo = false);
    }
  }

  Future<void> _fetchSocietyName(int societyId) async {
    try {
      final response = await http.get(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/admin-get-societies.php'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final societies = data['societies'] as List;

          Map<String, dynamic>? society;
          for (var s in societies) {
            if (s['id'].toString() == societyId.toString()) {
              society = s;
              break;
            }
          }

          if (society != null) {
            final name = society['name'] ?? 'Unknown';
            final city = society['city'] ?? 'Unknown';
            setState(() {
              _societyName = '$name • $city';
            });
          }
        }
      }
    } catch (e) {
      // Silent fail - will show "Loading..." if error
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 SocietyDashboardScreen: App resumed - refreshing data');
      _refreshData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _refreshData() {
    print('🔄 Refreshing society dashboard data');
    // Reload custom categories and other data
    setState(() {
      _lastRefreshTime = DateTime.now();
    });
  }

  static const List<Map<String, dynamic>> _builtInPhotoCategories = [
    {'name': 'Ganesh Festival', 'emoji': '🎉', 'color': Color(0xFFE8F5E9)},
    {'name': 'Lift Repair Done', 'emoji': '🔧', 'color': Color(0xFFE3F2FD)},
    {'name': 'Pool Cleaning', 'emoji': '🏊', 'color': Color(0xFFE0F7FA)},
    {'name': 'Society Day Celebration', 'emoji': '🎊', 'color': Color(0xFFF3E5F5)},
    {'name': 'Gate Motor Replaced', 'emoji': '🚪', 'color': Color(0xFFFFF8E1)},
    {'name': 'Garden Beautification', 'emoji': '🌳', 'color': Color(0xFFF9FBE7)},
  ];

  static const List<Color> _categoryColorPalette = [
    Color(0xFFFFE5E5),
    Color(0xFFE5F5FF),
    Color(0xFFF5E5FF),
    Color(0xFFE5FFE5),
    Color(0xFFFFF5E5),
    Color(0xFFE5FFF9),
  ];

  Future<List<Map<String, dynamic>>> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('photo_categories') ?? [];
    return saved.map((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return {
        'name': decoded['name'] as String,
        'emoji': decoded['emoji'] as String,
        'color': Color(decoded['color'] as int),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _loadAllPhotoCategories() async {
    final custom = await _loadCustomCategories();
    return [..._builtInPhotoCategories, ...custom];
  }

  Future<Map<String, dynamic>?> _addCustomCategory(String name, String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('photo_categories') ?? [];

    final allNames = [
      ..._builtInPhotoCategories.map((c) => c['name'] as String),
      ...saved.map((item) => (jsonDecode(item) as Map<String, dynamic>)['name'] as String),
    ];
    if (allNames.any((existing) => existing.toLowerCase() == name.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A category with that name already exists.')),
        );
      }
      return null;
    }

    final color = _categoryColorPalette[saved.length % _categoryColorPalette.length];
    saved.add(jsonEncode({'name': name, 'emoji': emoji, 'color': color.value}));
    await prefs.setStringList('photo_categories', saved);

    return {'name': name, 'emoji': emoji, 'color': color};
  }

  Future<String?> _showCreateCategoryDialog() async {
    final emojiController = TextEditingController();
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emoji', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: emojiController,
              autofocus: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              decoration: InputDecoration(
                hintText: '🎈',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Category Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Diwali Celebration',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22)),
            onPressed: () {
              if (emojiController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add an emoji and a name.')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return null;

    final created = await _addCustomCategory(nameController.text.trim(), emojiController.text.trim());
    return created?['name'] as String?;
  }

  Future<List<dynamic>> _loadRecentComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final complaints = prefs.getStringList('complaints') ?? [];
    return complaints.reversed.take(3).map((item) => jsonDecode(item)).toList();
  }

  Future<List<dynamic>> _loadRecentAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final announcements = prefs.getStringList('announcements') ?? [];
    return announcements.reversed.take(2).map((item) => jsonDecode(item)).toList();
  }

  String _formatTicketDate(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.tryParse(timestamp);
    if (date == null) return '';
    return DateFormat('d MMM').format(date);
  }

  Future<List<dynamic>> _loadSharedPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final photos = prefs.getStringList('shared_photos') ?? [];
    return photos.reversed.map((item) => jsonDecode(item)).toList();
  }

  Future<void> _pickAndSharePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Share a Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFFE67E22)),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFE67E22)),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e')),
        );
      }
      return;
    }
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo is larger than 10 MB. Please choose a smaller one.')),
        );
      }
      return;
    }

    if (!mounted) return;
    final categories = await _loadAllPhotoCategories();
    if (!mounted) return;

    const addNewSentinel = '__add_new_category__';
    final selection = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('What is this photo for?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            for (final cat in categories)
              ListTile(
                leading: Text(cat['emoji'] as String, style: const TextStyle(fontSize: 22)),
                title: Text(cat['name'] as String),
                onTap: () => Navigator.pop(context, cat['name'] as String),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Color(0xFFE67E22)),
              title: const Text('Add New Category', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE67E22))),
              onTap: () => Navigator.pop(context, addNewSentinel),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selection == null) return; // cancelled

    String category = selection;
    if (selection == addNewSentinel) {
      final created = await _showCreateCategoryDialog();
      if (created == null || !mounted) return; // cancelled creating
      category = created;
    }

    final prefs = await SharedPreferences.getInstance();
    final photos = prefs.getStringList('shared_photos') ?? [];
    photos.add(jsonEncode({
      'category': category,
      'imageBase64': base64Encode(bytes),
      'timestamp': DateTime.now().toString(),
    }));
    await prefs.setStringList('shared_photos', photos);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo shared!'), backgroundColor: Colors.green),
      );
      setState(() {});
    }
  }

  void _openComplaints() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddComplaintScreen()),
    ).then((_) => setState(() {}));
  }

  void _openNoticesTab() {
    setState(() => _selectedTab = 2);
  }

  @override
  Widget build(BuildContext context) {
    // Auto-refresh every 10 seconds when tab is visible
    final now = DateTime.now();
    if (_lastRefreshTime == null || now.difference(_lastRefreshTime!).inSeconds > 10) {
      _lastRefreshTime = now;
      print('🔄 Auto-refresh (SocietyDashboardScreen - 10s elapsed)');
      Future.microtask(_refreshData);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with orange gradient
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back icon & Refresh button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (Navigator.canPop(context))
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      else
                        const SizedBox(width: 24),
                      // Refresh button - triggers parent refresh
                      GestureDetector(
                        onTap: widget.onRefresh ?? _fetchMemberInfo,
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    _memberName ?? 'Society Member',
                    style: TextStyle(
                      fontSize: isSmall ? 24 : 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Society info
                  Text(
                    _societyName ?? 'Loading...',
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Designation Badge
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _designation ?? 'Member',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: List.generate(
                  tabs.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: Column(
                        children: [
                          Text(
                            tabs[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == index ? FontWeight.w700 : FontWeight.w500,
                              color: _selectedTab == index ? Colors.black87 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedTab == index)
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE67E22),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          else
                            Container(
                              height: 3,
                              color: Colors.transparent,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content based on selected tab
            if (_selectedTab == 0) ...[
              // Dashboard Tab Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildMenuCard(
                      '🚪',
                      'Visitor Gate',
                      'Manage visitor entries',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VisitorGateScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      '🚗',
                      'Parking Management',
                      'Request guest parking',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ParkingManagementScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      '👥',
                      'Tenant Management',
                      'Register tenants',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TenantManagementScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      '📋',
                      'Bills & Maintenance',
                      widget.isCommittee ? 'Upload & manage maintenance bills' : 'View maintenance bills',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BillsMaintenanceScreen(isCommittee: widget.isCommittee)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      '📢',
                      'Announcements',
                      widget.isCommittee ? 'Post & manage society notices' : 'View society notices',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AnnouncementsScreen(isCommittee: widget.isCommittee)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Add Complaint Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddComplaintScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5CC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE67E22), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('📝', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Complaint',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Report an issue to management',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Color(0xFFE67E22), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Complaints & Tickets Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Complaints & Tickets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: _openComplaints,
                      child: Text(
                        'View All →',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFE67E22),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<List<dynamic>>(
                  future: _loadRecentComplaints(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final complaints = snapshot.data ?? [];

                    if (complaints.isEmpty) {
                      return GestureDetector(
                        onTap: _openComplaints,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'No complaints raised yet',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: complaints.map((complaint) {
                        final isOpen = complaint['status'] == 'Open';
                        return _buildTicketCard(
                          complaint['title'] ?? '',
                          '${complaint['ticketNumber'] ?? ''} • ${_formatTicketDate(complaint['timestamp'])}',
                          isOpen ? 'Open' : '${complaint['status'] ?? ''} ✓',
                          isOpen ? Colors.amber : Colors.green,
                          onTap: _openComplaints,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Society Notices Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📣 Society Notices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: _openNoticesTab,
                      child: Text(
                        'See All →',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFE67E22),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<List<dynamic>>(
                  future: _loadRecentAnnouncements(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final notices = snapshot.data ?? [];

                    if (notices.isEmpty) {
                      return GestureDetector(
                        onTap: _openNoticesTab,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'No notices posted yet',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: notices.map((notice) {
                        return _buildNoticeCard(
                          notice['title'] ?? '',
                          notice['description'] ?? '',
                          _formatTicketDate(notice['timestamp']),
                          const Color(0xFFE67E22),
                          onTap: _openNoticesTab,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ] else if (_selectedTab == 1) ...[
              // Photos Tab Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: _pickAndSharePhoto,
                  child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('📷', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share a Photo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Upload from gallery or take new • Max 10 MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Photo Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait([_loadSharedPhotos(), _loadAllPhotoCategories()]),
                  builder: (context, snapshot) {
                    final sharedPhotos = (snapshot.data?[0] as List<dynamic>?) ?? [];
                    final allCategories = (snapshot.data?[1] as List<Map<String, dynamic>>?) ?? _builtInPhotoCategories;

                    final categoryTiles = allCategories.map<Widget>((cat) {
                      final categoryName = cat['name'] as String;
                      final categoryPhotos = sharedPhotos
                          .where((photo) => photo['category'] == categoryName)
                          .toList();

                      return _buildPhotoCard(
                        categoryName,
                        emoji: cat['emoji'] as String,
                        bgColor: cat['color'] as Color,
                        imageBytes: categoryPhotos.isNotEmpty
                            ? base64Decode(categoryPhotos.first['imageBase64'] as String)
                            : null,
                        subtitle: categoryPhotos.isNotEmpty ? '${categoryPhotos.length} photo${categoryPhotos.length > 1 ? 's' : ''}' : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryPhotosScreen(
                              categoryName: categoryName,
                              emoji: cat['emoji'] as String,
                              bgColor: cat['color'] as Color,
                              photos: categoryPhotos,
                            ),
                          ),
                        ),
                      );
                    }).toList();

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                      children: categoryTiles,
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ] else if (_selectedTab == 2) ...[
              // Notices Tab Content
              // Show Post Notice button only if committee member
              if (widget.isCommittee) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C4A9E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('📌', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Post a Notice',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Attach image or PDF',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Notices List with categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildCategoryNotice('URGENT NOTICE', '🔧', 'Water Tank Maintenance', 'Water supply will be off from 10 AM to 2 PM for tank cleaning.', Colors.orange, 'Today'),
                    const SizedBox(height: 12),
                    _buildCategoryNotice('EVENT', '🎉', 'AGM Meeting — 22 June 2026', 'Annual General Meeting at 7 PM in the clubhouse. All residents requested to attend...', const Color(0xFF1ABC9C), '2 days ago'),
                    const SizedBox(height: 12),
                    _buildCategoryNotice('AMENITY UPDATE', '🏊', 'Pool Maintenance Schedule', 'Pool will be closed on weekends for maintenance.', Colors.amber, '5 days ago'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ] else if (widget.isCommittee && _selectedTab == 3) ...[
              // Committee Management Tab
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '🏛️ Committee Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Coming Soon Sections
                    _buildCommitteeSection('👥', 'Members', 'Manage society members', Colors.blue),
                    const SizedBox(height: 12),
                    _buildCommitteeSection('✅', 'Approvals', 'Pending member & bill approvals', Colors.green),
                    const SizedBox(height: 12),
                    _buildCommitteeSection('📊', 'Statistics', 'Society stats & analytics', Colors.orange),
                    const SizedBox(height: 12),
                    _buildCommitteeSection('📈', 'Reports', 'Generate & export reports', Colors.purple),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(String title, String subtitle, String status, Color statusColor, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildNoticeCard(String title, String description, String footer, Color accentColor, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (footer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                footer,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCategoryNotice(String category, String emoji, String title, String description, Color categoryColor, String timeAgo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: categoryColor, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: categoryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(
    String title, {
    String? emoji,
    Color? bgColor,
    Uint8List? imageBytes,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoDetailScreen(
                    title: title,
                    imageBytes: imageBytes,
                    emoji: emoji,
                    bgColor: bgColor,
                    subtitle: subtitle,
                  ),
                ),
              ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes, fit: BoxFit.cover),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                        ),
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji ?? '🖼️', style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuCard(String emoji, String title, String subtitle, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 22),
        ],
      ),
      ),
    );
  }

  Widget _buildCommitteeSection(String emoji, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: color, size: 20),
        ],
      ),
    );
  }
}
