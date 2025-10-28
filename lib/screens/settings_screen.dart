// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../config/theme_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  bool _isDarkMode = false;
  bool _pickupReminders = true;
  bool _binStatusUpdates = true;
  bool _isDeleting = false;
  bool _isLoadingPreferences = true;
  bool _isUploadingImage = false;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _loadProfilePhoto();

    // Load dark mode state from ThemeProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _isDarkMode = themeProvider.isDarkMode;
      });
    });

    // Debug: Print user info
    final user = _authService.currentUser;
    print('Current user photoURL: ${user?.photoURL}');
    print('Current user displayName: ${user?.displayName}');
    print('Current user email: ${user?.email}');
  }

  Future<void> _loadProfilePhoto() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        // First check if user has a custom photo in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['photoUrl'] != null) {
          // Use custom uploaded photo from Firestore
          setState(() {
            _profilePhotoUrl = userDoc.data()?['photoUrl'];
          });
        } else {
          // Fall back to Google/Firebase Auth photo (for Google Sign-In users)
          setState(() {
            _profilePhotoUrl = user.photoURL;
          });
        }
      } catch (e) {
        print('Error loading profile photo: $e');
        // Fall back to Firebase Auth photo
        setState(() {
          _profilePhotoUrl = user.photoURL;
        });
      }
    }
  }

  Future<void> _updateProfilePhoto() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final user = _authService.currentUser;
      if (user == null) throw 'User not logged in';

      // Delete old photo if exists
      if (_profilePhotoUrl != null) {
        await StorageService.deleteImage(_profilePhotoUrl!);
      }

      // Upload new photo to Firebase Storage
      final downloadUrl = await StorageService.uploadImage(
        File(image.path),
        user.uid,
      );
      if (downloadUrl == null) throw 'Failed to upload image';

      // Update user profile
      await user.updatePhotoURL(downloadUrl);

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': downloadUrl,
      }, SetOptions(merge: true));

      setState(() {
        _profilePhotoUrl = downloadUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserPreferences() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final data = userDoc.data();
          setState(() {
            _isDarkMode = data?['darkMode'] ?? false;
            _pickupReminders = data?['pickupReminders'] ?? true;
            _binStatusUpdates = data?['binStatusUpdates'] ?? true;
            _isLoadingPreferences = false;
          });
        } else {
          setState(() => _isLoadingPreferences = false);
        }
      } catch (e) {
        print('Error loading preferences: $e');
        setState(() => _isLoadingPreferences = false);
      }
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setDarkMode(value);

    setState(() => _isDarkMode = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dark mode ${value ? 'enabled' : 'disabled'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _togglePickupReminders(bool value) async {
    setState(() => _pickupReminders = value);
    final user = _authService.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'pickupReminders': value,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pickup reminders ${value ? 'enabled' : 'disabled'}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error saving reminder preference: $e');
      }
    }
  }

  Future<void> _toggleBinStatusUpdates(bool value) async {
    setState(() => _binStatusUpdates = value);
    final user = _authService.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'binStatusUpdates': value,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bin status updates ${value ? 'enabled' : 'disabled'}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error saving status update preference: $e');
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_clock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw 'User not logged in';

        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // Update password
        await user.updatePassword(newPasswordController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Failed to change password';
        if (e.code == 'wrong-password') {
          errorMessage = 'Current password is incorrect';
        } else if (e.code == 'weak-password') {
          errorMessage = 'New password is too weak';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Binova Terms of Service',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text('Last Updated: January 2025\n'),
              _buildTermSection(
                '1. Acceptance of Terms',
                'By accessing and using Binova, you accept and agree to be bound by these Terms of Service.',
              ),
              _buildTermSection(
                '2. Service Description',
                'Binova provides waste management and recycling services including bin tracking, pickup scheduling, and recycling information.',
              ),
              _buildTermSection(
                '3. User Responsibilities',
                'Users must provide accurate information, maintain account security, and comply with local waste disposal regulations.',
              ),
              _buildTermSection(
                '4. Pickup Services',
                'Scheduled pickups are subject to availability. We reserve the right to reschedule based on operational needs.',
              ),
              _buildTermSection(
                '5. Data Usage',
                'We collect location data to provide recycling center information and optimize collection routes.',
              ),
              _buildTermSection(
                '6. Prohibited Activities',
                'Users must not misuse the service, provide false information, or attempt to access unauthorized areas.',
              ),
              _buildTermSection(
                '7. Service Modifications',
                'Binova reserves the right to modify or discontinue services with reasonable notice.',
              ),
              _buildTermSection(
                '8. Limitation of Liability',
                'Binova is not liable for delays, service interruptions, or issues beyond our control.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Binova Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text('Last Updated: January 2025\n'),
              _buildTermSection(
                '1. Information We Collect',
                'We collect personal information (name, email), location data, pickup preferences, and usage statistics.',
              ),
              _buildTermSection(
                '2. How We Use Your Information',
                'Your data is used to provide services, optimize routes, send notifications, and improve user experience.',
              ),
              _buildTermSection(
                '3. Location Data',
                'Location data is used to show nearby recycling centers and coordinate pickups. You can disable location services anytime.',
              ),
              _buildTermSection(
                '4. Data Storage',
                'Your data is securely stored using Firebase services with industry-standard encryption.',
              ),
              _buildTermSection(
                '5. Data Sharing',
                'We do not sell your data. Information is shared only with service providers necessary for operations.',
              ),
              _buildTermSection(
                '6. Notifications',
                'We send notifications about pickup status and reminders. You can manage preferences in settings.',
              ),
              _buildTermSection(
                '7. Your Rights',
                'You can access, modify, or delete your data anytime. Account deletion permanently removes all data.',
              ),
              _buildTermSection(
                '8. Cookies and Tracking',
                'We use necessary cookies for authentication and preferences. No third-party tracking cookies are used.',
              ),
              _buildTermSection(
                '9. Children\'s Privacy',
                'Our service is not intended for users under 13. We do not knowingly collect data from children.',
              ),
              _buildTermSection(
                '10. Policy Changes',
                'We may update this policy and will notify users of significant changes.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact Us',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'For privacy concerns, contact us at: privacy@binova.app',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw 'No user logged in';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Deleting account...'),
            ],
          ),
        ),
      );

      await _deleteUserData(user.uid);
      await user.delete();
      await _authService.signOut();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('users').doc(uid).delete();

      final binsSnapshot = await firestore
          .collection('bins')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in binsSnapshot.docs) {
        await doc.reference.delete();
      }

      final pickupsSnapshot = await firestore
          .collection('pickups')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in pickupsSnapshot.docs) {
        await doc.reference.delete();
      }

      final foodSnapshot = await firestore
          .collection('food_stock')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in foodSnapshot.docs) {
        await doc.reference.delete();
      }

      final reportsSnapshot = await firestore
          .collection('dumping_reports')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in reportsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('All user data deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
      throw 'Failed to delete user data';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPreferences) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          // Use themed AppBar colors (from AppTheme) instead of hard-coded
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // Match previous light look, but keep dark mode styling
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[50]
          : null,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        // Restore original green AppBar in light mode
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.green
            : null,
        foregroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingsCard(
            children: [_buildAccountInfo(), _buildChangePasswordTile()],
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Appearance'),
          _buildSettingsCard(children: [_buildDarkModeTile()]),
          const SizedBox(height: 24),

          _buildSectionHeader('Notifications'),
          _buildSettingsCard(
            children: [
              _buildNotificationTile(
                'Pickup Reminders',
                'Get notified before scheduled pickups',
                _pickupReminders,
                _togglePickupReminders,
              ),
              _buildNotificationTile(
                'Bin Status Updates',
                'Receive updates on bin collection status',
                _binStatusUpdates,
                _toggleBinStatusUpdates,
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('About'),
          _buildSettingsCard(
            children: [
              _buildSimpleTile(
                Icons.info_outline,
                'App Version',
                '1.0.0',
                null,
              ),
              _buildSimpleTile(
                Icons.description_outlined,
                'Terms of Service',
                '',
                _showTermsOfService,
              ),
              _buildSimpleTile(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                '',
                _showPrivacyPolicy,
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildDangerZone(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAccountInfo() {
    final user = _authService.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final userInitial = displayName[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _updateProfilePhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.shade100,
                  child: _isUploadingImage
                      ? const CircularProgressIndicator()
                      : _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _profilePhotoUrl!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) {
                              print('Error loading image: $error');
                              return Text(
                                userInitial,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          userInitial,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordTile() {
    return ListTile(
      leading: const Icon(Icons.lock_outline, color: Colors.green),
      title: const Text('Change Password'),
      subtitle: const Text('Update your account password'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _changePassword,
    );
  }

  Widget _buildDarkModeTile() {
    return SwitchListTile(
      secondary: Icon(
        _isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Dark Mode'),
      subtitle: const Text('Switch between light and dark theme'),
      value: _isDarkMode,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      onChanged: _toggleDarkMode,
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(
        value ? Icons.notifications_active : Icons.notifications_off,
        color: value ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(title),
      subtitle: Text(
        value ? subtitle : 'Disabled',
        style: TextStyle(
          color: value
              ? Theme.of(context).textTheme.bodySmall?.color
              : Colors.grey,
        ),
      ),
      value: value,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      onChanged: onChanged,
    );
  }

  Widget _buildSimpleTile(
    IconData icon,
    String title,
    String trailing,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: trailing.isNotEmpty
          ? Text(trailing, style: TextStyle(color: Theme.of(context).hintColor))
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDangerZone() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.2)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Permanently delete your account and data'),
              trailing: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right, color: Colors.red),
              onTap: _isDeleting ? null : _confirmDeleteAccount,
            ),
          ),
        ],
      ),
    );
  }
}
