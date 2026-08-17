import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';

class IndividualSignUpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const IndividualSignUpScreen({
    required this.phoneNumber,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<IndividualSignUpScreen> createState() =>
      _IndividualSignUpScreenState();
}

class _IndividualSignUpScreenState extends ConsumerState<IndividualSignUpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _currentLatitude;
  String? _currentLongitude;
  bool _isLoading = false;
  bool _locationFetching = false;
  bool _locationFetched = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _mobileController.text = widget.phoneNumber;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _mobileController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty &&
        _locationFetched;
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.saffron.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: AppTheme.saffron,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enable Location Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We need your location to provide personalized services',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchCurrentLocation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gps_fixed,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Use Current Location',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
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
    );
  }

  void _fetchCurrentLocation() async {
    setState(() => _locationFetching = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Requesting location permission...'),
            backgroundColor: Colors.blue,
          ),
        );
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentLatitude = position.latitude.toString();
          _currentLongitude = position.longitude.toString();
          _locationFetched = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location fetched successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _locationFetching = false);
    }
  }

  void _completeSignUp() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _saveProfileToDatabase(
        phoneNumber: _mobileController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        latitude: _currentLatitude ?? '0',
        longitude: _currentLongitude ?? '0',
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign up successful!'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to complete sign up'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _saveProfileToDatabase({
    required String phoneNumber,
    required String name,
    required String email,
    required String latitude,
    required String longitude,
  }) async {
    try {
      final url =
          Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/save-profile.php');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone_number': phoneNumber,
              'full_name': name,
              'email': email,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: screenHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.saffron,
                        AppTheme.saffron.withOpacity(0.85),
                        const Color(0xFFF25C05),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.saffron.withOpacity(0.15),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top +
                            (isSmall ? 16 : 24),
                        bottom: isSmall ? 20 : 32,
                        left: isSmall ? 12 : 16,
                        right: isSmall ? 12 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: isSmall ? 100 : 120,
                              height: isSmall ? 100 : 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: isSmall ? 14 : 18),
                          Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmall ? 26 : 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          SizedBox(height: isSmall ? 6 : 8),
                          Text(
                            'Join MahaMaintain Pro',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isSmall ? 12 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(
                        isSmall ? 12 : 16,
                        isSmall ? 16 : 20,
                        isSmall ? 12 : 16,
                        isSmall ? 16 : 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.98),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 18 : 24,
                        vertical: isSmall ? 20 : 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _mobileController,
                            label: 'Mobile Number',
                            hint: 'Enter your mobile number',
                            icon: Icons.phone_outlined,
                            isSmall: isSmall,
                            readOnly: false,
                          ),
                          SizedBox(height: isSmall ? 14 : 16),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            isSmall: isSmall,
                          ),
                          SizedBox(height: isSmall ? 14 : 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address (Optional)',
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            isSmall: isSmall,
                          ),
                          SizedBox(height: isSmall ? 16 : 20),
                          if (_locationFetched)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: isSmall ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: isSmall ? 8 : 10),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: isSmall ? 14 : 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.saffron.withOpacity(0.08),
                                        AppTheme.saffron.withOpacity(0.04),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppTheme.saffron.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        color: AppTheme.saffron,
                                        size: isSmall ? 20 : 22,
                                      ),
                                      SizedBox(width: isSmall ? 12 : 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Latitude',
                                              style: TextStyle(
                                                fontSize: isSmall ? 11 : 12,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              _currentLatitude ?? '0',
                                              style: TextStyle(
                                                fontSize: isSmall ? 12 : 13,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Longitude',
                                              style: TextStyle(
                                                fontSize: isSmall ? 11 : 12,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              _currentLongitude ?? '0',
                                              style: TextStyle(
                                                fontSize: isSmall ? 12 : 13,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _fetchCurrentLocation,
                                        child: Icon(
                                          Icons.refresh_rounded,
                                          color: AppTheme.saffron,
                                          size: isSmall ? 20 : 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isSmall ? 16 : 20),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: isSmall ? 50 : 56,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _showLocationDialog,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade50,
                                              Colors.blue.shade50
                                                  .withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.blue.shade200,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              color: Colors.blue.shade700,
                                              size: isSmall ? 20 : 22,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Add Location',
                                              style: TextStyle(
                                                fontSize: isSmall ? 14 : 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmall ? 16 : 20),
                              ],
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: isSmall ? 50 : 56,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isFormValid() && !_isLoading
                                    ? _completeSignUp
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.saffron,
                                        AppTheme.saffron.withOpacity(0.85),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.saffron.withOpacity(0.35),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                Colors.white,
                                              ),
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Sign Up',
                                                style: TextStyle(
                                                  fontSize:
                                                      isSmall ? 15 : 16,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward,
                                                color: Colors.white,
                                                size: isSmall ? 18 : 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isSmall,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isSmall ? 6 : 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: isSmall ? 12 : 13,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.saffron,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: isSmall ? 12 : 14,
              horizontal: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                icon,
                color: Colors.grey.shade600,
                size: isSmall ? 18 : 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
          ),
          style: TextStyle(
            fontSize: isSmall ? 14 : 15,
            color: Colors.black87,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
