import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../config/app_theme.dart';

class TenantManagementScreen extends StatefulWidget {
  const TenantManagementScreen({Key? key}) : super(key: key);

  @override
  State<TenantManagementScreen> createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends State<TenantManagementScreen> {
  final _tenantNameController = TextEditingController();
  final _flatNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _agreementValidTill;
  bool _isSaving = false;

  Future<void> _pickAgreementValidTill() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _agreementValidTill ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.saffron)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _agreementValidTill = picked);
    }
  }

  Future<List<dynamic>> _loadTenants() async {
    final prefs = await SharedPreferences.getInstance();
    final tenants = prefs.getStringList('tenants') ?? [];
    return tenants.map((item) => jsonDecode(item)).toList();
  }

  Future<void> _addTenant() async {
    if (_tenantNameController.text.isEmpty ||
        _flatNumberController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }
    if (_agreementValidTill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the agreement valid till date!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final tenants = prefs.getStringList('tenants') ?? [];

      final newTenant = jsonEncode({
        'name': _tenantNameController.text,
        'flatNumber': _flatNumberController.text,
        'phone': _phoneController.text,
        'agreementValidTill': _agreementValidTill!.toIso8601String(),
        'timestamp': DateTime.now().toString(),
      });

      tenants.add(newTenant);
      await prefs.setStringList('tenants', tenants);

      _tenantNameController.clear();
      _flatNumberController.clear();
      _phoneController.clear();
      setState(() => _agreementValidTill = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tenant registered successfully!'),
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

  Future<void> _deleteTenant(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final tenants = prefs.getStringList('tenants') ?? [];
    tenants.removeAt(index);
    await prefs.setStringList('tenants', tenants);
    setState(() {});
  }

  @override
  void dispose() {
    _tenantNameController.dispose();
    _flatNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('👥 Tenant Management'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Register Tenant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Tenant Name', _tenantNameController, Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField('Flat Number', _flatNumberController, Icons.home, hintText: 'A-101, B-205'),
                    const SizedBox(height: 12),
                    _buildTextField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    Text(
                      'Agreement Valid Till',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isSaving ? null : _pickAgreementValidTill,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, color: AppTheme.saffron, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              _agreementValidTill != null
                                  ? DateFormat('d MMM yyyy').format(_agreementValidTill!)
                                  : 'Select date',
                              style: TextStyle(
                                fontSize: 14,
                                color: _agreementValidTill != null ? Colors.black87 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _addTenant,
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
                              'Register Tenant',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Registered Tenants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _loadTenants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tenants = snapshot.data ?? [];

                if (tenants.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: const [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No tenants registered yet'),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tenants.length,
                  itemBuilder: (context, index) {
                    final tenant = tenants[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tenant['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _deleteTenant(index),
                                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Flat: ${tenant['flatNumber'] ?? ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${tenant['phone'] ?? ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (tenant['agreementValidTill'] != null) ...[
                              const SizedBox(height: 4),
                              Builder(builder: (context) {
                                final validTill = DateTime.tryParse(tenant['agreementValidTill']);
                                final expired = validTill != null && validTill.isBefore(DateTime.now());
                                return Text(
                                  validTill != null
                                      ? 'Agreement Valid Till: ${DateFormat('d MMM yyyy').format(validTill)}${expired ? ' (Expired)' : ''}'
                                      : 'Agreement Valid Till: N/A',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: expired ? Colors.red : Colors.grey,
                                    fontWeight: expired ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                            ],
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
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
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
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}
