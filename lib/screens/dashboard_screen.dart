// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'bin_tracker_screen.dart';
import 'schedule_pickup_screen.dart';
import 'food_stock_screen.dart';
import 'report_dumping_screen.dart';
import 'recycling_info_screen.dart';
import 'recycling_map_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'pickup_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  String _username = "User";
  String _email = "";
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _photoUrl;
  bool _showWelcomeCard = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Auto-hide welcome card after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showWelcomeCard = false;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _username =
                userDoc.data()?['username'] ?? user.displayName ?? "User";
            _email = user.email ?? "";
            _photoUrl = userDoc.data()?['photoUrl'] ?? user.photoURL;
            _isLoading = false;
          });
        } else {
          setState(() {
            _username = user.displayName ?? "User";
            _email = user.email ?? "";
            _photoUrl = user.photoURL;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return const PickupHistoryScreen();
      case 2:
        return const RecyclingMapScreen();
      case 3:
        return ProfileScreen(
          username: _username,
          email: _email,
          photoUrl: _photoUrl,
        );
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return Stack(
      children: [
        // Main content - always visible
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Services',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black87
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildServicesGrid(),
              ],
            ),
          ),
        ),
        // Popup welcome card overlay at the top
        if (_showWelcomeCard)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _showWelcomeCard ? 1.0 : 0.0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: _buildWelcomeCard(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.shade800
                  : Theme.of(context).colorScheme.primary,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: _photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _photoUrl!,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    )
                  : Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
            ),
            accountName: Text(
              _username,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(_email),
          ),
          ListTile(
            leading: Icon(
              Icons.home,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Bin Tracker'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const BinTrackerScreen());
            },
          ),
          ListTile(
            leading: Icon(
              Icons.schedule,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Schedule Pickup'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const SchedulePickupScreen());
            },
          ),
          ListTile(
            leading: Icon(
              Icons.fastfood,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Food Stock Manager'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const FoodStockScreen());
            },
          ),
          ListTile(
            leading: Icon(
              Icons.report,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Report Dumping'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const ReportDumpingScreen());
            },
          ),
          ListTile(
            leading: Icon(
              Icons.info,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Recycling Info'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const RecyclingInfoScreen());
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Colors.green.shade800, Colors.green.shade700]
              : [Colors.green, const Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Together, let\'s make the world cleaner and greener!',
            style: TextStyle(fontSize: 14, color: Colors.white, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      {
        'icon': Icons.delete_outline,
        'title': 'Bin Tracker',
        'description': 'Track your bins',
        'color': Colors.blue,
        'screen': const BinTrackerScreen(),
      },
      {
        'icon': Icons.schedule,
        'title': 'Schedule Pickup',
        'description': 'Request collection',
        'color': Colors.orange,
        'screen': const SchedulePickupScreen(),
      },
      {
        'icon': Icons.fastfood_outlined,
        'title': 'Food Stock',
        'description': 'Manage food waste',
        'color': Colors.purple,
        'screen': const FoodStockScreen(),
      },
      {
        'icon': Icons.report_problem_outlined,
        'title': 'Report Dumping',
        'description': 'Report violations',
        'color': Colors.red,
        'screen': const ReportDumpingScreen(),
      },
      {
        'icon': Icons.info_outline,
        'title': 'Recycling Info',
        'description': 'Learn to recycle',
        'color': Colors.teal,
        'screen': const RecyclingInfoScreen(),
      },
      // {
      //   'icon': Icons.eco,
      //   'title': 'Green Tips',
      //   'description': 'Eco-friendly tips',
      //   'color': Colors.lightGreen,
      //   'screen': const RecyclingInfoScreen(),
      // },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(
          icon: service['icon'] as IconData,
          title: service['title'] as String,
          description: service['description'] as String,
          color: service['color'] as Color,
          onTap: () => _navigateTo(service['screen'] as Widget),
        );
      },
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black87
                      : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[600]
                      : Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[50]
          : null,
      appBar: _currentIndex == 0
          ? AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.shade800
                  : Colors.green,
              foregroundColor: Colors.white,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    _navigateTo(NotificationsScreen(username: _username));
                  },
                ),
              ],
            )
          : null,
      drawer: _buildDrawer(),
      body: _buildCurrentPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            // Refresh user data when switching to profile tab
            if (index == 3) {
              _loadUserData();
            }
          },
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Activity',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
