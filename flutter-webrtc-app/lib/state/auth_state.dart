import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthSignedInState extends AuthState {
  final User user;

  AuthSignedInState(this.user);
}

class AuthNotAuthenticatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String error;

  AuthErrorState(this.error);
}

class AuthLoadingState extends AuthState {}
