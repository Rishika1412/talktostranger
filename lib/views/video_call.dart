import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';
import '../services/video_call_manager.dart';

class VideoCall extends StatefulWidget {
  final String username, target;
  final bool caller;
  VideoCall(
      {required this.username, required this.target, required this.caller});
  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> with WidgetsBindingObserver {
  List<Widget> messages = [Text("NO LOGS")];
  bool setAccept = false;
  bool isConnected = false;
  VideoCallManager? _videoCallManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoCallManager = VideoCallManager(onDataReceived: _handleData);
    _videoCallManager!
        .initWebRTC(widget.username, widget.target)
        .then((value) => _videoCallManager!.init(widget.username))
        .then((value) => widget.caller
            ? _startCall()
            : Future.delayed(Duration(seconds: 3), () {
                _startCall();
              }));
  }

  void _handleData(String data) {
    setState(() {
      messages.add(Text(data));
    });
    final message = json.decode(data);
    switch (message['type']) {
      case 'call_response':
        _videoCallManager!.updateTargetUser("a");
        if (message['data'] == "user is ready for call") {
          _videoCallManager!.createOffer(widget.username, widget.target);
        }
        break;
      case 'offer_received':
        print("Offer Recieved ${(message['data'])}");
        setState(() {
          setAccept = true;
        });

        _videoCallManager!
            .handleOffer(message['data'], widget.username, message['name']);
        break;
      case 'answer_received':
        _videoCallManager!.handleAnswer(message['data']);
        break;
      case 'ice_candidate':
        _videoCallManager!.handleIceCandidate(message['data']);
        break;
      case 'call_ended':
        deleteDB();
        endCallUser();
        _videoCallManager!.dispose();
        Navigator.pop(context);

        break;
      default:
        break;
    }
  }

  deleteDB() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Define the data to be added to the document
    String deleteCollection = widget.caller ? "accepted" : "calling";

    // Add the document to the "calling" collection
    await firestore
        .collection(deleteCollection)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .delete();
  }

  void _endCall() {
    deleteDB();
    endCallUser();
    _videoCallManager!.endCall(widget.username, widget.target);

    _videoCallManager!.dispose();
    Navigator.pop(context);
  }

  void _mute() {
    _videoCallManager!.toggleAudioMute();
    setState(() {});
  }

  Future<void> inCallUser() async {
    try {
      // Access the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Define the data to be added to the document
      Map<String, dynamic> callingData = {
        'id': FirebaseAuth.instance.currentUser!
            .uid, // Replace with actual caller information
        'incall': true
      };

      // Add the document to the "calling" collection
      await firestore
          .collection('activeUser')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update(callingData);

      print('Document added to "activeUser" collection successfully');
    } catch (e) {
      print('Error adding document to "activeUser" collection: $e');
    }
  }

  Future<void> endCallUser() async {
    try {
      // Access the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Define the data to be added to the document
      Map<String, dynamic> callingData = {
        'id': FirebaseAuth.instance.currentUser!
            .uid, // Replace with actual caller information
        'incall': false
      };

      // Add the document to the "calling" collection
      await firestore
          .collection('activeUser')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update(callingData);

      print('Document added to "activeUser" collection successfully');
    } catch (e) {
      print('Error adding document to "activeUser" collection: $e');
    }
  }

  void _startCall() {
    _videoCallManager!.startCall(widget.username, widget.target);
    inCallUser();
    setState(() {
      isConnected = true;
    });
  }

  void _flipcamera() {
    _videoCallManager!.switchCamera();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: <Widget>[
          Row(
            children: [
              if (_videoCallManager!.remoteRenderer != null)
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: RTCVideoView(_videoCallManager!.remoteRenderer),
                )
              else
                Text('No Remote Video'),
            ],
          ),
          if (_videoCallManager!.localRenderer != null)
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.08,
              child: ClipRRect(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                        color: Colors.white,
                        width: 2.0), // Add a border for visibility
                  ),
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: MediaQuery.of(context).size.height * 0.24,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: RTCVideoView(_videoCallManager!.localRenderer)),
                ),
              ),
            )
          else
            Text('No Camera Video'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.08,
                width: MediaQuery.of(context).size.width,
                color: Colors.blueGrey,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: _flipcamera,
                      child: Icon(
                        _videoCallManager!.isFrontCamera
                            ? Icons.camera_front
                            : Icons.camera_rear_outlined,
                        color: Colors.grey,
                      ),
                    ),
                    FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: _startCall,
                      child: Icon(
                        Icons.video_call,
                        color: Colors.grey,
                      ),
                    ),
                    FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: _mute,
                      child: Icon(
                        _videoCallManager!.isAudioMuted
                            ? Icons.mic_off
                            : Icons.mic,
                        color: Colors.grey,
                      ),
                    ),
                    FloatingActionButton(
                      backgroundColor: Colors.red,
                      onPressed: _endCall,
                      child: Icon(Icons.call_end),
                    ),
                  ],
                ),
              ),
            ],
          ),
          isConnected
              ? SizedBox()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                      ],
                    ),
                  ],
                )
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Remove the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    // Call the deleteDB function when the app is terminated
    deleteDB();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This method is called when the app's lifecycle state changes
    if (state == AppLifecycleState.paused) {
      // The app is being paused, you can call deleteDB or perform other tasks
      deleteDB();
    }
    if (state == AppLifecycleState.detached) {
      deleteDB();
    }
  }
}
