import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talktostranger/views/auth_view.dart';
import 'bloc/auth_bloc.dart';
import 'firebase_options.dart';


import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> checkAndRequestLocationPermission() async {
  var notificationStatus = await Permission.notification.status;

  if (!notificationStatus.isGranted) {
    var notificationResult = await Permission.notification.request();
    if (!notificationResult.isGranted) {}
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  checkAndRequestLocationPermission();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // initPlatformState();
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("9a5f0573-70fa-41b1-b1b0-a93dc64485e7");

  OneSignal.Notifications.requestPermission(true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (context) => AuthBloc(),
        child: const AuthenticationScreen(),
      ),
    );
  }
}
