import 'package:flutter/material.dart';

/// Centralized asset paths and icon constants.
///
/// All asset references and commonly-used icons should come
/// from here so they can be found and updated in one place.
class AppAssets {
  AppAssets._();

  // ── Images ───────────────────────────────────────────
  static const String logo = 'assets/images/app_logo.png';

  // ── Icons (semantic names for commonly-reused icons) ─
  static const IconData discover = Icons.local_fire_department;
  static const IconData library = Icons.auto_stories;
  static const IconData profile = Icons.person_outline;
  static const IconData like = Icons.favorite;
  static const IconData pass = Icons.close;
  static const IconData spice = Icons.local_fire_department;
  static const IconData spiceOutlined = Icons.local_fire_department_outlined;
  static const IconData bookPlaceholder = Icons.auto_stories;
  static const IconData error = Icons.error_outline;
  static const IconData refresh = Icons.refresh;
  static const IconData signOut = Icons.logout;
  static const IconData pages = Icons.menu_book_outlined;
  static const IconData mood = Icons.mood;
  static const IconData warning = Icons.warning_amber_outlined;
}
