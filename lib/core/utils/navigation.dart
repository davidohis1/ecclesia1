import 'package:flutter/material.dart';
import '../../features/profile/screens/profile_screen.dart';

/// Call this from anywhere to open a user profile.
/// Keeps a single import point so no circular dependencies.
void openProfile(BuildContext context, String userId) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
  );
}