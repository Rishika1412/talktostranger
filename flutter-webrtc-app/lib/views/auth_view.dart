import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talktostranger/bloc/auth_bloc.dart';
import 'package:talktostranger/event/auth_event.dart';
import 'package:talktostranger/main.dart';
import 'package:talktostranger/state/auth_state.dart';
import 'package:talktostranger/views/home_screen.dart';

import 'login_screen.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<AuthBloc>(context).add(CheckAuthenticationStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSignedInState) {
          
          return HomePage(user: state.user);
        } else if (state is AuthNotAuthenticatedState) {
         
          return GoogleLogin();
        } else if (state is AuthErrorState) {
          
          return Center(
            child: Text('Error: ${state.error}'),
          );
        } else {
         
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class SignInButton extends StatelessWidget {
  const SignInButton({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(SignInWithGoogleEvent());
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
