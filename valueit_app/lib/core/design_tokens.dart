import 'package:flutter/material.dart';

/// ValueIt design tokens — professional property-valuation workflow UI.
abstract final class AppColors {
  static const ink = Color(0xFF0B1220);
  static const inkMuted = Color(0xFF475569);
  static const inkSubtle = Color(0xFF94A3B8);

  static const canvas = Color(0xFFF1F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFFAFBFC);
  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);

  static const brand = Color(0xFF1B4D6E);
  static const brandDark = Color(0xFF123347);
  static const brandLight = Color(0xFFE8F1F6);

  static const accent = Color(0xFFB8860B);
  static const accentLight = Color(0xFFFEF9E8);

  static const success = Color(0xFF047857);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFFFBEB);
  static const error = Color(0xFFB91C1C);
  static const errorBg = Color(0xFFFEF2F2);
  static const info = Color(0xFF0369A1);
  static const infoBg = Color(0xFFEFF6FF);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
}

enum ProjectStatusTone { pending, inProgress, completed, neutral }

ProjectStatusTone statusTone(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return ProjectStatusTone.pending;
    case 'in progress':
      return ProjectStatusTone.inProgress;
    case 'completed':
      return ProjectStatusTone.completed;
    default:
      return ProjectStatusTone.neutral;
  }
}
