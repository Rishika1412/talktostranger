import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talktostranger/views/auth_view.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'bloc/auth_bloc.dart';
import 'firebase_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  MobileAds.instance.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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


