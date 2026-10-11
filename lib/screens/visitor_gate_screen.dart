import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../config/app_theme.dart';
import 'visitor_details_screen.dart';
import 'photo_viewer_screen.dart';

Widget _buildVisitorAvatar(Map visitor, {double size = 40}) {
  // Try photo_url from API - load via CORS proxy
  final photoUrl = visitor['photo_url'] as String?;
  if (photoUrl != null && photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
    // Extract filename from URL
    final filename = photoUrl.split('/').last;
    // Load via CORS proxy
    final proxyUrl = 'https://digitrixmedia.com/mahamaintainpro/api/serve-photo.php?file=$filename';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        proxyUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('⚠️ Photo load failed via proxy - Error: $error');
          return _buildDefaultAvatar(size);
        },
      ),
    );
  }

  // Fallback to photoBase64 from local storage
  final photoBase64 = visitor['photoBase64'] as String?;
  if (photoBase64 != null && photoBase64.isNotEmpty) {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(base64Decode(photoBase64), width: size, height: size, fit: BoxFit.cover),
      );
    } catch (e) {
      return _buildDefaultAvatar(size);
    }
  }

  return _buildDefaultAvatar(size);
}

Widget _buildDefaultAvatar(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.person_outline, color: Colors.grey),
  );
}

Widget _buildTappableAvatar(BuildContext context, Map visitor, {double size = 40}) {
  final photoUrl = visitor['photo_url'] as String?;
  final visitorName = visitor['name'] as String? ?? 'Visitor';

  final avatar = _buildVisitorAvatar(visitor, size: size);

  if (photoUrl != null && photoUrl.isNotEmpty && photoUrl.startsWith('http')) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoViewerScreen(
              photoUrl: photoUrl,
              visitorName: visitorName,
            ),
          ),
        );
      },
      child: avatar,
    );
  }

  return avatar;
}

Widget? _buildStatusBadge(Map visitor) {
  final status = visitor['status'] as String?;
  if (status == null || status == 'pending') return null;
  final isApproved = status == 'Approved';
  final color = isApproved ? Colors.green : Colors.red;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      isApproved ? 'Approved ✓' : 'Denied ✗',
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class VisitorGateScreen extends StatefulWidget {
  const VisitorGateScreen({Key? key}) : super(key: key);

  @override
  State<VisitorGateScreen> createState() => _VisitorGateScreenState();
}

class _VisitorGateScreenState extends State<VisitorGateScreen> {
  final _visitorNameController = TextEditingController();
  final _visitorPhoneController = TextEditingController();
  final _visitorPurposeController = TextEditingController();
  Uint8List? _photoBytes;
  bool _isSaving = false;
  static const String API_BASE_URL = 'https://digitrixmedia.com/mahamaintainpro/api';

  Future<List<dynamic>> _loadRecentVisitors() async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/get-visitors.php?status=pending&limit=5'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['visitors'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('Recent visitors API error: $e');
    }
    return [];
  }

  Future<List<dynamic>> _loadRegisteredVisitors() async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/get-visitors.php?status=approved'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['visitors'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('Registered visitors API error: $e');
    }
    return [];
  }

  Future<void> _pickPhoto() async {
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
              child: Text('Capture Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppTheme.saffron),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.saffron),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _photoBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera/gallery: $e')),
        );
      }
    }
  }

  Future<void> _addVisitor() async {
    if (_visitorNameController.text.isEmpty ||
        _visitorPhoneController.text.isEmpty ||
        _visitorPurposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? photoBase64;
      if (_photoBytes != null) {
        photoBase64 = 'data:image/jpeg;base64,' + base64Encode(_photoBytes!);
      }

      final payload = {
        'name': _visitorNameController.text,
        'phone': _visitorPhoneController.text,
        'purpose': _visitorPurposeController.text,
        'photoBase64': photoBase64,
      };

      debugPrint('📤 Sending visitor to API: ${payload['name']}');

      final response = await http.post(
        Uri.parse('$API_BASE_URL/save-visitor.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60));

      debugPrint('📡 API Response Status: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Also save to local SharedPreferences for offline access
        final prefs = await SharedPreferences.getInstance();
        final visitors = prefs.getStringList('visitors') ?? [];

        final newVisitor = jsonEncode({
          'name': _visitorNameController.text,
          'phone': _visitorPhoneController.text,
          'purpose': _visitorPurposeController.text,
          'photoBase64': photoBase64,
          'timestamp': DateTime.now().toString(),
        });

        visitors.add(newVisitor);
        await prefs.setStringList('visitors', visitors);

        _visitorNameController.clear();
        _visitorPhoneController.clear();
        _visitorPurposeController.clear();
        _photoBytes = null;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visitor registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to register visitor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _visitorNameController.dispose();
    _visitorPhoneController.dispose();
    _visitorPurposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('🚪 Visitor Gate'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Register Visitor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo Section
                          if (_photoBytes != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Photo',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(_photoBytes!, width: double.infinity, height: 200, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _photoBytes = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Visitor Photo',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickPhoto,
                                  child: Container(
                                    width: double.infinity,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300, width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.photo_camera, size: 40, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to capture photo',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          _buildTextField('Visitor Name', _visitorNameController, Icons.person),
                          const SizedBox(height: 12),
                          _buildTextField('Phone Number', _visitorPhoneController, Icons.phone, keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _buildTextField('Purpose of Visit', _visitorPurposeController, Icons.edit),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _addVisitor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.saffron,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Register Visitor',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Visitors (Last 5)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visitors who came to see you',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<dynamic>>(
                    future: _loadRecentVisitors(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final recentVisitors = snapshot.data ?? [];

                      if (recentVisitors.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: const [
                                Icon(Icons.people_outline, size: 40, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No visitors yet'),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentVisitors.length,
                        itemBuilder: (context, index) {
                          final visitor = recentVisitors[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  _buildTappableAvatar(context, visitor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          visitor['name'] ?? 'Unknown',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          visitor['flatNo'] != null
                                              ? '${visitor['purpose'] ?? 'N/A'} • Flat ${visitor['flatNo']}'
                                              : (visitor['purpose'] ?? 'N/A'),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (visitor['guardName'] != null)
                                          Text(
                                            'Logged by ${visitor['guardName']} • ${visitor['gate'] ?? ''}',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (_buildStatusBadge(visitor) != null) _buildStatusBadge(visitor)!,
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Registered Visitors',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<dynamic>>(
                    future: _loadRegisteredVisitors(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final visitors = snapshot.data ?? [];

                      if (visitors.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: const [
                                Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No visitors registered yet'),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visitors.length,
                        itemBuilder: (context, index) {
                          final visitor = visitors[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VisitorDetailsScreen(
                                  visitor: visitor,
                                  index: index,
                                  onDelete: (_) {},
                                ),
                              ),
                            ),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTappableAvatar(context, visitor, size: 48),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            visitor['name'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          if (visitor['flatNo'] != null)
                                            Text(
                                              'Flat: ${visitor['flatNo']}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          else
                                            Text(
                                              'Phone: ${visitor['phone'] ?? 'N/A'}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Purpose: ${visitor['purpose'] ?? 'N/A'}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (_buildStatusBadge(visitor) != null) ...[
                                            const SizedBox(height: 6),
                                            _buildStatusBadge(visitor)!,
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}
