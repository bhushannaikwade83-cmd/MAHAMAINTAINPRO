import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';

class AnnouncementsScreen extends StatefulWidget {
  final bool isCommittee;

  const AnnouncementsScreen({this.isCommittee = false, Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  Future<int> _societyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('societyId') ?? 1;
  }

  Future<List<dynamic>> _loadAnnouncements() async {
    final societyId = await _societyId();
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get-society-notices.php?society_id=$societyId'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['notices'] as List).map((n) => {
                'id': n['id'],
                'title': n['title'],
                'description': n['description'],
                'timestamp': n['created_at'],
              }).toList();
        }
      }
    } catch (e) {
      // Silent fail - list just shows empty
    }
    return [];
  }

  Future<void> _addAnnouncement() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final societyId = await _societyId();
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/add-society-notice.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'society_id': societyId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? data['error'] ?? 'Failed to post notice');
      }

      _titleController.clear();
      _descriptionController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement posted successfully!'),
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

  Future<void> _deleteAnnouncement(int index) async {
    // Notices are now tracked server-side; deletion isn't exposed yet.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notice deletion is not available yet.')),
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
        title: const Text('📢 Announcements'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isCommittee) ...[
              const Text(
                'Post Announcement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Title', _titleController, Icons.title),
                      const SizedBox(height: 12),
                      _buildTextField(
                        'Description',
                        _descriptionController,
                        Icons.description,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _addAnnouncement,
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
                                'Post Announcement',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'All Announcements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Text(
                'Latest Announcements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Posted by your society admin',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
            ],
            FutureBuilder<List<dynamic>>(
              future: _loadAnnouncements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final announcements = snapshot.data ?? [];

                if (announcements.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: const [
                          Icon(Icons.announcement_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No announcements yet'),
                        ],
                      ),
                    ),
                  );
                }

                // Newest first
                final displayList = announcements.reversed.toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayList.length,
                  itemBuilder: (context, displayIndex) {
                    final announcement = displayList[displayIndex];
                    final storageIndex = announcements.length - 1 - displayIndex;
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
                                  child: Text(
                                    announcement['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (widget.isCommittee)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete announcement',
                                    onPressed: () => _deleteAnnouncement(storageIndex),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              announcement['description'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
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
