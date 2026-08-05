import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AddressSettingsScreen extends StatefulWidget {
  const AddressSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AddressSettingsScreen> createState() => _AddressSettingsScreenState();
}

class _AddressSettingsScreenState extends State<AddressSettingsScreen> {
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: 'Shri Ramdev Park CHS');
    _cityController = TextEditingController(text: 'Mumbai');
    _postalCodeController = TextEditingController(text: '400607');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('🏠 Address Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Your Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Street Address', _addressController, Icons.location_on),
                    const SizedBox(height: 12),
                    _buildTextField('City', _cityController, Icons.location_city),
                    const SizedBox(height: 12),
                    _buildTextField('Postal Code', _postalCodeController, Icons.mail),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Address updated successfully!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.saffron,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
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
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}
