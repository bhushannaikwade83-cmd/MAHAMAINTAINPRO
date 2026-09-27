import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';

class AddComplaintScreen extends StatefulWidget {
  const AddComplaintScreen({Key? key}) : super(key: key);

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Maintenance';
  String _selectedPriority = 'medium';
  Uint8List? _photoBytes;
  File? _videoFile;
  bool _isSaving = false;

  final List<Map<String, String>> priorities = [
    {'value': 'low', 'label': 'Low'},
    {'value': 'medium', 'label': 'Medium'},
    {'value': 'high', 'label': 'High'},
  ];

  final List<String> categories = [
    'Maintenance',
    'Noise',
    'Parking',
    'Water',
    'Electricity',
    'Safety',
    'Other'
  ];

  Future<List<dynamic>> _loadComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get-society-complaints.php?user_id=$userId'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['complaints'] as List).map((c) => {
                'id': c['id'],
                'ticketNumber': 'CMP-${c['id']}',
                'title': c['category'] ?? '',
                'description': c['description'] ?? '',
                'category': c['category'] ?? '',
                'priority': c['priority'] ?? 'medium',
                'photoUrl': c['photo_url'],
                'videoUrl': c['video_url'],
                'status': c['status'] ?? 'open',
                'resolutionRemarks': c['resolution_remarks'],
                'assignedVendorName': c['assigned_vendor_name'],
                'customerConfirmed': c['customer_confirmed'] == 1 || c['customer_confirmed'] == true,
                'timestamp': c['created_at'],
              }).toList();
        }
      }
    } catch (e) {
      // Silent fail - list just shows empty
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
              child: Text('Add a Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Future<String?> _uploadPhoto(Uint8List bytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/upload-complaint-photo.php'),
      );
      request.headers.addAll(SupabaseAuthRepository.staticAuthHeaders);
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'complaint.jpg'));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['url'];
      }
    } catch (e) {
      // Non-fatal - complaint still gets submitted without the photo
    }
    return null;
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null) return;
      setState(() => _videoFile = File(picked.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick video: $e')),
        );
      }
    }
  }

  Future<String?> _uploadVideo(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/upload-complaint-video.php'),
      );
      final authToken = SupabaseAuthRepository.currentToken;
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.files.add(await http.MultipartFile.fromPath('video', file.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['url'];
      }
    } catch (e) {
      // Non-fatal - complaint still gets submitted without the video
    }
    return null;
  }

  Future<void> _confirmResolution(int complaintId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/confirm-complaint-resolution.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({'id': complaintId}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to confirm');
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for confirming!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reopenComplaint(int complaintId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/reopen-complaint.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({'id': complaintId}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to reopen');
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint reopened')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final societyId = prefs.getInt('societyId') ?? 1;

      if (userId == null) {
        throw Exception('You must be logged in to submit a complaint');
      }

      String? photoUrl;
      if (_photoBytes != null) {
        photoUrl = await _uploadPhoto(_photoBytes!);
      }
      String? videoUrl;
      if (_videoFile != null) {
        videoUrl = await _uploadVideo(_videoFile!);
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/add-society-complaint.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'society_id': societyId,
          'category': _selectedCategory,
          'priority': _selectedPriority,
          'description': '${_titleController.text}: ${_descriptionController.text}',
          if (photoUrl != null) 'photo_url': photoUrl,
          if (videoUrl != null) 'video_url': videoUrl,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to submit complaint');
      }

      final ticketNumber = 'CMP-${data['complaint_id']}';

      _titleController.clear();
      _descriptionController.clear();
      _photoBytes = null;
      _videoFile = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint submitted! Ticket: $ticketNumber'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
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

  Future<void> _deleteComplaint(int index) async {
    // Complaints are now tracked server-side by management; residents can't
    // delete a submitted ticket, only management can resolve it.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitted complaints are tracked by management and cannot be deleted.')),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('📝 Add Complaint'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report an Issue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Priority',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      items: priorities
                          .map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPriority = value);
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Title', _titleController, Icons.title),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Description',
                      _descriptionController,
                      Icons.description,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Photo (optional)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isSaving ? null : _pickPhoto,
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _photoBytes != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(_photoBytes!, fit: BoxFit.cover),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _photoBytes = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 32, color: AppTheme.saffron),
                                  const SizedBox(height: 6),
                                  Text('Tap to add a photo', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Video (optional)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isSaving ? null : _pickVideo,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _videoFile != null ? Icons.check_circle : Icons.videocam_outlined,
                              color: _videoFile != null ? Colors.green : AppTheme.saffron,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _videoFile != null ? 'Video attached (${_videoFile!.path.split('/').last})' : 'Tap to attach a short video (max 60s)',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_videoFile != null)
                              GestureDetector(
                                onTap: () => setState(() => _videoFile = null),
                                child: const Icon(Icons.close, size: 18, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submitComplaint,
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
                              'Submit Complaint',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Complaints',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _loadComplaints(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final complaints = snapshot.data ?? [];

                if (complaints.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: const [
                          Icon(Icons.note_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No complaints submitted yet'),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    final status = complaint['status'] ?? 'open';
                    final statusColor = status == 'resolved'
                        ? Colors.green
                        : status == 'in_progress'
                            ? Colors.amber
                            : Colors.orange;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        complaint['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        complaint['ticketNumber'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              complaint['description'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (complaint['photoUrl'] != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  complaint['photoUrl'],
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  cacheHeight: 200,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                ),
                              ),
                            ],
                            if (complaint['assignedVendorName'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Assigned to: ${complaint['assignedVendorName']}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                              ),
                            ],
                            if (status == 'resolved' && complaint['resolutionRemarks'] != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Resolution: ${complaint['resolutionRemarks']}',
                                  style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Chip(
                                      label: Text(complaint['category'] ?? ''),
                                      backgroundColor: Colors.grey.shade200,
                                      labelStyle: const TextStyle(fontSize: 12),
                                    ),
                                    Chip(
                                      label: Text((complaint['priority'] ?? 'medium').toUpperCase()),
                                      backgroundColor: Colors.blue.shade50,
                                      labelStyle: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                if (status == 'resolved' && complaint['customerConfirmed'] != true)
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () => _reopenComplaint(complaint['id']),
                                        child: const Text('Reopen'),
                                      ),
                                      TextButton(
                                        onPressed: () => _confirmResolution(complaint['id']),
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
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
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: maxLines > 1 ? null : Icon(icon),
          ),
        ),
      ],
    );
  }
}
