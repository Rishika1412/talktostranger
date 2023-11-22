import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

class VideoCallManager {
  final Function(String) onDataReceived;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  IOWebSocketChannel _channel;
  bool isAudioMuted = false;
  bool isFrontCamera =true;
  bool isConnecting =false;
  VideoCallManager({required this.onDataReceived})
      : _peerConnection = null,
        _localStream = null,
        _channel = IOWebSocketChannel.connect(
            'wss://www.machineyantra.com:8443'); // Update with your server address
  String targetUser = "1";
  void updateTargetUser(String newTarget) {
    targetUser = newTarget;
  }

  Future<void> initWebRTC(String username, String target) async {
    await initLocalStream();
    initRemoteRenderer();
    await createPConnection();

    // Set up event listeners
    _peerConnection!.onTrack = (event) {
      remoteRenderer.srcObject = event.streams[0];
    };
    _peerConnection!.onIceCandidate = (candidate) {
      // Send ICE candidate to the other peer
      final iceCandidate = {
        "type": "ice_candidate",
        "name": username, // Replace with your username
        "target":target, // Replace with the target user's username
        "data": {
          "sdpMid": candidate.sdpMid,
          "sdpMLineIndex": candidate.sdpMLineIndex,
          "candidate": candidate.candidate
        }
      };
      print("ICE ${iceCandidate}");
      _channel.sink.add(jsonEncode(iceCandidate));
    };

    // Handle incoming messages from the server
    _channel.stream.listen((data) {
      onDataReceived(data);
      final message = json.decode(data);
      switch (message['type']) {
        case 'create_offer':
          // Handle incoming offer
          handleOffer(message['data'],message['name'],message['target']);
          break;
        case 'create_answer':
          // Handle incoming answer
          handleAnswer(message['data']);
          break;
        case 'ice_candidate':
          // Handle incoming ICE candidate
          handleIceCandidate(message['data']);
          break;
        default:
          // Handle other message types
          break;
      }
    });
  }

  Future<void> initLocalStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});

    // Ensure that the RTCVideoRenderer is properly initialized before setting the stream
    await localRenderer.initialize();
    localRenderer.srcObject = _localStream;
  }

  void initRemoteRenderer() async {
    await remoteRenderer.initialize();
    await localRenderer.initialize();
  }

  Future<void> createPConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'url': 'stun:stun.l.google.com:19302'
        }, // You can add your own TURN/STUN servers here
      ],
    };
    _peerConnection = await createPeerConnection(configuration, {});
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  void handleOffer(String offer,String username,String target) async {
    print("Working ${offer}");
    await _peerConnection!
        .setRemoteDescription(RTCSessionDescription(offer, 'offer'));
    final answer = await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);
    print("Working 2");
    final answerMessage = {
      "type": "create_answer",
      "name": username, // Replace with your username
      "target": target, // Replace with the target user's username
      "data": {"sdp": answer.sdp}
    };
    _channel.sink.add(jsonEncode(answerMessage));
  }

  void handleAnswer(String answer) async {


    await _peerConnection!
        .setRemoteDescription(RTCSessionDescription(answer, 'answer'));

  }

  void handleIceCandidate(Map<String, dynamic> iceCandidate) {
    final candidate = RTCIceCandidate(
      iceCandidate['candidate'],
      iceCandidate['sdpMid'],
      iceCandidate['sdpMLineIndex'],
    );
    _peerConnection!.addCandidate(candidate);
  }

  void createOffer(String username,String target) async {
    final offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);
print(offer.sdp);
    final offerMessage = {
      "type": "create_offer",
      "name": username, // Replace with your username
      "target": target, // Replace with the target user's username
      "data": {"sdp": offer.sdp}
    };
    _channel.sink.add(jsonEncode(offerMessage));
  }

  void init(String username) {
    // Send an initiation message to the server
    final initMessage = {
      "type": "store_user",
      "name": username, // Replace with your username
      "target":null, // Replace with the target user's username
      "data": null
    };
    _channel.sink.add(jsonEncode(initMessage));
  }

  void startCall(String username,String target) {
    // Send a start call message to the server
    final startCallMessage = {
      "type": "start_call",
      "name": username, // Replace with your username
      "target":target, // Replace with the target user's username
      "data": null
    };
    _channel.sink.add(jsonEncode(startCallMessage));
  }


  Future<void> switchCamera() async {
    if (_localStream != null) {
      bool value = await _localStream!.getVideoTracks()[0].switchCamera();
      while (value == this.isFrontCamera)
        value = await _localStream!.getVideoTracks()[0].switchCamera();
      this.isFrontCamera = value;
    }
  }
  void endCall(String username,String target) {
    // Send an "end_call" message to the server
    final endCallMessage = {
      "type": "end_call",
      "name": username, // Replace with your username
      "target": target, // Replace with the target user's username
      "data": null
    };
    _channel.sink.add(jsonEncode(endCallMessage));
  }
  // Method to toggle mute/unmute audio
  Future<void> toggleAudioMute()async {
    if (_localStream != null) {

      if (!isAudioMuted) {
        Helper.setMicrophoneMute(true, _localStream!.getAudioTracks()[0]);
        isAudioMuted = true;
      } else {
        Helper.setMicrophoneMute(false, _localStream!.getAudioTracks()[0]);
        isAudioMuted = false;
      }
    }
  }



  void dispose() {
    _localStream?.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _peerConnection?.close();
    _channel.sink.close();
  }
}
