import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale for the app, built on Inter via google_fonts.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.inter(color: AppColors.textPrimary);

  static TextStyle get displayLarge =>
      _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle get headingLarge =>
      _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25);

  static TextStyle get headingMedium =>
      _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get headingSmall =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get bodyLarge =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle get bodyMedium =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle get bodySmall => _base.copyWith(
      fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: AppColors.textSecondary);

  static TextStyle get labelLarge =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle get labelSmall => _base.copyWith(
      fontSize: 11, fontWeight: FontWeight.w600, height: 1.3, color: AppColors.textSecondary);

  static TextStyle get button =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.surface);
}
