// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String email;
  // Add photoUrl parameter
  final String? photoUrl;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.email,
    this.photoUrl, // Add this parameter
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, int> _stats = {
    'totalPickups': 0,
    'completedPickups': 0,
    'foodItems': 0,
    'reports': 0,
  };
  bool _isLoadingStats = true;
  String? _profilePhotoUrl;
  String _currentUsername = '';
  String? _currentMobileNo;
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    print('📸 ProfileScreen initState: photoUrl passed = ${widget.photoUrl}');
    // Initialize with the passed photoUrl immediately
    _profilePhotoUrl = widget.photoUrl;
    _currentUsername = widget.username;
    _loadUserStats();
    _loadProfilePhoto();
    _loadUserData();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload photo if the widget's photoUrl prop changed
    if (oldWidget.photoUrl != widget.photoUrl) {
      print(
        '📸 ProfileScreen didUpdateWidget: photoUrl changed from ${oldWidget.photoUrl} to ${widget.photoUrl}',
      );
      _loadProfilePhoto();
    }
  }

  Future<void> _loadProfilePhoto() async {
    final user = _authService.currentUser;
    print('📸 ProfileScreen: Loading profile photo for user: ${user?.uid}');

    if (user != null) {
      try {
        // First check if user has a custom photo in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final dynamic rawDocPhoto = userDoc.data()?['photoUrl'];
        final String? docPhoto =
            rawDocPhoto is String && rawDocPhoto.trim().isNotEmpty
            ? rawDocPhoto.trim()
            : null;
        final String? widgetPhoto =
            widget.photoUrl != null && widget.photoUrl!.trim().isNotEmpty
            ? widget.photoUrl!.trim()
            : null;
        final String? authPhoto =
            user.photoURL != null && user.photoURL!.trim().isNotEmpty
            ? user.photoURL!.trim()
            : null;

        print('📸 Firestore photoUrl: $docPhoto');
        print('📸 Widget photoUrl: $widgetPhoto');
        print('📸 Firebase Auth photoURL: $authPhoto');

        final String? chosen = docPhoto ?? widgetPhoto ?? authPhoto;
        print('📸 Chosen photoUrl: $chosen');

        if (mounted) {
          setState(() {
            _profilePhotoUrl = chosen;
          });
          print('📸 Final _profilePhotoUrl set to: $_profilePhotoUrl');
        }
      } catch (e) {
        print('❌ Error loading profile photo: $e');
        // Fall back to Firebase Auth photo or widget photo
        final String? widgetPhoto = widget.photoUrl;
        final String? authPhoto = user.photoURL;
        final String? chosen =
            (widgetPhoto != null && widgetPhoto.trim().isNotEmpty)
            ? widgetPhoto.trim()
            : (authPhoto != null && authPhoto.trim().isNotEmpty
                  ? authPhoto.trim()
                  : null);
        setState(() {
          _profilePhotoUrl = chosen;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _currentUsername = userDoc.data()?['username'] ?? widget.username;
            _currentMobileNo = userDoc.data()?['mobileNo'];
            _currentRole = userDoc.data()?['role'];
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _loadUserStats() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        // Get pickups count
        final pickupsSnapshot = await FirebaseFirestore.instance
            .collection('pickups')
            .where('userId', isEqualTo: user.uid)
            .get();

        // Get completed pickups count
        final completedPickupsSnapshot = await FirebaseFirestore.instance
            .collection('pickups')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'Completed')
            .get();

        // Get food items count
        final foodSnapshot = await FirebaseFirestore.instance
            .collection('food_stock')
            .where('userId', isEqualTo: user.uid)
            .get();

        // Get reports count
        final reportsSnapshot = await FirebaseFirestore.instance
            .collection('dumping_reports')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (mounted) {
          setState(() {
            _stats = {
              'totalPickups': pickupsSnapshot.docs.length,
              'completedPickups': completedPickupsSnapshot.docs.length,
              'foodItems': foodSnapshot.docs.length,
              'reports': reportsSnapshot.docs.length,
            };
            _isLoadingStats = false;
          });
        }
      } catch (e) {
        print('Error loading stats: $e');
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Match app light look (soft gray) while keeping dark theme default
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[50]
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [Colors.green.shade800, Colors.green.shade700]
                      : [Colors.green, const Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 40, top: 60),
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      print(
                        '📸 ProfileScreen build: _profilePhotoUrl = $_profilePhotoUrl',
                      );
                      final displayName = _currentUsername.isNotEmpty
                          ? _currentUsername
                          : widget.username;
                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child:
                            _profilePhotoUrl != null &&
                                _profilePhotoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _profilePhotoUrl!,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                placeholder: (context, url) {
                                  print('📸 Loading image from: $url');
                                  return const CircularProgressIndicator();
                                },
                                errorWidget: (context, url, error) {
                                  print(
                                    '❌ Error loading profile image: $error',
                                  );
                                  print('❌ Failed URL: $url');
                                  return Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  );
                                },
                              )
                            : Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentUsername.isNotEmpty
                        ? _currentUsername
                        : widget.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  if (_currentMobileNo != null && _currentMobileNo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _currentMobileNo!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Eco Warrior',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoadingStats
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Impact',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.green
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Pickups',
                                _stats['totalPickups'].toString(),
                                Icons.local_shipping,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Completed',
                                _stats['completedPickups'].toString(),
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Food Items',
                                _stats['foodItems'].toString(),
                                Icons.restaurant,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Reports',
                                _stats['reports'].toString(),
                                Icons.report,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Account Section
                        Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.green
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal information',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                  currentUsername: _currentUsername.isNotEmpty
                                      ? _currentUsername
                                      : widget.username,
                                  currentEmail: widget.email,
                                  currentPhotoUrl: _profilePhotoUrl,
                                  currentMobileNo: _currentMobileNo,
                                  currentRole: _currentRole,
                                ),
                              ),
                            );

                            // Reload data if profile was updated
                            if (result == true && mounted) {
                              await _loadProfilePhoto();
                              await _loadUserData();
                              setState(() {}); // Force rebuild
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          icon: Icons.settings,
                          title: 'Settings',
                          subtitle: 'Manage your preferences',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help and contact support',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Contact support at: support@binova.app',
                                ),
                                backgroundColor: Colors.blue,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          icon: Icons.info_outline,
                          title: 'About Binova',
                          subtitle: 'Version 1.0.0',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.green.shade50,
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/binova_logo.png',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Binova',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          'Version 1.0.0',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).hintColor,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                content: const Text(
                                  'Binova is your smart waste management companion. '
                                  'Together, we\'re making the world cleaner and greener!',
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _handleLogout,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.08,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
