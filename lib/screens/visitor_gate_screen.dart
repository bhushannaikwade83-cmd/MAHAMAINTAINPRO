import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_theme.dart';

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
      body: SingleChildScrollView(
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(visitor['name'] ?? ''),
                        subtitle: Text(visitor['phone'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteVisitor(index),
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
