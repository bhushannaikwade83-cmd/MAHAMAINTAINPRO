import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';

class SocietyInfoScreen extends StatefulWidget {
  final bool isCommittee;

  const SocietyInfoScreen({this.isCommittee = false, Key? key}) : super(key: key);

  @override
  State<SocietyInfoScreen> createState() => _SocietyInfoScreenState();
}

class _SocietyInfoScreenState extends State<SocietyInfoScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  DateTime? _registrationDate;

  int? _societyId;
  bool _loading = true;
  bool _isSaving = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final societyId = prefs.getInt('societyId') ?? 1;
    _societyId = societyId;

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get-society-details.php?id=$societyId'),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['society'] != null) {
        final s = data['society'];
        _nameController.text = s['name'] ?? '';
        _addressController.text = s['address'] ?? '';
        _cityController.text = s['city'] ?? '';
        _postalCodeController.text = s['postal_code'] ?? '';
        _registrationNumberController.text = s['registration_number'] ?? '';
        _contactPhoneController.text = s['contact_phone'] ?? '';
        _contactEmailController.text = s['contact_email'] ?? '';
        _registrationDate = DateTime.tryParse(s['registration_date'] ?? '');
      }
    } catch (e) {
      // Silent fail - form just stays empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRegistrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.saffron)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _registrationDate = picked);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Society name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/admin-update-society.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'id': _societyId,
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'postal_code': _postalCodeController.text.trim(),
          'registration_number': _registrationNumberController.text.trim(),
          if (_registrationDate != null)
            'registration_date': DateFormat('yyyy-MM-dd').format(_registrationDate!),
          'contact_phone': _contactPhoneController.text.trim(),
          'contact_email': _contactEmailController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? data['error'] ?? 'Failed to update society info');
      }

      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Society info updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _registrationNumberController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.isCommittee;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('🏠 Society Info'),
        elevation: 0,
        actions: [
          if (canEdit && !_loading)
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit),
              tooltip: _editing ? 'Cancel editing' : 'Edit society info',
              onPressed: () => setState(() => _editing = !_editing),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Basic Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _field('Society Name', _nameController, Icons.apartment, enabled: _editing),
                  const SizedBox(height: 12),
                  _field('Address', _addressController, Icons.location_on, enabled: _editing, maxLines: 2),
                  const SizedBox(height: 12),
                  _field('City', _cityController, Icons.location_city, enabled: _editing),
                  const SizedBox(height: 12),
                  _field('Pincode', _postalCodeController, Icons.pin, enabled: _editing, keyboardType: TextInputType.number),
                  const SizedBox(height: 24),

                  const Text('Registration Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'From the society\'s Co-operative Societies registration certificate',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  _field('Registration Number', _registrationNumberController, Icons.badge, enabled: _editing),
                  const SizedBox(height: 12),
                  Text('Registration Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _editing ? _pickRegistrationDate : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color: _editing ? null : Colors.grey.shade100,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: AppTheme.saffron, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _registrationDate != null
                                ? DateFormat('d MMM yyyy').format(_registrationDate!)
                                : 'Not set',
                            style: TextStyle(
                              fontSize: 14,
                              color: _registrationDate != null ? Colors.black87 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Contact Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _field('Contact Phone', _contactPhoneController, Icons.phone, enabled: _editing, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('Contact Email', _contactEmailController, Icons.email, enabled: _editing, keyboardType: TextInputType.emailAddress),

                  if (_editing) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
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
                          : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: !enabled,
            fillColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }
}
