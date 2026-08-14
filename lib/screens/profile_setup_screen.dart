import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const ProfileSetupScreen({
    required this.phoneNumber,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _currentLocation = 'Fetching location...';
  bool _isLoading = false;
  bool _geoLocationLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _fetchCurrentLocation() async {
    setState(() => _geoLocationLoading = true);
    try {
      // TODO: Integrate with location_geolocator package
      // For now, show placeholder
      setState(() {
        _currentLocation = 'Mumbai, Maharashtra\n(19.0760° N, 72.8777° E)';
      });
    } catch (e) {
      setState(() {
        _currentLocation = 'Failed to fetch location';
      });
    } finally {
      setState(() => _geoLocationLoading = false);
    }
  }

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _currentLocation.isNotEmpty;
  }

  void _completeProfile() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Save profile to database
      // For now, show success and navigate to dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile setup complete!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to dashboard
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.saffron,
                        AppTheme.saffron.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 16 : 20,
                    vertical: MediaQuery.of(context).padding.top + (isSmall ? 10 : 20),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isSmall ? 12 : 16),
                      Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: isSmall ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                      SizedBox(height: isSmall ? 12 : 14),
                      Text(
                        'Help us know you better',
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isSmall ? 20 : 28),
                      Container(
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
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              icon: Icons.person_outline,
                              isSmall: isSmall,
                            ),
                            SizedBox(height: isSmall ? 14 : 16),
                            _buildTextField(
                              controller: _addressController,
                              label: 'Address',
                              hint: 'Enter your residential address',
                              icon: Icons.location_on_outlined,
                              isSmall: isSmall,
                              maxLines: 3,
                            ),
                            SizedBox(height: isSmall ? 14 : 16),
                            Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: isSmall ? 6 : 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: isSmall ? 12 : 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.gps_fixed,
                                    color: Colors.grey.shade600,
                                    size: isSmall ? 18 : 20,
                                  ),
                                  SizedBox(width: isSmall ? 10 : 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _currentLocation,
                                          style: TextStyle(
                                            fontSize: isSmall ? 12 : 13,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_geoLocationLoading)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          AppTheme.saffron,
                                        ),
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: _fetchCurrentLocation,
                                      child: Icon(
                                        Icons.refresh,
                                        color: AppTheme.saffron,
                                        size: isSmall ? 18 : 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmall ? 20 : 28),
                            SizedBox(
                              width: double.infinity,
                              height: isSmall ? 50 : 56,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isFormValid() && !_isLoading
                                      ? _completeProfile
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
                                                valueColor: AlwaysStoppedAnimation(
                                                  Colors.white,
                                                ),
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              'Complete & Access Dashboard',
                                              style: TextStyle(
                                                fontSize: isSmall ? 14 : 15,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
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
    int maxLines = 1,
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
          maxLines: maxLines,
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
