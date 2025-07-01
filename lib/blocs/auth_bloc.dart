import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthLoaded extends AuthState {
  final User user;
  AuthLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final UserRepository userRepository;

  AuthCubit(this.userRepository) : super(AuthInitial());

  Future<void> login(String name, String password) async {
    emit(AuthLoading());
    final user = await userRepository.getUserByUsername(name);

    if (user == null) {
      emit(AuthFailure("User not found. Please register."));
    } else if (user.password != password) {
      emit(AuthFailure("Invalid credentials. Please try again."));
    } else {
      emit(AuthLoaded(user));
    }
  }

  Future<bool> register(String name, String password) async {
    emit(AuthLoading());
    final success = await userRepository.register(name, password);
    if (success) {
      emit(AuthInitial()); // Go back to login screen
      return true;
    }
    emit(AuthFailure("Username already exists."));
    return false;
  }
}
