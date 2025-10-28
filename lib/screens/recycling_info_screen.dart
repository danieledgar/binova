// lib/screens/recycling_info_screen.dart
import 'package:flutter/material.dart';

class RecyclingInfoScreen extends StatelessWidget {
  const RecyclingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[50]
          : null,
      appBar: AppBar(
        title: const Text('Recycling Information'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.green.shade800
            : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [Colors.green.shade800, Colors.green.shade700]
                        : [Colors.green, const Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.recycling, size: 60, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Learn to Recycle Properly',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Reduce waste and help protect our environment',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recycling Categories Grid
            _buildCategoryCard(
              icon: Icons.restart_alt,
              title: 'Reduce and Reuse',
              color: Colors.blue,
              tips: [
                'Purchase products with minimal packaging',
                'Use reusable shopping bags and water bottles',
                'Donate usable items instead of discarding',
                'Repair items before replacing them',
              ],
            ),
            const SizedBox(height: 16),

            _buildCategoryCard(
              icon: Icons.recycling,
              title: 'Recycle',
              color: Colors.green,
              tips: [
                'Clean containers before recycling',
                'Separate materials according to local guidelines',
                'Check packaging for recycling symbols',
                'Remove caps and lids from bottles',
              ],
            ),
            const SizedBox(height: 16),

            _buildCategoryCard(
              icon: Icons.energy_savings_leaf,
              title: 'What You Can Do',
              color: Colors.teal,
              tips: [
                'Schedule regular recycling pickups',
                'Monitor bin fill levels through our app',
                'Report illegal dumping in your area',
                'Educate family and friends about recycling',
              ],
            ),
            const SizedBox(height: 16),

            _buildCategoryCard(
              icon: Icons.computer,
              title: 'Electronics and Batteries',
              color: Colors.indigo,
              tips: [
                'Schedule special pickups for electronics',
                'Use designated battery collection points',
                'Data wiping services available upon request',
                'Never throw electronics in regular trash',
              ],
            ),
            const SizedBox(height: 16),

            _buildCategoryCard(
              icon: Icons.restaurant,
              title: 'Food Waste',
              color: Colors.orange,
              tips: [
                'Use our food stock management tool',
                'Schedule organic waste collection',
                'Reduce excess food through inventory tracking',
                'Compost at home when possible',
              ],
            ),
            const SizedBox(height: 16),

            _buildCategoryCard(
              icon: Icons.weekend,
              title: 'Bulk Items',
              color: Colors.purple,
              tips: [
                'Schedule bulk item pickup service',
                'Disassemble large items when possible',
                'Special handling for mattresses and furniture',
                'Consider donation for usable furniture',
              ],
            ),
            const SizedBox(height: 24),

            // Local Guidelines Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Local Recycling Guidelines',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recycling regulations may vary by location. Our system is tailored to your area\'s specific requirements. Check your dashboard for personalized recycling schedules and guidelines.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Materials Reference Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Common Recyclable Materials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMaterialRow(
                      Icons.water_drop,
                      'Plastic',
                      'Bottles, containers, packaging',
                    ),
                    const Divider(),
                    _buildMaterialRow(
                      Icons.description,
                      'Paper',
                      'Newspapers, cardboard, magazines',
                    ),
                    const Divider(),
                    _buildMaterialRow(
                      Icons.wine_bar,
                      'Glass',
                      'Bottles, jars (clean and empty)',
                    ),
                    const Divider(),
                    _buildMaterialRow(
                      Icons.build,
                      'Metal',
                      'Cans, aluminum foil, scrap metal',
                    ),
                    const Divider(),
                    _buildMaterialRow(
                      Icons.devices,
                      'Electronics',
                      'Phones, computers, appliances',
                    ),
                    const Divider(),
                    _buildMaterialRow(
                      Icons.eco,
                      'Organic',
                      'Food waste, yard trimmings',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> tips,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialRow(IconData icon, String material, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
