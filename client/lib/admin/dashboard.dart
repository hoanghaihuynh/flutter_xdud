import 'package:flutter/material.dart';
import 'package:myproject/admin/screen/cart_management_screen.dart';
import 'package:myproject/admin/screen/order_management_screen.dart';
import 'package:myproject/admin/screen/product_management_screen.dart';
import 'package:myproject/admin/screen/user_management_screen.dart';
import 'package:myproject/admin/screen/topping_management_screen.dart';
import 'package:myproject/admin/screen/voucher_management_screen.dart';
import 'package:myproject/screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AdminDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildDashboardCard(
              context,
              Icons.people,
              'User Management',
              Colors.blue,
              () {
                // Điều hướng đến UserManagementScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserManagementScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              Icons.local_pizza,
              'Product Management',
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProductManagementScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              Icons.receipt,
              'Order Management',
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderManagementScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              Icons.add_circle_outline,
              'Topping Management',
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ToppingManagementScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              Icons.shopping_cart,
              'Cart Management',
              Colors.teal,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CartManagementScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              Icons.discount,
              'Voucher Management',
              Colors.pink,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VoucherManagementScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $pageName'),
        duration: const Duration(milliseconds: 500),
      ),
    );
    // Replace with actual navigation when pages are created
    // Navigator.push(context, MaterialPageRoute(builder: (context) => Page()));
  }
}
