import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../blocs/table/table_cubit.dart';
import '../db/db_helper.dart';
import '../models/restaurant_table_model.dart';
import '../widgets/app_theme.dart';
import '../widgets/table_grid_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool hasOrdered = false;
  bool loadingOrderState = true;
  RestaurantTable? myTable;
  late TableCubit tableCubit;
  late StreamSubscription<String> _toastSub;

  @override
  void initState() {
    super.initState();
    tableCubit = TableCubit(DbHelper.instance);
    _toastSub = tableCubit.actionStream.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accent,
            content: Text(message, style: const TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _loadOrderState();
  }

  Future<void> _loadOrderState() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoaded) return;

    final userId = authState.user.id;
    final table = await DbHelper.instance.getUserBookedTable(userId);
    if (!mounted) return;

    final ordered = table != null &&
        (await DbHelper.instance.getLatestOrderForUser(userId))?.isCompleted ==
            false;

    setState(() {
      hasOrdered = ordered;
      myTable = table;
      loadingOrderState = false;
    });
  }

  @override
  void dispose() {
    _toastSub.cancel();
    tableCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthLoaded || loadingOrderState) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userId = authState.user.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${authState.user.name}'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset All Data',
            onPressed: () async {
              await DbHelper.instance.resetData();
              if (mounted) {
                setState(() => loadingOrderState = true);
                await _loadOrderState();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: BlocProvider<TableCubit>(
        create: (_) => tableCubit..fetchTables(showLoading: true),
        child: BlocBuilder<TableCubit, TableState>(
          builder: (context, state) {
            if (state is TableLoading || state is TableInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TableLoaded) {
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TableGridView(
                        tables: state.tables,
                        userId: userId,
                        onTableTap: (table) async {
                          final isMine = table.bookedByUserId == userId;

                          if (table.isBooked && !isMine) return;

                          if (isMine) {
                            await tableCubit.unbookTable(table.id, userId);
                          } else {
                            await tableCubit.bookTable(table.id, userId);
                          }

                          if (mounted) await _loadOrderState();
                        },
                      ),
                    ),
                  ),
                  if (myTable != null)
                    Container(
                      width: double.infinity,
                      color: AppTheme.background,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!hasOrdered)
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.pushNamed(context, '/menu');
                                if (mounted) _loadOrderState();
                              },
                              icon: const Icon(Icons.restaurant_menu, size: 20),
                              label: const Text("Order Food",
                                  style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            )
                          else ...[
                            const Text(
                              "You have an active order. You can add more items or complete the order.",
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.pushNamed(context, '/menu');
                                if (mounted) _loadOrderState();
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text("Add More Items",
                                  style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Complete Order?"),
                                    content: const Text(
                                        "Are you sure you want to complete this order and release the table?"),
                                    actions: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppTheme.primary,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                              ),
                                              child: const Text("Confirm"),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.grey[300],
                                                foregroundColor: Colors.black87,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                              ),
                                              child: const Text("Cancel"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return;

                                final order = await DbHelper.instance
                                    .getLatestOrderForUser(userId);
                                if (order != null && !order.isCompleted) {
                                  await DbHelper.instance
                                      .markOrderCompleted(order.id!);
                                  await DbHelper.instance
                                      .unbookTable(order.tableId);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Order completed. Table unbooked."),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    await _loadOrderState();
                                    tableCubit.fetchTables(showLoading: false);
                                  }
                                }
                              },
                              icon: const Icon(Icons.done_all, size: 20),
                              label: const Text("Complete Order",
                                  style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size.fromHeight(40),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/history');
                            },
                            icon: const Icon(Icons.history, size: 20),
                            label: const Text("Order History",
                                style: TextStyle(fontSize: 14)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            } else {
              return const Center(child: Text('No tables available.'));
            }
          },
        ),
      ),
    );
  }
}
