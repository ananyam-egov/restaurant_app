import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../repositories/db/db_helper.dart';
import '../models/order_model.dart';
import '../widgets/app_theme.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late String userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthLoaded) {
      userId = authState.user.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order History'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
  labelColor: Colors.black,
  unselectedLabelColor: Colors.black54,
  indicatorColor: Colors.black,
  tabs: [
    Tab(text: 'Current Orders'),
    Tab(text: 'Past Orders'),
  ],
),

        ),
        body: TabBarView(
          children: [
            _buildOrderList(past: false),
            _buildOrderList(past: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList({required bool past}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DbHelper.instance.getOrderHistory(userId, onlyCompleted: past),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }

        // Group by orderId
        final Map<int, List<Map<String, dynamic>>> grouped = {};
        for (var row in data) {
          grouped.putIfAbsent(row['orderId'] as int, () => []).add(row);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final orderId = grouped.keys.elementAt(index);
            final items = grouped[orderId]!;
            final timestamp = DateTime.parse(items.first['timestamp']);
            final tableId = items.first['tableId'];
            double total = 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$orderId • Table $tableId',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Placed on: ${timestamp.toLocal().toString().split('.')[0]}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 24),
                  ...items.map((item) {
                    final name = item['itemName'];
                    final qty = item['quantity'] as int;
                    final unitPrice = item['price'] as double;
                    final lineTotal = qty * unitPrice;
                    total += lineTotal;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$name x$qty'),
                          Text('₹${lineTotal.toStringAsFixed(0)}'),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
