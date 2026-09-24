import 'package:flutter/material.dart';

/// Single source of truth for every color used in the app.
/// Never hardcode a Color(...) value in a screen/widget — reference this class.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0B5FFF);
  static const Color primaryDark = Color(0xFF0842B8);
  static const Color primaryLight = Color(0xFFE8F0FF);
  static const Color secondary = Color(0xFF00B894);

  // Neutrals
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E7EC);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textDisabled = Color(0xFF98A2B3);

  // Status
  static const Color success = Color(0xFF12B76A);
  static const Color warning = Color(0xFFF79009);
  static const Color error = Color(0xFFF04438);
  static const Color info = Color(0xFF0B5FFF);

  // Lead pipeline stage colors (Kanban)
  static const Color stageNew = Color(0xFF7F56D9);
  static const Color stageContacted = Color(0xFF0B5FFF);
  static const Color stageQualified = Color(0xFFF79009);
  static const Color stageProposal = Color(0xFF00B894);
  static const Color stageWon = Color(0xFF12B76A);
  static const Color stageLost = Color(0xFFF04438);

  // Role badge colors
  static const Color roleSuperAdmin = Color(0xFF7F56D9);
  static const Color roleAdmin = Color(0xFF0B5FFF);
  static const Color roleSalesManager = Color(0xFF00B894);
  static const Color roleSalesExecutive = Color(0xFFF79009);
  static const Color roleTechnician = Color(0xFF12B76A);
  static const Color roleCustomer = Color(0xFF667085);
}
