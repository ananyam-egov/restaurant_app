class Order {
  final int? id; // nullable: only set after DB insert
  final String userId;
  final int tableId;
  final DateTime timestamp;
  final bool isCompleted;

  Order({
    this.id,
    required this.userId,
    required this.tableId,
    required this.timestamp,
    this.isCompleted = false,
  });

  factory Order.fromMap(Map<String, dynamic> map) => Order(
        id: map['id'],
        userId: map['userId'],
        tableId: map['tableId'],
        timestamp: DateTime.parse(map['timestamp']),
        isCompleted: (map['isCompleted'] ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id, // only included for updates
        'userId': userId,
        'tableId': tableId,
        'timestamp': timestamp.toIso8601String(),
        'isCompleted': isCompleted ? 1 : 0,
      };
}
