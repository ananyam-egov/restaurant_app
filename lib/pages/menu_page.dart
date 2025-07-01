import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../repositories/db/db_helper.dart';
import '../models/menu_item_model.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/restaurant_table_model.dart';
import '../widgets/app_theme.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final Map<int, int> quantities = {};
  List<MenuItem> menuItems = [];
  RestaurantTable? bookedTable;
  Order? currentOrder;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoaded) return;

    final userId = authState.user.id;
    final table = await DbHelper.instance.getUserBookedTable(userId);
    final items = await DbHelper.instance.getMenuItems();
    final existingOrder = await DbHelper.instance.getLatestOrderForUser(userId);

    final db = await DbHelper.instance.dbFuture;
    final prefill = <int, int>{};

    if (existingOrder != null && !existingOrder.isCompleted) {
      final existingItems = await db.query(
        'order_items',
        where: 'orderId = ?',
        whereArgs: [existingOrder.id],
      );
      for (final row in existingItems) {
        final itemId = row['menuItemId'] as int;
        final qty = row['quantity'] as int;
        prefill[itemId] = qty;
      }
    }

    if (!mounted) return;
    setState(() {
      bookedTable = table;
      menuItems = items;
      currentOrder = existingOrder;
      quantities.addAll(prefill);
      loading = false;
    });
  }

  void _placeOrder() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoaded) return;

    if (bookedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must book a table first.")),
      );
      return;
    }

    final userId = authState.user.id;

    final selectedItems = quantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => OrderItem(
              id: 0,
              orderId: 0,
              menuItemId: entry.key,
              quantity: entry.value,
            ))
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one item.")),
      );
      return;
    }

    final isNewOrder = currentOrder == null || currentOrder!.isCompleted;

    final order = Order(
      id: isNewOrder ? null : currentOrder!.id,
      userId: userId,
      tableId: bookedTable!.id,
      timestamp: DateTime.now(),
      isCompleted: false,
    );

    _showConfirmationDialog(order, selectedItems, menuItems);
  }

  void _showConfirmationDialog(
    Order order,
    List<OrderItem> selectedItems,
    List<MenuItem> menu,
  ) {
    final itemMap = {for (var item in menu) item.id: item};
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirm Order',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Table: ${bookedTable!.name}',
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ...selectedItems.map((item) {
                  final name =
                      menu.firstWhere((m) => m.id == item.menuItemId).name;
                  final price =
                      menu.firstWhere((m) => m.id == item.menuItemId).price;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$name x${item.quantity}'),
                        Text('₹${(price * item.quantity).toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Confirm Button (on the left)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await DbHelper.instance
                                .placeOrder(order, selectedItems);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Order placed successfully!")),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Order failed: $e")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("Confirm"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Cancel Button (on the right)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    double totalPrice = 0;
    int totalItems = 0;

    for (final entry in quantities.entries) {
      final item = menuItems.firstWhere((i) => i.id == entry.key);
      totalPrice += item.price * entry.value;
      totalItems += entry.value;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu"),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset Data',
            onPressed: () async {
              await DbHelper.instance.resetData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data reset successfully.")),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (bookedTable != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                "Booking: ${bookedTable!.name}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text(
                "No table booked. Please book a table to order.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: AppTheme.card,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text("₹${item.price.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () {
                                setState(() {
                                  quantities[item.id] =
                                      (quantities[item.id] ?? 0) - 1;
                                  if (quantities[item.id]! < 0)
                                    quantities[item.id] = 0;
                                });
                              },
                            ),
                            Text("${quantities[item.id] ?? 0}"),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () {
                                setState(() {
                                  quantities[item.id] =
                                      (quantities[item.id] ?? 0) + 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: ₹${totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  "$totalItems item${totalItems == 1 ? '' : 's'} selected",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _placeOrder,
              icon: const Icon(Icons.check),
              label: const Text("Place Order"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
