import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';

class ManageComplaintsScreen extends StatefulWidget {
  const ManageComplaintsScreen({Key? key}) : super(key: key);

  @override
  State<ManageComplaintsScreen> createState() => _ManageComplaintsScreenState();
}

class _ManageComplaintsScreenState extends State<ManageComplaintsScreen> {
  List<dynamic> _complaints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final societyId = prefs.getInt('societyId') ?? 1;

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get-society-complaints.php?society_id=$societyId'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() => _complaints = data['complaints']);
      }
    } catch (e) {
      // Silent fail - list just shows empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> complaint, String newStatus, {String? resolutionRemarks}) async {
    final prefs = await SharedPreferences.getInstance();
    final societyId = prefs.getInt('societyId') ?? 1;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/update-complaint-status.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'id': complaint['id'],
          'society_id': societyId,
          'status': newStatus,
          if (resolutionRemarks != null) 'resolution_remarks': resolutionRemarks,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to update status');
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showResolveDialog(Map<String, dynamic> complaint) async {
    final remarksController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Complaint'),
        content: TextField(
          controller: remarksController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What was done to fix this?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark Resolved')),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(complaint, 'resolved', resolutionRemarks: remarksController.text.trim());
    }
  }

  Future<List<dynamic>> _loadVendors() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get-active-vendors.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['vendors'];
    } catch (e) {
      // Silent fail - dialog just shows empty list
    }
    return [];
  }

  Future<void> _showAssignVendorDialog(Map<String, dynamic> complaint) async {
    final vendors = await _loadVendors();
    int? selectedVendorId = complaint['assigned_vendor_id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Technician / Vendor'),
          content: vendors.isEmpty
              ? const Text('No active vendors found in the system yet.')
              : DropdownButtonFormField<int>(
                  value: selectedVendorId,
                  decoration: const InputDecoration(labelText: 'Registered Vendor', border: OutlineInputBorder()),
                  items: vendors
                      .map<DropdownMenuItem<int>>((v) => DropdownMenuItem(
                            value: v['id'],
                            child: Text('${v['name']} (${v['phone'] ?? 'no phone'})'),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedVendorId = value),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: vendors.isEmpty ? null : () => Navigator.pop(context, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedVendorId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final societyId = prefs.getInt('societyId') ?? 1;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/assign-complaint-vendor.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'id': complaint['id'],
          'society_id': societyId,
          'vendor_id': selectedVendorId,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to assign vendor');
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.amber;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('📋 Manage Complaints'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _complaints.isEmpty
                  ? const Center(child: Text('No complaints yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _complaints.length,
                      itemBuilder: (context, index) {
                        final c = _complaints[index];
                        final status = c['status'] ?? 'open';
                        final createdAt = DateTime.tryParse(c['created_at'] ?? '');
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
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              color: _priorityColor(c['priority'] ?? 'medium'),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              c['category'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.replaceAll('_', ' ').toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _statusColor(status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(c['description'] ?? '', style: TextStyle(color: Colors.grey.shade700)),
                                if (c['photo_url'] != null) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      c['photo_url'],
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      cacheHeight: 200,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                                if (c['video_url'] != null) ...[
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => launchUrl(Uri.parse(c['video_url']), mode: LaunchMode.externalApplication),
                                    child: Row(
                                      children: [
                                        Icon(Icons.videocam, size: 16, color: AppTheme.saffron),
                                        const SizedBox(width: 4),
                                        Text('View attached video', style: TextStyle(color: AppTheme.saffron, fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                                if (c['assigned_vendor_name'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Assigned: ${c['assigned_vendor_name']}${c['assigned_vendor_phone'] != null ? ' (${c['assigned_vendor_phone']})' : ''}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                                if (c['reopened_count'] != null && c['reopened_count'] > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reopened ${c['reopened_count']} time(s)',
                                    style: const TextStyle(fontSize: 11, color: Colors.red),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                if (createdAt != null)
                                  Text(
                                    DateFormat('d MMM yyyy, h:mm a').format(createdAt),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    TextButton(
                                      onPressed: () => _showAssignVendorDialog(c),
                                      child: const Text('Assign Vendor'),
                                    ),
                                    if (status != 'in_progress' && status != 'resolved')
                                      TextButton(
                                        onPressed: () => _updateStatus(c, 'in_progress'),
                                        child: const Text('Mark In Progress'),
                                      ),
                                    if (status != 'resolved')
                                      TextButton(
                                        onPressed: () => _showResolveDialog(c),
                                        child: const Text('Mark Resolved'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
