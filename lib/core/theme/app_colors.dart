import 'package:flutter/material.dart';

/// Finecity Landscape color palette.
class AppColors {
  AppColors._();

  // Primary
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF81C784);
  static const primaryDark = Color(0xFF1B5E20);

  // Care type
  static const careWatering = Color(0xFF1976D2);
  static const careFertilizer = Color(0xFFFF8F00);
  static const carePruning = Color(0xFF7B1FA2);
  static const careRepotting = Color(0xFF5D4037);
  static const careGeneral = Color(0xFF546E7A);

  // Task status
  static const statusPending = Color(0xFFF9A825);
  static const statusDue = Color(0xFFE65100);
  static const statusOverdue = Color(0xFFE53935);
  static const statusCompleted = Color(0xFF2E7D32);
  static const statusMissed = Color(0xFFB71C1C);

  // Neutrals
  static const background = Color(0xFFF5F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1B1B1B);
  static const textSecondary = Color(0xFF6B6B6B);
  static const border = Color(0xFFE0E0E0);
  static const disabled = Color(0xFFBDBDBD);

  /// Returns the color for a given care type string.
  static Color careTypeColor(String type) {
    switch (type) {
      case 'watering':
        return careWatering;
      case 'fertilizer':
        return careFertilizer;
      case 'pruning':
        return carePruning;
      case 'repotting':
        return careRepotting;
      default:
        return careGeneral;
    }
  }

  /// Returns the color for a given task status string.
  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return statusPending;
      case 'due':
        return statusDue;
      case 'overdue':
        return statusOverdue;
      case 'completed':
        return statusCompleted;
      case 'missed':
        return statusMissed;
      case 'skipped':
        return disabled;
      default:
        return textSecondary;
    }
  }
}
