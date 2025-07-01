import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/pages/current_order_page.dart';
import 'package:restaurant_app/pages/login_page.dart';
import 'package:restaurant_app/pages/menu_page.dart';
import 'package:restaurant_app/pages/order_history_page.dart';
import 'package:restaurant_app/pages/register_page.dart';
import 'package:restaurant_app/pages/home_page.dart';

import 'blocs/auth_bloc.dart';
import 'repositories/user_repository.dart';
import 'widgets/app_theme.dart';


void main() {
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(UserRepository()),
      child: MaterialApp(
        title: 'Restaurant App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme, // ✅ Apply the custom food theme here
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          '/register': (_) => const RegisterPage(),
          '/home': (context) => const HomePage(),
          '/menu': (context) => const MenuPage(),
          '/history': (_) => const OrderHistoryPage(),
          '/current-order': (context) => const CurrentOrderPage(),
        },
      ),
    );
  }
}
