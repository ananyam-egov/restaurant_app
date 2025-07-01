import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../repositories/db/db_helper.dart';

class CurrentOrderPage extends StatefulWidget {
  const CurrentOrderPage({super.key});

  @override
  State<CurrentOrderPage> createState() => _CurrentOrderPageState();
}

class _CurrentOrderPageState extends State<CurrentOrderPage> {
  late String userId;
  List<Map<String, dynamic>> items = [];
  int? orderId;
  int? tableId;
  String? tableName;
  bool isCompleted = false;
  bool loading = true;
  Map<String, dynamic>? lastDeletedItem;

  @override
  void initState() {
    super.initState();
    userId = (context.read<AuthCubit>().state as AuthLoaded).user.id;
    _load();
  }

  Future<void> _load() async {
    final fullData = await DbHelper.instance.getOrderHistory(userId);
    final active = fullData.where((e) => e['isCompleted'] == 0).toList();

    if (active.isEmpty) {
      setState(() {
        items = [];
        loading = false;
      });
      return;
    }

    final first = active.first;
    setState(() {
      items = active;
      orderId = first['orderId'];
      tableId = first['tableId'];
      tableName = "Table ${first['tableId']}";
      isCompleted = first['isCompleted'] == 1;
      loading = false;
    });
  }

  Future<void> _updateQuantity(int menuItemId, int newQty) async {
    if (orderId == null || isCompleted) return;

    final db = await DbHelper.instance.dbFuture;

    if (newQty <= 0) {
      final itemToDelete = items.firstWhere((e) => e['menuItemId'] == menuItemId);
      setState(() {
        lastDeletedItem = itemToDelete;
      });

      await db.delete(
        'order_items',
        where: 'orderId = ? AND menuItemId = ?',
        whereArgs: [orderId, menuItemId],
      );

      _load();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              if (lastDeletedItem != null) {
                await db.insert('order_items', {
                  'orderId': orderId,
                  'menuItemId': lastDeletedItem!['menuItemId'],
                  'quantity': lastDeletedItem!['quantity'],
                });
                _load();
              }
            },
          ),
        ),
      );
    } else {
      await db.update(
        'order_items',
        {'quantity': newQty},
        where: 'orderId = ? AND menuItemId = ?',
        whereArgs: [orderId, menuItemId],
      );
      _load();
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (final item in items) {
      final price = item['price'] ?? 0.0;
      final qty = item['quantity'] ?? 0;
      total += price * qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Current Order")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text("No active order found."))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Table: $tableName",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(item['itemName']),
                              subtitle: Text("₹${(item['price'] as num).toStringAsFixed(2)}"),
                              trailing: isCompleted
                                  ? Text("x${item['quantity']}")
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () => _updateQuantity(item['menuItemId'], item['quantity'] - 1),
                                        ),
                                        Text('${item['quantity']}'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () => _updateQuantity(item['menuItemId'], item['quantity'] + 1),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Total: ₹${_calculateTotal().toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
    );
  }
}
