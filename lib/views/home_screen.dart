import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talktostranger/bloc/auth_bloc.dart';
import 'package:talktostranger/event/auth_event.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${user.displayName}!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
              BlocProvider.of<AuthBloc>(context).add(SignOutEvent());
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}