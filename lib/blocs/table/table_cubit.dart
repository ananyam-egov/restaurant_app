import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/restaurant_table_model.dart';
import '../../repositories/db/db_helper.dart';

/// STATES

abstract class TableState extends Equatable {
  const TableState();

  @override
  List<Object?> get props => [];
}

class TableInitial extends TableState {}

class TableLoading extends TableState {}

class TableLoaded extends TableState {
  final List<RestaurantTable> tables;

  const TableLoaded(this.tables);

  @override
  List<Object?> get props => [tables];
}

/// CUBIT

class TableCubit extends Cubit<TableState> {
  final DbHelper dbHelper;
  final StreamController<String> _actionController = StreamController<String>.broadcast();

  TableCubit(this.dbHelper) : super(TableInitial());

  Stream<String> get actionStream => _actionController.stream;

  Future<void> fetchTables({bool showLoading = false}) async {
    if (showLoading) emit(TableLoading());
    final tables = await dbHelper.getTables();
    emit(TableLoaded(tables));
  }

  Future<void> bookTable(int tableId, String userId) async {
    final userBooked = await dbHelper.getUserBookedTable(userId);

    if (userBooked != null) {
      final hasOrdered = await dbHelper.hasPlacedOrder(userId, userBooked.id);
      if (hasOrdered) {
        _actionController.add('You have already placed an order. You cannot book a new table.');
        return;
      }

      _actionController.add('You have already booked ${userBooked.name}');
      return;
    }

    final current = state;
    if (current is! TableLoaded) return;

    final table = current.tables.firstWhere((t) => t.id == tableId);
    if (table.isBooked) {
      _actionController.add('Table already booked.');
      return;
    }

    await dbHelper.bookTable(tableId, userId);
    await fetchTables(); // silent refresh without loading state
  }

  Future<void> unbookTable(int tableId, String userId) async {
    final current = state;
    if (current is! TableLoaded) return;

    final table = current.tables.firstWhere((t) => t.id == tableId);
    if (table.bookedByUserId != userId) {
      _actionController.add('You can only cancel your own bookings.');
      return;
    }

    final hasOrdered = await dbHelper.hasPlacedOrder(userId, tableId);
    if (hasOrdered) {
      _actionController.add('Cannot unbook. You have already placed an order for this table.');
      return;
    }

    await dbHelper.unbookTable(tableId);
    await fetchTables();
  }

  @override
  Future<void> close() {
    _actionController.close();
    return super.close();
  }
}
