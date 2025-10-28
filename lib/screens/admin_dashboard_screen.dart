// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../config/theme_provider.dart';
import 'admin_users_screen.dart';
import 'admin_pickups_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_bins_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_food_stock_screen.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int totalUsers = 0;
  int totalPickups = 0;
  int pendingReports = 0;
  int activeBins = 0;
  int pendingPickups = 0;
  int lowStockItems = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      // Get total users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // Get total pickups
      final pickupsSnapshot = await FirebaseFirestore.instance
          .collection('pickups')
          .get();

      // Get pending reports
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('dumping_reports')
          .where('status', isEqualTo: 'pending')
          .get();

      // Get active bins count
      final binsSnapshot = await FirebaseFirestore.instance
          .collection('bins')
          .where('status', isEqualTo: 'available')
          .get();

      // Get pending pickups count
      final pendingPickupsSnapshot = await FirebaseFirestore.instance
          .collection('pickups')
          .where('status', isEqualTo: 'pending')
          .get();

      // Get low stock items count
      final foodStockSnapshot = await FirebaseFirestore.instance
          .collection('food_stock')
          .where('quantity', isLessThan: 10)
          .get();

      if (mounted) {
        setState(() {
          totalUsers = usersSnapshot.size;
          totalPickups = pickupsSnapshot.size;
          pendingReports = reportsSnapshot.size;
          activeBins = binsSnapshot.size;
          pendingPickups = pendingPickupsSnapshot.size;
          lowStockItems = foodStockSnapshot.size;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadStatistics()); // Reload stats when returning
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: isDark ? Colors.green.shade800 : Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen(),
                  ),
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 4,
                      color: isDark ? Colors.green.shade800 : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Admin Portal',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage and monitor the platform',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistics Cards
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          'Pending Pickups',
                          pendingPickups,
                          Icons.local_shipping_outlined,
                          Colors.orange,
                          isDark,
                        ),
                        _buildStatCard(
                          'Pending Reports',
                          pendingReports,
                          Icons.report_problem,
                          Colors.red,
                          isDark,
                        ),
                        _buildStatCard(
                          'Low Stock Items',
                          lowStockItems,
                          Icons.inventory_2_outlined,
                          Colors.amber,
                          isDark,
                        ),
                        _buildStatCard(
                          'Active Bins',
                          activeBins,
                          Icons.delete_outline,
                          Colors.green,
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Management Sections
                    Text(
                      'Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildManagementCard(
                      'User Management',
                      'View and manage all users',
                      Icons.people_outline,
                      Colors.blue,
                      () => _navigateTo(const AdminUsersScreen()),
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      'Pickup Management',
                      'Manage scheduled pickups',
                      Icons.event,
                      Colors.orange,
                      () => _navigateTo(const AdminPickupsScreen()),
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      'Dumping Reports',
                      'Review and resolve reports',
                      Icons.report,
                      Colors.red,
                      () => _navigateTo(const AdminReportsScreen()),
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      'Food Stock Inventory',
                      'Manage food donations & stock',
                      Icons.inventory_2,
                      Colors.orange,
                      () => _navigateTo(const AdminFoodStockScreen()),
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      'Bin Management',
                      'Monitor and manage bins',
                      Icons.delete_outline,
                      Colors.green,
                      () => _navigateTo(const AdminBinsScreen()),
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      'Analytics',
                      'View platform statistics',
                      Icons.analytics,
                      Colors.purple,
                      () => _navigateTo(const AdminAnalyticsScreen()),
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
