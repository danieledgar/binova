// lib/config/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isLoading = true;

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  ThemeProvider() {
    _loadThemePreference();
  }

  // Load theme preference from Firestore
  Future<void> _loadThemePreference() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          _isDarkMode = userDoc.data()?['darkMode'] ?? false;
        }
      }
    } catch (e) {
      print('Error loading theme preference: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    // Save to Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'darkMode': _isDarkMode,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  // Set dark mode explicitly
  Future<void> setDarkMode(bool value) async {
    print('🎨 ThemeProvider.setDarkMode called with value: $value');
    print('🎨 Current isDarkMode: $_isDarkMode');

    if (_isDarkMode == value) {
      print('🎨 Value unchanged, skipping');
      return;
    }

    _isDarkMode = value;
    print('🎨 isDarkMode changed to: $_isDarkMode');
    notifyListeners();
    print('🎨 notifyListeners() called');

    // Save to Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('🎨 Current user: ${user?.uid}');
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'darkMode': _isDarkMode,
        }, SetOptions(merge: true));
        print('🎨 Dark mode saved to Firestore');
      }
    } catch (e) {
      print('❌ Error saving theme preference: $e');
    }
  }

  // Reload theme after login
  Future<void> reloadTheme() async {
    _isLoading = true;
    notifyListeners();
    await _loadThemePreference();
  }
}
