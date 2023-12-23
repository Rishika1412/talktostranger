import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talktostranger/bloc/auth_bloc.dart';
import 'package:talktostranger/event/auth_event.dart';
import 'package:talktostranger/state/auth_state.dart';
import 'package:talktostranger/views/home_screen.dart';
import 'package:talktostranger/views/update_screen.dart';

import 'login_screen.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> with WidgetsBindingObserver {
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<AuthBloc>(context).add(CheckAuthenticationStatusEvent());
    WidgetsBinding.instance.addObserver(this);

    // Subscribe to connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
          setState(() {
            _connectivityResult = result;
          });
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }
  Future<void> updateStatus(bool active) async {
    try {
      // Get the current user's ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Reference to the user's document
      DocumentReference userRef =
      FirebaseFirestore.instance.collection('activeUser').doc(userId);
      DocumentSnapshot previousNumber = await userRef.get();

      await userRef
          .update({'online': active});
    } catch (e) {
      print('Error updating number of cards: $e');
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print(state);

    switch (state) {
      case AppLifecycleState.resumed:
      // App is in the foreground
        updateStatus(true);
        break;
      case AppLifecycleState.inactive:
        updateStatus(false);

        // App is in an inactive state (e.g., in a phone call)
        break;
      case AppLifecycleState.paused:
        updateStatus(false);
      // App is in the background
        break;
      case AppLifecycleState.detached:
        updateStatus(false);
      // App is terminated
        break;
      case AppLifecycleState.hidden:
        //updateStatus(false);
        // TODO: Handle this case.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSignedInState) {
          
          return HomePage(user: state.user);
        } else if (state is AuthNotAuthenticatedState) {
         
          return GoogleLogin();
        } else if (state is NotUpdatedState) {

          return UpdateScreen();
        }  else if (state is AuthErrorState) {
          
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
