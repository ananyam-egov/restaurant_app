import 'app_db.dart';
import '../../models/restaurant_table_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/order_model.dart';
import '../../models/order_item_model.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  final dbFuture = AppDatabase.instance.database;

  DbHelper._init();

  Future<List<RestaurantTable>> getTables() async {
    final db = await dbFuture;
    final result = await db.query('restaurant_tables');
    return result.map((e) => RestaurantTable.fromMap(e)).toList();
  }

  Future<List<MenuItem>> getMenuItems() async {
    final db = await dbFuture;
    final result = await db.query('menu_items');
    return result.map((e) => MenuItem.fromMap(e)).toList();
  }
Future<int> placeOrder(Order order, List<OrderItem> items) async {
  final db = await dbFuture;

  int orderId;

  if (order.id == null) {
    // Insert new order
    final orderMap = order.toMap()..remove('id');
    orderId = await db.insert('orders', orderMap);
  } else {
    // Reuse existing order ID
    orderId = order.id!;

    // 🔁 Clear old items before inserting updated ones
    await db.delete(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
  }

  // Insert fresh order items
  for (final item in items) {
    await db.insert('order_items', {
      'orderId': orderId,
      'menuItemId': item.menuItemId,
      'quantity': item.quantity,
    });
  }

  return orderId;
}



  Future<void> bookTable(int tableId, String userId) async {
    final db = await dbFuture;
    await db.update(
      'restaurant_tables',
      {'isBooked': 1, 'bookedByUserId': userId},
      where: 'id = ? AND isBooked = 0',
      whereArgs: [tableId],
    );
  }

  Future<void> unbookTable(int tableId) async {
    final db = await dbFuture;
    await db.update(
      'restaurant_tables',
      {'isBooked': 0, 'bookedByUserId': null},
      where: 'id = ?',
      whereArgs: [tableId],
    );
  }

  Future<RestaurantTable?> getUserBookedTable(String userId) async {
    final db = await dbFuture;
    final result = await db.query(
      'restaurant_tables',
      where: 'bookedByUserId = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) return null;
    return RestaurantTable.fromMap(result.first);
  }

  Future<List<Order>> getOrdersForUser(String userId) async {
    final db = await dbFuture;
    final result = await db.query(
      'orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return result.map((e) => Order.fromMap(e)).toList();
  }

  Future<List<Order>> getUserOrders(String userId, {bool past = false}) async {
    final db = await dbFuture;
    final result = await db.query(
      'orders',
      where: 'userId = ? AND isCompleted = ?',
      whereArgs: [userId, past ? 1 : 0],
      orderBy: 'timestamp DESC',
    );
    return result.map((e) => Order.fromMap(e)).toList();
  }

  Future<Order?> getLatestOrderForUser(String userId) async {
    final db = await dbFuture;
    final result = await db.query(
      'orders',
      where: 'userId = ? AND isCompleted = 0',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Order.fromMap(result.first);
    }
    return null;
  }

  Future<void> markOrderCompleted(int orderId) async {
    final db = await dbFuture;
    await db.update(
      'orders',
      {'isCompleted': 1},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

 Future<bool> hasPlacedOrder(String userId, int tableId) async {
  final db = await dbFuture;
  final result = await db.query(
    'orders',
    where: 'userId = ? AND tableId = ? AND isCompleted = 0',
    whereArgs: [userId, tableId],
    limit: 1,
  );
  return result.isNotEmpty;
}


  Future<List<Map<String, dynamic>>> getOrderHistory(String userId, {bool onlyCompleted = false}) async {
  final db = await dbFuture;
  return await db.rawQuery('''
    SELECT o.id AS orderId, o.timestamp, o.tableId, mi.name AS itemName,
           mi.price, oi.quantity, o.isCompleted
    FROM orders o
    JOIN order_items oi ON o.id = oi.orderId
    JOIN menu_items mi ON oi.menuItemId = mi.id
    WHERE o.userId = ? ${onlyCompleted ? 'AND o.isCompleted = 1' : 'AND o.isCompleted = 0'}
    ORDER BY o.timestamp DESC
  ''', [userId]);
}


  Future<void> resetData() async {
    final db = await dbFuture;
    await db.delete('orders');
    await db.delete('order_items');
    await db.update('restaurant_tables', {'isBooked': 0, 'bookedByUserId': null});
  }
  Future<void> completeOrderAndUnbook(int orderId, int tableId) async {
  final db = await dbFuture;
  await db.transaction((txn) async {
    await txn.update(
      'orders',
      {'isCompleted': 1},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    await txn.update(
      'restaurant_tables',
      {'isBooked': 0, 'bookedByUserId': null},
      where: 'id = ?',
      whereArgs: [tableId],
    );
  });
}
Future<int> insertOrder(Order order) async {
  final db = await dbFuture;
  return await db.insert('orders', order.toMap());
}

Future<void> insertOrderItems(int orderId, List<OrderItem> items) async {
  final db = await dbFuture;

  for (final item in items) {
    // Check if item already exists
    final existing = await db.query(
      'order_items',
      where: 'orderId = ? AND menuItemId = ?',
      whereArgs: [orderId, item.menuItemId],
    );

    if (existing.isNotEmpty) {
      final currentQty = existing.first['quantity'] as int;
      await db.update(
        'order_items',
        {'quantity': currentQty + item.quantity},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('order_items', {
        'orderId': orderId,
        'menuItemId': item.menuItemId,
        'quantity': item.quantity,
      });
    }
  }
}
Future<List<Map<String, dynamic>>> getItemsForOrder(int orderId) async {
  final db = await dbFuture;
  final result = await db.rawQuery('''
    SELECT mi.name AS itemName, mi.price, oi.quantity
    FROM order_items oi
    JOIN menu_items mi ON mi.id = oi.menuItemId
    WHERE oi.orderId = ?
  ''', [orderId]);
  return result;
}


}
