import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({
    Key? key,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController mapController;
  late LatLng _selectedLocation;
  String _selectedAddress = 'Fetching address...';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(19.2183, 73.0784);
    _fetchAddress(_selectedLocation);
    // Auto-load current location if not provided
    if (widget.initialLocation == null) {
      Future.delayed(const Duration(milliseconds: 500), _getCurrentLocation);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddress(LatLng location) async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=AIzaSyD9MUDoEMKnUWRSPEOMvmNkNzsFNI3NvnU',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          var address = data['results'][0]['formatted_address'] ?? 'Address not found';

          // Clean up address step by step
          address = address.replaceAll(RegExp(r'[A-Z0-9]{4}\+[A-Z0-9]{2}'), '').trim(); // Remove Plus Codes
          address = address.replaceAll(RegExp(r',\s*,+'), ', ').trim(); // Replace multiple commas with single comma
          address = address.replaceAll(RegExp(r'\s+'), ' ').trim(); // Remove extra spaces
          address = address.replaceAll(RegExp(r'^,\s*|,\s*$'), '').trim(); // Remove leading/trailing commas

          // Split by comma, filter empty parts, rejoin
          final parts = address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
          address = parts.join(', ').trim();

          setState(() => _selectedAddress = address);
          debugPrint('✅ Clean Address: $address');
        } else {
          setState(() => _selectedAddress = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
        }
      } else {
        setState(() => _selectedAddress = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
      }
    } catch (e) {
      debugPrint('❌ Geocoding error: $e');
      setState(() => _selectedAddress = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=AIzaSyD9MUDoEMKnUWRSPEOMvmNkNzsFNI3NvnU',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final newLocation = LatLng(location['lat'], location['lng']);

          mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: newLocation, zoom: 15),
            ),
          );

          setState(() => _selectedLocation = newLocation);
          await _fetchAddress(newLocation);
          _searchController.clear();
        }
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final status = await Geolocator.requestPermission();
        if (status == LocationPermission.denied ||
            status == LocationPermission.deniedForever) {
          debugPrint('❌ Location permission denied');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newLocation,
            zoom: 17,
          ),
        ),
      );

      setState(() => _selectedLocation = newLocation);
      await _fetchAddress(newLocation);

      debugPrint('📍 Current Location: $newLocation');
    } catch (e) {
      debugPrint('❌ Location error: $e');
    }
  }

  void _confirmLocation() {
    debugPrint('✅ Location confirmed: $_selectedAddress (${_selectedLocation.latitude}, ${_selectedLocation.longitude})');
    Navigator.pop(context, {
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-Screen Google Map
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
              mapController?.setMapStyle(null);
              debugPrint('✅ GoogleMap created successfully');
            },
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            onCameraMove: (CameraPosition position) {
              setState(() => _selectedLocation = position.target);
              _fetchAddress(position.target);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            liteModeEnabled: false,
          ),

          // Top Header with Back & Search
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 12,
                left: 12,
                right: 12,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _searchLocation,
                              decoration: InputDecoration(
                                hintText: 'Search an area or address',
                                hintStyle: TextStyle(color: Colors.grey.shade600),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Draggable Pin
          Center(
            child: Icon(
              Icons.location_on,
              color: AppTheme.saffron,
              size: 50,
              shadows: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          // Current Location Button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 8,
              onPressed: _getCurrentLocation,
              child: Icon(Icons.my_location, color: AppTheme.saffron, size: 24),
            ),
          ),

          // Address Card at Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppTheme.saffron,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Location',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (_isLoading)
                              SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.saffron,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Text(
                                _selectedAddress,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Confirm Button
                  GestureDetector(
                    onTap: _confirmLocation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.saffron, AppTheme.saffronDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.saffron.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'CONFIRM & PROCEED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
