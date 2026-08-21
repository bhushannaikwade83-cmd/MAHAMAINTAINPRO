import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import '../config/app_theme.dart';
import 'location_picker_screen.dart';
import 'add_address_screen.dart';

class AddressSettingsScreen extends StatefulWidget {
  const AddressSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AddressSettingsScreen> createState() => _AddressSettingsScreenState();
}

class _AddressSettingsScreenState extends State<AddressSettingsScreen> {
  late List<Map<String, String>> _addresses;

  @override
  void initState() {
    super.initState();
    _addresses = [];
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('userPhone');

      if (phoneNumber == null) {
        _showFallbackAddress(prefs);
        return;
      }

      // Fetch addresses from addresses table
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-addresses.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['addresses'] != null && (data['addresses'] as List).isNotEmpty) {
          final loadedAddresses = (data['addresses'] as List).map((addr) => {
            'id': addr['id']?.toString() ?? '',
            'type': addr['address_type']?.toString() ?? 'Home',
            'address': addr['full_address']?.toString() ?? 'Address not available',
            'phone': phoneNumber,
          }).toList();

          if (mounted) {
            setState(() {
              _addresses = loadedAddresses.cast<Map<String, String>>();
            });
          }
          debugPrint('✅ Addresses loaded from database: ${_addresses.length} found');
          return;
        }
      }

      // Fallback if no addresses in database
      _showFallbackAddress(prefs);
    } catch (e) {
      debugPrint('❌ Error loading addresses: $e');
      final prefs = await SharedPreferences.getInstance();
      _showFallbackAddress(prefs);
    }
  }

  void _showFallbackAddress(SharedPreferences prefs) {
    // No fallback - show empty list if no addresses in database
    setState(() {
      _addresses = [];
    });
  }

  Future<void> _editAddress(Map<String, String> address) async {
    try {
      final locationResult = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
      );

      if (locationResult != null && mounted) {
        // Navigate to AddAddressScreen with edit mode
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAddressScreen(
                initialLatitude: locationResult['latitude'].toString(),
                initialLongitude: locationResult['longitude'].toString(),
                initialAddress: locationResult['address'] ?? '',
                addressId: address['id'], // Pass address ID for update
              ),
            ),
          ).then((_) {
            if (mounted) {
              setState(() => _loadAddresses());
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Edit error: $e');
    }
  }

  Future<void> _deleteAddress(Map<String, String> address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('userPhone');

      if (phoneNumber == null) return;

      // Call delete API
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/delete-address.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address_id': address['id'] ?? '',
          'phone_number': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Address deleted successfully');
          // Reload addresses after deletion
          await _loadAddresses();
        }
      }
    } catch (e) {
      debugPrint('❌ Delete error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ADDRESSES',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            // Addresses List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAVED ADDRESSES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._addresses.map((address) => _buildAddressCard(address)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Add New Address Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () async {
                  final locationResult = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
                  );

                  if (locationResult != null && mounted) {
                    // Location picker returns: latitude, longitude, address
                    // Navigate to AddAddressScreen with this data
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddAddressScreen(
                            initialLatitude: locationResult['latitude'].toString(),
                            initialLongitude: locationResult['longitude'].toString(),
                            initialAddress: locationResult['address'] ?? '',
                          ),
                        ),
                      ).then((_) {
                        if (mounted) {
                          setState(() => _loadAddresses());
                        }
                      });
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.saffron, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ADD NEW ADDRESS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.saffron,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, String> address) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.saffron.withOpacity(0.08),
            AppTheme.saffron.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.saffron.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.saffron.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Badge and Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.saffron.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.saffron,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.saffron.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        address['type'] ?? 'Home',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.saffron,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address['address'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Divider
          Divider(height: 1, color: AppTheme.saffron.withOpacity(0.1)),
          const SizedBox(height: 14),
          // Phone Number
          Row(
            children: [
              Icon(
                Icons.phone_rounded,
                color: AppTheme.saffron,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Phone: ${address['phone'] ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButtonNew('EDIT', () => _editAddress(address)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _deleteAddress(address),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'DELETE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButtonNew('SHARE', () {}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonNew(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.saffron.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.saffron.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.saffron,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
