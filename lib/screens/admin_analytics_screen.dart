// lib/screens/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../config/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Fetch various statistics
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final pickupsSnapshot = await FirebaseFirestore.instance
          .collection('pickups')
          .get();

      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('dumping_reports')
          .get();

      final binsSnapshot = await FirebaseFirestore.instance
          .collection('bins')
          .get();

      // Calculate pickup status distribution
      final pickupsByStatus = <String, int>{};
      for (var pickup in pickupsSnapshot.docs) {
        final status = pickup.data()['status'] ?? 'unknown';
        pickupsByStatus[status] = (pickupsByStatus[status] ?? 0) + 1;
      }

      // Calculate waste type distribution
      final wasteTypeDistribution = <String, int>{};
      for (var pickup in pickupsSnapshot.docs) {
        final wasteType = pickup.data()['wasteType'] ?? 'Other';
        wasteTypeDistribution[wasteType] =
            (wasteTypeDistribution[wasteType] ?? 0) + 1;
      }

      // Calculate report status distribution
      final reportsByStatus = <String, int>{};
      for (var report in reportsSnapshot.docs) {
        final status = report.data()['status'] ?? 'unknown';
        reportsByStatus[status] = (reportsByStatus[status] ?? 0) + 1;
      }

      setState(() {
        _analyticsData = {
          'totalUsers': usersSnapshot.size,
          'totalPickups': pickupsSnapshot.size,
          'totalReports': reportsSnapshot.size,
          'totalBins': binsSnapshot.size,
          'pickupsByStatus': pickupsByStatus,
          'wasteTypeDistribution': wasteTypeDistribution,
          'reportsByStatus': reportsByStatus,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: isDark ? Colors.green.shade800 : Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummaryCards(isDark),
                  const SizedBox(height: 24),

                  // Pickup Status Chart
                  _buildSectionTitle('Pickup Status Distribution', isDark),
                  const SizedBox(height: 16),
                  _buildPickupStatusChart(isDark),
                  const SizedBox(height: 24),

                  // Waste Type Distribution
                  _buildSectionTitle('Waste Type Distribution', isDark),
                  const SizedBox(height: 16),
                  _buildWasteTypeChart(isDark),
                  const SizedBox(height: 24),

                  // Reports Status
                  _buildSectionTitle('Reports Status', isDark),
                  const SizedBox(height: 16),
                  _buildReportsChart(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            '${_analyticsData['totalUsers'] ?? 0}',
            Icons.people,
            Colors.blue,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Pickups',
            '${_analyticsData['totalPickups'] ?? 0}',
            Icons.local_shipping,
            Colors.green,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildPickupStatusChart(bool isDark) {
    final pickupsByStatus =
        _analyticsData['pickupsByStatus'] as Map<String, int>? ?? {};

    if (pickupsByStatus.isEmpty) {
      return _buildEmptyChart('No pickup data available', isDark);
    }

    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _createPieChartSections(pickupsByStatus),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(pickupsByStatus, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteTypeChart(bool isDark) {
    final wasteTypeDistribution =
        _analyticsData['wasteTypeDistribution'] as Map<String, int>? ?? {};

    if (wasteTypeDistribution.isEmpty) {
      return _buildEmptyChart('No waste type data available', isDark);
    }

    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _createBarChartGroups(wasteTypeDistribution),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final types = wasteTypeDistribution.keys.toList();
                          if (value.toInt() < 0 ||
                              value.toInt() >= types.length) {
                            return const Text('');
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              types[value.toInt()],
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsChart(bool isDark) {
    final reportsByStatus =
        _analyticsData['reportsByStatus'] as Map<String, int>? ?? {};

    if (reportsByStatus.isEmpty) {
      return _buildEmptyChart('No report data available', isDark);
    }

    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: reportsByStatus.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value:
                          entry.value / (_analyticsData['totalReports'] ?? 1),
                      backgroundColor: isDark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        entry.key == 'pending' ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message, bool isDark) {
    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          message,
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections(Map<String, int> data) {
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.red];
    int index = 0;

    return data.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: color,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _createBarChartGroups(Map<String, int> data) {
    return data.entries.toList().asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: Colors.green,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, int> data, bool isDark) {
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.red];
    int index = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.entries.map((entry) {
        final color = colors[index % colors.length];
        index++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              entry.key,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
