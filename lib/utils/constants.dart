import 'package:flutter/material.dart';

/// API and server configuration
class ApiConfig {
  static const String baseUrl = 'https://digitrixmedia.com/mahamaintainpro';
  static const String imagesUrl = '$baseUrl/assets/services';
}

/// Central color palette for Maha Maintain CRM.
class AppColors {
  static const teal = Color(0xFF0F766E);
  static const tealDark = Color(0xFF0B4F4A);
  static const saffron = Color(0xFFEF8B22);
  static const background = Color(0xFFF4F6F5);
  static const cardWhite = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
}

/// Cities Maha Maintain currently operates / sells in.
const List<String> serviceCities = [
  'Mumbai',
  'Navi Mumbai',
  'Thane',
  'Pune',
  'Nashik',
  'Nagpur',
];
