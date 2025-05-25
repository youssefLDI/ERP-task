import 'package:erptask/features/auth/domain/entities/app_user.dart';

abstract class AuthState {}

// initial
class AuthInitial extends AuthState {}

//loading
class AuthLoading extends AuthState {}

//authnticated
class Authnticated extends AuthState {
  final AppUser user;
  Authnticated(this.user);
}

//unauthnticated
class Unauthenticated extends AuthState {}

//errors
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
