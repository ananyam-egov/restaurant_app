class RestaurantTable {
  final int id;
  final String name;
  final bool isBooked;
  final String? bookedByUserId;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.isBooked,
    this.bookedByUserId,
  });

  factory RestaurantTable.fromMap(Map<String, dynamic> map) {
    return RestaurantTable(
      id: map['id'],
      name: map['name'],
      isBooked: map['isBooked'] == 1,
      bookedByUserId: map['bookedByUserId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isBooked': isBooked ? 1 : 0,
      'bookedByUserId': bookedByUserId,
    };
  }
}
