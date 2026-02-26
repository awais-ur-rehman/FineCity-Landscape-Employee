import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Finecity Landscape typography scale using Poppins.
class AppTypography {
  AppTypography._();

  static const _fontFamily = 'Poppins';

  static const h1 = TextStyle(
    fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const body1 = TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const body2 = TextStyle(
    fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const caption = TextStyle(
    fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const button = TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const overline = TextStyle(
    fontFamily: _fontFamily, fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, letterSpacing: 1.5,
  );
}
