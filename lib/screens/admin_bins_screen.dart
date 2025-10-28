// lib/screens/admin_bins_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../config/theme_provider.dart';
import '../services/notification_message_service.dart';
import 'package:intl/intl.dart';

class AdminBinsScreen extends StatefulWidget {
  const AdminBinsScreen({super.key});

  @override
  State<AdminBinsScreen> createState() => _AdminBinsScreenState();
}

class _AdminBinsScreenState extends State<AdminBinsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bin Management'),
        backgroundColor: isDark ? Colors.green.shade800 : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: isDark ? Colors.grey[850] : Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by bin ID or location...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              ),
            ),
          ),

          // Bins List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bins')
                  .orderBy('lastUpdated', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final bins = snapshot.data?.docs ?? [];

                // Apply search filter
                final filteredBins = bins.where((bin) {
                  final data = bin.data() as Map<String, dynamic>;
                  final binId = bin.id.toLowerCase();
                  final location = (data['location'] ?? '')
                      .toString()
                      .toLowerCase();
                  return binId.contains(_searchQuery) ||
                      location.contains(_searchQuery);
                }).toList();

                if (filteredBins.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 80,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bins found',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                  itemCount: filteredBins.length,
                  itemBuilder: (context, index) {
                    final bin =
                        filteredBins[index].data() as Map<String, dynamic>;
                    final binId = filteredBins[index].id;
                    return _buildBinCard(binId, bin, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBinDialog(isDark),
        backgroundColor: isDark ? Colors.green.shade700 : Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBinCard(String binId, Map<String, dynamic> bin, bool isDark) {
    final binType = bin['type'] ?? 'Standard';
    final location = bin['location'] ?? 'Unknown';
    final status = bin['status'] ?? 'available';
    final fillLevel = bin['fillLevel'] ?? 0;
    final lastUpdated = bin['lastUpdated'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bin #$binId',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        binType,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),

            // Fill Level
            Row(
              children: [
                Text(
                  'Fill Level:',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: fillLevel / 100,
                    backgroundColor: isDark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getFillLevelColor(fillLevel),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$fillLevel%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            if (lastUpdated != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Updated ${DateFormat('MMM dd, yyyy').format(lastUpdated.toDate())}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBinDetails(binId, bin),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.green.shade400
                          : Colors.green,
                      side: BorderSide(
                        color: isDark ? Colors.green.shade700 : Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateBinStatus(binId, status),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.green.shade700
                          : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteBin(binId),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'in-use':
        return Colors.blue;
      case 'full':
        return Colors.red;
      case 'in-transit':
        return Colors.purple;
      case 'picked-up':
        return Colors.teal;
      case 'recycled':
        return Colors.lightGreen;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getFillLevelColor(int fillLevel) {
    if (fillLevel >= 80) return Colors.red;
    if (fillLevel >= 50) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showBinDetails(String binId, Map<String, dynamic> bin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bin #$binId'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', bin['type'] ?? 'N/A'),
              _buildDetailRow('Status', bin['status'] ?? 'N/A'),
              _buildDetailRow('Location', bin['location'] ?? 'N/A'),
              _buildDetailRow('Fill Level', '${bin['fillLevel'] ?? 0}%'),
              _buildDetailRow('Bin ID', binId),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _updateBinStatus(String binId, String currentStatus) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Bin Status'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Available'),
                subtitle: const Text('Bin is ready for use'),
                leading: Radio<String>(
                  value: 'available',
                  groupValue: currentStatus,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              ),
              ListTile(
                title: const Text('In-Use'),
                subtitle: const Text('Bin is currently being used'),
                leading: Radio<String>(
                  value: 'in-use',
                  groupValue: currentStatus,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              ),
              ListTile(
                title: const Text('Full'),
                subtitle: const Text('Bin is full and needs pickup'),
                leading: Radio<String>(
                  value: 'full',
                  groupValue: currentStatus,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              ),
              ListTile(
                title: const Text('In-Transit'),
                subtitle: const Text('Bin is being transported'),
                leading: Radio<String>(
                  value: 'in-transit',
                  groupValue: currentStatus,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              ),
              ListTile(
                title: const Text('Picked Up'),
                subtitle: const Text('Bin has been picked up'),
                leading: Radio<String>(
                  value: 'picked-up',
                  groupValue: currentStatus,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              ),
              ListTile(
                title: const Text('Recycled'),
                subtitle: const Text('Waste has been recycled'),
                leading: Radio<String>(
                  value: 'recycled',
                  groupValue: currentStatus,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              ),
              ListTile(
                title: const Text('Maintenance'),
                subtitle: const Text('Bin needs maintenance'),
                leading: Radio<String>(
                  value: 'maintenance',
                  groupValue: currentStatus,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      try {
        // Get the bin document first to retrieve userId and pickupId
        final binDoc = await FirebaseFirestore.instance
            .collection('bins')
            .doc(binId)
            .get();

        if (!binDoc.exists) {
          throw Exception('Bin not found');
        }

        final binData = binDoc.data();
        final userId = binData?['userId'];
        final binType = binData?['type'] ?? 'waste';
        final pickupId = binData?['pickupId'];

        // Update bin status
        await FirebaseFirestore.instance.collection('bins').doc(binId).update({
          'status': newStatus,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Handle notifications and related updates based on status
        if (userId != null) {
          // If status changed to "picked-up", send notification to user
          if (newStatus == 'picked-up') {
            await NotificationMessageService.sendMessage(
              userId: userId,
              title: 'Bin Picked Up! ♻️',
              message:
                  'Your $binType bin has been successfully picked up and is being processed. Thank you for your contribution to a cleaner environment!',
              category: 'Pickup',
            );
          }
          // If status changed to "recycled", send completion notification and update pickup
          else if (newStatus == 'recycled') {
            // Send recycling completion notification
            await NotificationMessageService.sendMessage(
              userId: userId,
              title: 'Recycling Completed! 🌱',
              message:
                  'Your $binType has been successfully recycled! Thank you for making a positive impact on our environment. You\'re helping create a sustainable future!',
              category: 'Pickup',
            );

            // Update associated pickup to "Completed" status
            if (pickupId != null && pickupId.toString().isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('pickups')
                  .doc(pickupId)
                  .update({
                    'status': 'Completed',
                    'completedAt': FieldValue.serverTimestamp(),
                  });
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bin status updated to $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteBin(String binId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bin'),
        content: const Text(
          'Are you sure you want to delete this bin? This action cannot be undone.',
        ),
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
      try {
        print('Attempting to delete bin with ID: $binId');

        // Delete the bin document
        await FirebaseFirestore.instance.collection('bins').doc(binId).delete();

        print('Bin deleted successfully: $binId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Bin deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error deleting bin: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Failed to delete bin: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _showAddBinDialog(bool isDark) {
    final typeController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Bin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Bin Type',
                hintText: 'e.g., Standard, Recycling',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Enter location',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (typeController.text.isNotEmpty &&
                  locationController.text.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance.collection('bins').add({
                    'type': typeController.text,
                    'location': locationController.text,
                    'status': 'available',
                    'fillLevel': 0,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bin added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add bin: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
