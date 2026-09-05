import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';

class Society {
  final int id;
  final String name;
  final String address;
  final String city;

  Society({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
  });

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
    );
  }
}

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
  final TextEditingController _nameController = TextEditingController();
  late TextEditingController _phoneController;

  List<Society>? societies;
  Society? selectedSociety;
  bool _isLoading = false;
  bool _loadingCities = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phoneNumber);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _fetchSocieties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _fetchSocieties() async {
    setState(() => _loadingCities = true);
    try {
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/admin-get-societies.php');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final societiesList = (data['societies'] as List)
              .map((s) => Society.fromJson(s))
              .toList();
          setState(() => societies = societiesList);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to load societies'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loadingCities = false);
    }
  }

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty && selectedSociety != null;
  }

  void _submitRegistration() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/register-secretary.php');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': _nameController.text.trim(),
              'phone': widget.phoneNumber,
              'society_id': selectedSociety!.id,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration submitted! Awaiting admin approval.'),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.pop(context);
          });
        } else {
          throw Exception(data['message'] ?? 'Registration failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Register for a Society',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Society',
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isSmall ? 12 : 16),
                if (_loadingCities)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: isSmall ? 24 : 32),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppTheme.saffron),
                      ),
                    ),
                  )
                else if (societies == null || societies!.isEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: isSmall ? 24 : 32),
                    child: const Center(
                      child: Text('No societies available'),
                    ),
                  )
                else
                  Column(
                    children: societies!.map((society) {
                      final isSelected = selectedSociety?.id == society.id;
                      return GestureDetector(
                        onTap: () => setState(() => selectedSociety = society),
                        child: Container(
                          margin: EdgeInsets.only(bottom: isSmall ? 12 : 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.saffron
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? AppTheme.saffron.withOpacity(0.05)
                                : Colors.white,
                          ),
                          padding: EdgeInsets.all(isSmall ? 12 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      society.name,
                                      style: TextStyle(
                                        fontSize: isSmall ? 14 : 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: AppTheme.saffron,
                                      size: isSmall ? 20 : 24,
                                    ),
                                ],
                              ),
                              SizedBox(height: isSmall ? 6 : 8),
                              Text(
                                society.address,
                                style: TextStyle(
                                  fontSize: isSmall ? 12 : 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: isSmall ? 4 : 6),
                              Text(
                                society.city,
                                style: TextStyle(
                                  fontSize: isSmall ? 12 : 13,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                SizedBox(height: isSmall ? 24 : 32),
                Text(
                  'Your Details',
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isSmall ? 12 : 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Name *',
                      style: TextStyle(
                        fontSize: isSmall ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isSmall ? 6 : 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
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
                      ),
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 15,
                        color: Colors.black87,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? 12 : 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone Number *',
                      style: TextStyle(
                        fontSize: isSmall ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isSmall ? 6 : 8),
                    TextField(
                      controller: _phoneController,
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
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
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isSmall ? 12 : 14,
                          horizontal: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? 24 : 32),
                SizedBox(
                  width: double.infinity,
                  height: isSmall ? 50 : 56,
                  child: ElevatedButton(
                    onPressed: _isFormValid() && !_isLoading
                        ? _submitRegistration
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.saffron,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Submit Registration',
                            style: TextStyle(
                              fontSize: isSmall ? 15 : 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
