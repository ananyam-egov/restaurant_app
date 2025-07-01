import 'package:flutter/material.dart';
import '../models/restaurant_table_model.dart';

class TableGridView extends StatelessWidget {
  final List<RestaurantTable> tables;
  final String userId;
  final void Function(RestaurantTable table) onTableTap;

  const TableGridView({
    super.key,
    required this.tables,
    required this.userId,
    required this.onTableTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final isMine = table.bookedByUserId == userId;

        final color = isMine
            ? Colors.green
            : table.isBooked
                ? Colors.grey.shade600
                : Colors.orange;

        final label = isMine
            ? 'Booked by You'
            : table.isBooked
                ? 'Booked'
                : 'Available';

        return GestureDetector(
          onTap: () => onTableTap(table),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(2, 4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table.name,
                    style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
