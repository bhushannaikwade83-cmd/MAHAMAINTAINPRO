import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_theme.dart';
import 'visitor_details_screen.dart';

Widget _buildVisitorAvatar(Map visitor, {double size = 40}) {
  final photoBase64 = visitor['photoBase64'] as String?;
  if (photoBase64 != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(base64Decode(photoBase64), width: size, height: size, fit: BoxFit.cover),
    );
  }
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
  bool _isSaving = false;

  Future<List<dynamic>> _loadVisitors() async {
    final prefs = await SharedPreferences.getInstance();
    final visitors = prefs.getStringList('visitors') ?? [];
    return visitors.map((item) => jsonDecode(item)).toList();
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
      final prefs = await SharedPreferences.getInstance();
      final visitors = prefs.getStringList('visitors') ?? [];

      final newVisitor = jsonEncode({
        'name': _visitorNameController.text,
        'phone': _visitorPhoneController.text,
        'purpose': _visitorPurposeController.text,
        'timestamp': DateTime.now().toString(),
      });

      visitors.add(newVisitor);
      await prefs.setStringList('visitors', visitors);

      _visitorNameController.clear();
      _visitorPhoneController.clear();
      _visitorPurposeController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visitor added successfully!'),
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

  Future<void> _deleteVisitor(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final visitors = prefs.getStringList('visitors') ?? [];
    visitors.removeAt(index);
    await prefs.setStringList('visitors', visitors);
    setState(() {});
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
                    future: _loadVisitors(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allVisitors = snapshot.data ?? [];
                      final recentVisitors = allVisitors.reversed.take(5).toList();

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
                                  _buildVisitorAvatar(visitor),
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
                    future: _loadVisitors(),
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
                                  onDelete: _deleteVisitor,
                                ),
                              ),
                            ).then((_) => setState(() {})),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildVisitorAvatar(visitor, size: 48),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  visitor['name'] ?? 'Unknown',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => _deleteVisitor(index),
                                                child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              ),
                                            ],
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
