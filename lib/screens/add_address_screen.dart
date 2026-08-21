import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import '../config/app_theme.dart';
import 'location_picker_screen.dart';

class AddAddressScreen extends StatefulWidget {
  final String? initialLatitude;
  final String? initialLongitude;
  final String? initialAddress;
  final String? addressId; // For editing existing address

  const AddAddressScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.addressId,
  }) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> with SingleTickerProviderStateMixin {
  // Maharashtra Pincode Database
  static const Map<String, Map<String, String>> pincodeDatabase = {
    // Thane
    '400601': {'name': 'Thane', 'district': 'Thane', 'taluka': 'Thane', 'city': 'Thane', 'state': 'Maharashtra'},
    '400602': {'name': 'Thane City', 'district': 'Thane', 'taluka': 'Thane', 'city': 'Thane', 'state': 'Maharashtra'},
    '400603': {'name': 'Kashimira', 'district': 'Thane', 'taluka': 'Thane', 'city': 'Thane', 'state': 'Maharashtra'},
    '400604': {'name': 'Naupada', 'district': 'Thane', 'taluka': 'Thane', 'city': 'Thane', 'state': 'Maharashtra'},
    '400605': {'name': 'Kolsewadi', 'district': 'Thane', 'taluka': 'Thane', 'city': 'Thane', 'state': 'Maharashtra'},
    '400606': {'name': 'Shilphata', 'district': 'Thane', 'taluka': 'Thane', 'city': 'Thane', 'state': 'Maharashtra'},
    '400607': {'name': 'Ulhasnagar', 'district': 'Thane', 'taluka': 'Thane', 'city': 'Thane', 'state': 'Maharashtra'},
    '400608': {'name': 'Kalyan', 'district': 'Thane', 'taluka': 'Kalyan', 'city': 'Kalyan', 'state': 'Maharashtra'},
    '400609': {'name': 'Murbad', 'district': 'Thane', 'taluka': 'Murbad', 'city': 'Thane', 'state': 'Maharashtra'},
    '421201': {'name': 'Neral', 'district': 'Thane', 'taluka': 'Neral', 'city': 'Thane', 'state': 'Maharashtra'},

    // Navi Mumbai
    '400703': {'name': 'Belapur', 'district': 'Raigad', 'taluka': 'Panvel', 'city': 'Navi Mumbai', 'state': 'Maharashtra'},
    '400704': {'name': 'Nerul', 'district': 'Raigad', 'taluka': 'Panvel', 'city': 'Navi Mumbai', 'state': 'Maharashtra'},
    '400705': {'name': 'Vashi', 'district': 'Raigad', 'taluka': 'Panvel', 'city': 'Navi Mumbai', 'state': 'Maharashtra'},
    '400706': {'name': 'Seawoods', 'district': 'Raigad', 'taluka': 'Panvel', 'city': 'Navi Mumbai', 'state': 'Maharashtra'},
    '400707': {'name': 'Kharghar', 'district': 'Raigad', 'taluka': 'Panvel', 'city': 'Navi Mumbai', 'state': 'Maharashtra'},
    '400708': {'name': 'Taloja', 'district': 'Raigad', 'taluka': 'Panvel', 'city': 'Navi Mumbai', 'state': 'Maharashtra'},
    '400709': {'name': 'New Panvel', 'district': 'Raigad', 'taluka': 'Panvel', 'city': 'Navi Mumbai', 'state': 'Maharashtra'},
    '410205': {'name': 'Kopar Khairane', 'district': 'Raigad', 'taluka': 'Panvel', 'city': 'Navi Mumbai', 'state': 'Maharashtra'},

    // South Mumbai
    '400001': {'name': 'Fort', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
    '400002': {'name': 'Colaba', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
    '400003': {'name': 'Ballard Estate', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
    '400004': {'name': 'Kala Ghoda', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
    '400005': {'name': 'Kalachowki', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
    '400006': {'name': 'Girgaum', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
    '400007': {'name': 'Khetwadi', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
    '400008': {'name': 'Bhuleshwar', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
    '400009': {'name': 'Dhobi Talao', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
    '400010': {'name': 'Marine Lines', 'district': 'Mumbai', 'taluka': 'Mumbai', 'city': 'Mumbai', 'state': 'Maharashtra'},
  };

  late TextEditingController _buildingController;
  late TextEditingController _buildingNameController;
  late TextEditingController _streetController;
  late TextEditingController _pincodeController;
  late TextEditingController _labelController;
  late TextEditingController _instructionsController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _latitude;
  String? _longitude;
  String _locationType = 'House';
  bool _useAccountDetails = true;
  bool _isSaving = false;
  bool _isFetchingPincode = false;
  String _headerAddress = 'Loading address...';
  String _userName = '';
  String _userPhone = '';
  String _areaName = '';
  String _cityName = '';
  String _taluka = '';
  String _district = '';
  String _state = '';
  String _pincode = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Load initial values
    _buildingController = TextEditingController();
    _buildingNameController = TextEditingController();
    _streetController = TextEditingController();
    _pincodeController = TextEditingController();
    _labelController = TextEditingController();
    _instructionsController = TextEditingController();

    // Use initial values from location picker if provided
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _latitude = widget.initialLatitude;
      _longitude = widget.initialLongitude;
      if (widget.initialAddress != null) {
        _pincodeController.text = widget.initialAddress!;
        _parseAddressDetails(widget.initialAddress!);
      }
    }

    _loadCurrentLocation();

    // Load address details if editing
    if (widget.addressId != null) {
      _loadAddressForEditing();
    }
  }

  Future<void> _loadAddressForEditing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('userPhone');

      if (phoneNumber == null) return;

      // Fetch all addresses and find the one to edit
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-addresses.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['addresses'] != null) {
          // Find the address to edit
          final address = (data['addresses'] as List).firstWhere(
            (a) => a['id'].toString() == widget.addressId,
            orElse: () => null,
          );

          if (address != null && mounted) {
            // Load individual fields (not full_address to avoid duplication)
            _buildingController.text = address['building']?.toString() ?? '';
            _buildingNameController.text = address['building_name']?.toString() ?? '';
            _streetController.text = address['street']?.toString() ?? '';
            _pincodeController.text = address['pincode']?.toString() ?? '';
            _labelController.text = address['label']?.toString() ?? '';
            _instructionsController.text = address['delivery_instructions']?.toString() ?? '';
            _locationType = address['address_type']?.toString() ?? 'House';

            setState(() {});
            debugPrint('✅ Address loaded for editing');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading address for editing: $e');
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _latitude = prefs.getString('userLatitude');
      _longitude = prefs.getString('userLongitude');
      _userName = prefs.getString('userName') ?? '';
      _userPhone = prefs.getString('userPhone') ?? '';
      final phoneNumber = prefs.getString('userPhone');

      debugPrint('📍 Current Location - Lat: $_latitude, Long: $_longitude');

      // Fetch address from database
      if (phoneNumber != null) {
        final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/check-user.php');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone_number': phoneNumber}),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          debugPrint('📡 API Response: $data');
          if (data['exists'] == true && data['address'] != null) {
            _headerAddress = data['address'];
            _parseAddressDetails(data['address']);

            // Fetch lat/long from database
            _latitude = data['latitude']?.toString() ?? '';
            _longitude = data['longitude']?.toString() ?? '';

            debugPrint('📍 DB Latitude: $_latitude, Longitude: $_longitude');
          }
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading location: $e');
    }
  }

  void _parseAddressDetails(String address) {
    final parts = address.split(',').map((s) => s.trim()).toList();
    if (parts.isNotEmpty) {
      _areaName = parts.isNotEmpty ? parts[0] : '';
      _cityName = parts.length > 1 ? parts[1] : '';
      _taluka = parts.length > 2 ? parts[2] : '';
      _district = parts.length > 3 ? parts[3] : '';
      _state = parts.length > 4 ? parts[4] : '';
      _pincode = parts.length > 5 ? parts[5] : '';
    }
  }

  Future<void> _openLocationPicker() async {
    final initialLocation = _latitude != null && _latitude!.isNotEmpty && _longitude != null && _longitude!.isNotEmpty
        ? LatLng(double.parse(_latitude!), double.parse(_longitude!))
        : null;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: initialLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'].toString();
        _longitude = result['longitude'].toString();
        _pincodeController.text = result['address'] ?? '';
        _parseAddressDetails(result['address'] ?? '');
      });

      debugPrint('📍 Location: Lat=$_latitude, Long=$_longitude');
    }
  }

  Future<void> _fetchPincodeDetails() async {
    final pincode = _pincodeController.text.trim();

    debugPrint('🔍 Pincode entered: $pincode');

    if (pincode.isEmpty || pincode.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(pincode)) {
      debugPrint('❌ Invalid pincode format');
      return;
    }

    setState(() => _isFetchingPincode = true);

    try {
      // Try external API first
      final url = Uri.parse('https://api.postalpincode.in/pincode/$pincode');
      debugPrint('📡 Fetching from API: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      debugPrint('📊 Response status: ${response.statusCode}');
      debugPrint('📝 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        debugPrint('📋 API Data: $data');

        if (data is List && data.isNotEmpty) {
          final result = data[0];

          if (result['Status'] == 'Success' && result['PostOffice'] != null) {
            final postoffices = result['PostOffice'];

            if (postoffices is List && postoffices.isNotEmpty) {
              final po = postoffices[0];

              if (!mounted) return;
              setState(() {
                _areaName = po['Name'] ?? '';
                _cityName = po['District'] ?? '';
                _taluka = po['Block'] ?? '';
                _district = po['District'] ?? '';
                _state = po['State'] ?? '';
                _pincode = pincode;
              });

              debugPrint('✅ Success! Area=$_areaName, Taluka=$_taluka, State=$_state');
              return;
            }
          } else {
            debugPrint('❌ API Error: ${result['Status']} - ${result['Message']}');
          }
        }
      }

      // Fallback to local database
      if (pincodeDatabase.containsKey(pincode)) {
        final data = pincodeDatabase[pincode]!;

        if (!mounted) return;
        setState(() {
          _areaName = data['name'] ?? '';
          _cityName = data['city'] ?? '';
          _taluka = data['taluka'] ?? '';
          _district = data['district'] ?? '';
          _state = data['state'] ?? '';
          _pincode = pincode;
        });

        debugPrint('✅ Local DB Pincode Details: Area=$_areaName, City=$_cityName, State=$_state');
      } else {
        debugPrint('❌ Pincode not found: $pincode');
      }
    } catch (e) {
      debugPrint('❌ Fetch error: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingPincode = false);
      }
    }
  }

  Future<void> _saveAddress() async {
    // Validate mandatory fields
    String? errorMessage;

    if (_buildingController.text.trim().isEmpty) {
      errorMessage = 'Building / Floor is mandatory *';
    } else if (_pincodeController.text.trim().isEmpty) {
      errorMessage = 'Pincode is mandatory *';
    } else if (_labelController.text.trim().isEmpty) {
      errorMessage = 'Save address as is mandatory *';
    }

    if (errorMessage != null) {
      debugPrint('❌ Validation error: $errorMessage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isSaving = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('userPhone');
      final userName = prefs.getString('userName') ?? '';

      if (phoneNumber == null || userName.isEmpty) {
        throw Exception('User data not found');
      }

      // Combine address details - clean and trim each field
      final addressParts = <String>[];

      // Trim and clean user-entered fields (remove extra commas)
      final building = _buildingController.text.trim().replaceAll(RegExp(r',+'), '').trim();
      final buildingName = _buildingNameController.text.trim().replaceAll(RegExp(r',+'), '').trim();
      final street = _streetController.text.trim().replaceAll(RegExp(r',\s*,+'), ',').trim(); // Replace multiple commas with single

      if (building.isNotEmpty) {
        addressParts.add(building);
      }
      if (buildingName.isNotEmpty && buildingName != building) {
        addressParts.add(buildingName);
      }
      if (street.isNotEmpty && street != building && street != buildingName) {
        addressParts.add(street);
      }

      // Add pincode-fetched fields
      if (_areaName.isNotEmpty) {
        addressParts.add(_areaName.trim());
      }
      if (_cityName.isNotEmpty) {
        addressParts.add(_cityName.trim());
      }
      if (_taluka.isNotEmpty) {
        addressParts.add(_taluka.trim());
      }
      if (_district.isNotEmpty) {
        addressParts.add(_district.trim());
      }
      if (_state.isNotEmpty) {
        addressParts.add(_state.trim());
      }

      // Pincode at the end
      final pincode = _pincodeController.text.trim();
      if (pincode.isNotEmpty) {
        addressParts.add(pincode);
      }

      final fullAddress = addressParts.join(', ');

      // Determine if this is create or update
      final isUpdate = widget.addressId != null;
      final endpoint = isUpdate ? 'update-address.php' : 'save-address.php';
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/$endpoint');

      final requestBody = {
        'phone_number': phoneNumber,
        'address_type': _locationType,
        'building': _buildingController.text,
        'building_name': _buildingNameController.text,
        'street': _streetController.text,
        'pincode': _pincodeController.text,
        'area': _areaName,
        'city': _cityName,
        'taluka': _taluka,
        'district': _district,
        'state': _state,
        'latitude': _latitude != null ? double.tryParse(_latitude!) : 0,
        'longitude': _longitude != null ? double.tryParse(_longitude!) : 0,
        'label': _labelController.text,
        'delivery_instructions': _instructionsController.text,
        'full_address': fullAddress,
      };

      // Add address_id if updating
      if (isUpdate) {
        requestBody['address_id'] = widget.addressId;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Save locally
          await prefs.setString('user_address', fullAddress);
          debugPrint('✅ Address saved successfully! ID: ${data['address_id']}');

          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to save');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Save address error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _buildingNameController.dispose();
    _streetController.dispose();
    _pincodeController.dispose();
    _labelController.dispose();
    _instructionsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header with selected address
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                bottom: 14,
                left: 16,
                right: 16,
              ),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_pincodeController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: AppTheme.saffron, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Location',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _pincodeController.text,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _openLocationPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.saffron.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.saffron.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.saffron,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // Form Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Receiver Details
                  _buildSection('Receiver Details', [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.saffron,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Use my account details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_userName, $_userPhone',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  // Location Details
                  _buildSection('Location Details', [
                    // Selected Address (Read-only) - from location picker
                    if (_latitude != null && _latitude!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Address (from map)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _pincodeController.text.isEmpty ? 'Loading address...' : _pincodeController.text,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Location type buttons
                    Row(
                      children: ['House', 'Office', 'Other'].map((type) {
                        final isSelected = _locationType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _locationType = type),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.white,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    type == 'House'
                                        ? Icons.home
                                        : type == 'Office'
                                            ? Icons.business
                                            : Icons.location_on,
                                    color: isSelected ? Colors.white : Colors.grey.shade600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Building / Floor (Mandatory)
                    _buildTextField('Building / Floor *', _buildingController),
                    const SizedBox(height: 10),
                    // Building Name (Optional)
                    _buildTextField('Building Name (Optional)', _buildingNameController),
                    const SizedBox(height: 10),
                    // Street (Optional)
                    _buildTextField('Street (Optional)', _streetController),
                    const SizedBox(height: 10),
                    // Pincode (Mandatory)
                    _buildTextField('Pincode *', _pincodeController),
                    const SizedBox(height: 10),
                    // Save address as (Mandatory)
                    _buildTextField('Save address as *', _labelController),
                  ]),
                  const SizedBox(height: 20),
                  // Delivery Instructions
                  _buildSection('Delivery Instructions (Recommended)', [
                    _buildTextField('Instructions to reach location', _instructionsController, maxLines: 3),
                  ]),
                  const SizedBox(height: 30),
                  // Location Photos Section
                  _buildSection('Location Photos (Recommended)', [
                    Container(
                      padding: const EdgeInsets.all(20),
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
                          color: AppTheme.saffron.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.saffron.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.saffron.withOpacity(0.2),
                                  AppTheme.saffron.withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(
                                color: AppTheme.saffron.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: AppTheme.saffron,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Add Location Photos',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Help delivery partners reach you faster',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ScaleTransition(
                            scale: _fadeAnimation,
                            child: GestureDetector(
                              onTap: () {
                                debugPrint('📸 Photo upload coming soon...');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.saffron.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppTheme.saffron.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.saffron.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_a_photo, color: AppTheme.saffron, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.saffron,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),
                  // Save Button with Animation
                  ScaleTransition(
                    scale: _fadeAnimation,
                    child: GestureDetector(
                      onTap: _isSaving ? null : _saveAddress,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isSaving
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : [AppTheme.saffron, AppTheme.saffronDark],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _isSaving
                              ? []
                              : [
                                  BoxShadow(
                                    color: AppTheme.saffron.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: AppTheme.saffron.withOpacity(0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSaving)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.5,
                                ),
                              )
                            else
                              Icon(Icons.check_circle, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              _isSaving ? 'Saving address...' : 'Save Address',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.saffron,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.saffron, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 10,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
