import 'package:flutter/material.dart';

class DistributorScreen extends StatelessWidget {
    const DistributorScreen({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Distributor Home'),
                elevation: 0,
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            'Welcome, Distributor',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        _buildDashboardGrid(),
                        const SizedBox(height: 24),
                        const Text(
                            'Recent Orders',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildRecentOrdersList(),
                    ],
                ),
            ),
        );
    }

    Widget _buildDashboardGrid() {
        return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
                _buildDashboardCard('Total Orders', '1,234', Colors.blue),
                _buildDashboardCard('Pending', '45', Colors.orange),
                _buildDashboardCard('Completed', '1,189', Colors.green),
                _buildDashboardCard('Revenue', '\$45,000', Colors.purple),
            ],
        );
    }

    Widget _buildDashboardCard(String title, String value, Color color) {
        return Card(
            child: Container(
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text(title, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                            value,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _buildRecentOrdersList() {
        return ListView.builder(
            itemCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
                return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                        title: Text('Order #${1000 + index}'),
                        subtitle: const Text('Pending'),
                        trailing: const Text('\$299.99'),
                    ),
                );
            },
        );
    }
}