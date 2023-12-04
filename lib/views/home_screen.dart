// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:talktostranger/bloc/auth_bloc.dart';
import 'package:talktostranger/event/auth_event.dart';
import 'package:http/http.dart' as http;
import 'video_call.dart';
import '../services/video_call_manager.dart';

class HomePage extends StatefulWidget {
  final User user;

  HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController targetController = TextEditingController();

  final StreamController<DocumentSnapshot<Map<String, dynamic>>>
      _userStreamController =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>();

  VideoCallManager? _videoCallManager;
  final CardSwiperController controller = CardSwiperController();
  int _numInterstitialLoadAttempts = 0;
  int _numRewardLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;
  int maxVideoFailedLoadAttempts = 3;
  int noOfCards = 3;
  bool isCalling = false;
  @override
  void initState() {
    super.initState();
    activateUser();
    _createInterstitialAd();
    _createRewardedAd();
    //OneSignal.User.addTagWithKey("id", FirebaseAuth.instance.currentUser!.uid);

    //  _usernameController.text = FirebaseAuth.instance.currentUser!.uid;
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print("Some ${event.notification.rawPayload!['custom']}");
      Map<String, dynamic> jsonData =
          json.decode(event.notification.rawPayload!['custom']);

      String keyI = jsonData['i'];
      String keyAId = jsonData['a']['id'];

      print("Key 'i': $keyI");
      print("Key 'a' -> 'id': $keyAId");
      if (mounted)
        setState(() {
          targetController.text = keyAId;
        });
    });
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      // Access Firestore and set up a stream for the current user's data
      FirebaseFirestore.instance
          .collection('activeUser')
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        snapshot.docs.forEach((DocumentSnapshot document) {
          Map<String, dynamic> data = document.data() as Map<String, dynamic>;

          // Access fields from the document
          String userId = document.id;

          // Print or use the data as needed
        });
        if (mounted)
          setState(() {
            // Update your UI or perform any other necessary actions
          });
      });
    });
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Access Firestore and set up a stream for the current user's data
        FirebaseFirestore.instance
            .collection('calling') // Adjust the collection name accordingly
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          // print(snapshot.data());

          _userStreamController.add(snapshot);
          if (mounted) setState(() {});
        });
      }
    });
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Access Firestore and set up a stream for the current user's data
        FirebaseFirestore.instance
            .collection('accepted') // Adjust the collection name accordingly
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          print("Accepted");
          if (snapshot.data() != null) {
            print(snapshot.data()!['caller']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoCall(
                  username: FirebaseAuth.instance.currentUser!.uid,
                  target: snapshot.data()!['caller'],
                  caller: true,
                ),
              ),
            );
          }
          if (mounted) setState(() {});
        });
      }
    });
  }

  static final AdRequest request = const AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );
  @override
  void dispose() {
    // Close the StreamController when the widget is disposed
    _userStreamController.close();
    super.dispose();
  }

  Future<void> addDocumentToCallingCollection(
      String targetUSER, String Caller) async {
    try {
      // Access the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Define the data to be added to the document
      Map<String, dynamic> callingData = {
        'caller': Caller, // Replace with actual caller information
        'callee': targetUSER, // Replace with actual callee information
        'timestamp': FieldValue.serverTimestamp(),
        //  'incall': false
      };

      // Add the document to the "calling" collection
      await firestore.collection('calling').doc(targetUSER).set(callingData);
    } catch (e) {}
  }

  Future<void> activateUser() async {
    try {
      // Access the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Define the data to be added to the document
      Map<String, dynamic> callingData = {
        'id': FirebaseAuth.instance.currentUser!
            .uid, // Replace with actual caller information
        'incall': false,
        'imgurl': FirebaseAuth.instance.currentUser!.photoURL
      };

      // Add the document to the "calling" collection
      await firestore
          .collection('activeUser')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set(callingData);

      print('Document added to "activeUser" collection successfully');
    } catch (e) {
      print('Error adding document to "activeUser" collection: $e');
    }
  }

  Future<void> acceptDocumentToCallingCollection(
      String targetUSER, String Caller) async {
    try {
      // Access the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Define the data to be added to the document
      Map<String, dynamic> callingData = {
        'caller': Caller, // Replace with actual caller information
        'callee': targetUSER, // Replace with actual callee information
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add the document to the "calling" collection
      await firestore.collection('accepted').doc(targetUSER).set(callingData);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCall(
            username: FirebaseAuth.instance.currentUser!.uid,
            target: targetUSER,
            caller: false,
          ),
        ),
      );
      print('Document added to "calling" collection successfully');
    } catch (e) {
      print('Error adding document to "calling" collection: $e');
    }
  }

  Future<void> deleteDocumentToCallingCollection(
      String targetUSER, String Caller) async {
    try {
      // Access the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Add the document to the "calling" collection
      await firestore.collection('calling').doc(targetUSER).delete();

      print('Document added to "calling" collection successfully');
    } catch (e) {
      print('Error adding document to "calling" collection: $e');
    }
  }

  void sendOneSignalNotification() async {
    String apiUrl = 'https://onesignal.com/api/v1/notifications';
    String apiKey =
        'ZWVkYjQ1OTEtMDM4OS00ZjJmLTljN2UtZDdhOTVhMGQxZGU5'; // Replace with your OneSignal REST API Key

    Map<String, dynamic> payload = {
      "app_id": "9a5f0573-70fa-41b1-b1b0-a93dc64485e7",
      "filters": [
        {
          "field": "tag",
          "key": "id",
          "relation": "=",
          "value": "ZP6i1GJpvcUC8TQY2NO0Zwo4v4d2"
        },
      ],
      "data": {"id": FirebaseAuth.instance.currentUser!.uid},
      "contents": {"en": "English Message"}
    };

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $apiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print(
            'Failed to send notification. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error sending notification: $error');
    }
  }

  InterstitialAd? _interstitialAd;
  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910',
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
            //   _showInterstitialAd();
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              _createInterstitialAd();
            }
          },
        ));
  }

  void _showInterstitialAd(String userName) {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          addDocumentToCallingCollection(
              userName.toString(), FirebaseAuth.instance.currentUser!.uid),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        addDocumentToCallingCollection(
            userName.toString(), FirebaseAuth.instance.currentUser!.uid);
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        addDocumentToCallingCollection(
            userName.toString(), FirebaseAuth.instance.currentUser!.uid);
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  RewardedAd? _rewardedAd;

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313',
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _numRewardLoadAttempts = 0;
          _rewardedAd!.setImmersiveMode(true);
          print('Rewarded video ad loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Rewarded video ad failed to load: $error');
          _numRewardLoadAttempts += 1;
          _rewardedAd = null;
          if (_numRewardLoadAttempts < maxVideoFailedLoadAttempts) {
            _createRewardedAd();
          }
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      print('Warning: attempt to show rewarded ad before loaded.');
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('Ad showed fullscreen content.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('Ad dismissed fullscreen content.');
        ad.dispose();
        _createRewardedAd(); // Load a new rewarded ad after it's dismissed
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('Ad failed to show fullscreen content: $error');
        ad.dispose();
        _createRewardedAd(); // Load a new rewarded ad after failure
      },
      onAdImpression: (RewardedAd ad) => print('Ad impression.'),
    );

    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      setState(() {
        noOfCards = noOfCards + 3;
      });
    });
    _rewardedAd = null; // Set to null to prevent showing the same ad again
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            bottomOpacity: 0.0,
            backgroundColor: Colors.red,
            elevation: 0.0,
            title: const Text(
              "ConnectMe",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                  onPressed: () async {
                    _showRewardedAd();
                  },
                  icon: const Icon(Iconsax.video)),
              IconButton(
                  onPressed: () async {
                    BlocProvider.of<AuthBloc>(context).add(SignOutEvent());
                  },
                  icon: const Icon(Iconsax.logout))
            ],
          ),
          body: Container(
            child: Column(
              children: [
                Flexible(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('activeUser')
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty ||
                          snapshot.data!.docs.length < noOfCards - 1) {
                        return const Center(child: Text('No data available'));
                      }
                      return CardSwiper(
                          controller: controller,
                          cardsCount: snapshot.data!.docs.length,
                          //onSwipe: _onSwipe,
                          // onUndo: _onUndo,
                          numberOfCardsDisplayed: noOfCards,
                          isLoop: true,
                          backCardOffset: const Offset(2, 18),
                          padding: const EdgeInsets.all(24.0),
                          cardBuilder: (
                            context,
                            index,
                            horizontalThresholdPercentage,
                            verticalThresholdPercentage,
                          ) {
                            DocumentSnapshot document =
                                snapshot.data!.docs[index];
                            Map<String, dynamic> data =
                                document.data() as Map<String, dynamic>;

                            String? userName = data['id'];
                            String? img = data['imgurl'];
                            bool? age = data['incall'];

                            return FirebaseAuth.instance.currentUser!.uid ==
                                    userName
                                ? const SizedBox()
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 3,
                                          blurRadius: 7,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                  imageUrl: img.toString())),
                                          // Image.network(img.toString()),
                                          ListTile(
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ElevatedButton.icon(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16.0)),
                                                      ),
                                                      onPressed: () async {
                                                        setState(() {
                                                          isCalling = true;
                                                        });
                                                        if (index ==
                                                            noOfCards - 1) {
                                                          _showRewardedAd();
                                                        } else {
                                                          _showInterstitialAd(
                                                              userName!);
                                                        }
                                                        await Future.delayed(
                                                                const Duration(
                                                                    seconds:
                                                                        14))
                                                            .then((value) {
                                                          setState(() {
                                                            isCalling = false;
                                                          });
                                                        });
                                                      },
                                                      icon: const Icon(
                                                          Iconsax.call),
                                                      label:
                                                          const Text("Call")),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                          }
//  cards[index],
                          );
                      // return ListView.builder(
                      //   itemCount: snapshot.data!.docs.length,
                      //   itemBuilder: (context, index) {
                      //     DocumentSnapshot document =
                      //         snapshot.data!.docs[index];
                      //     Map<String, dynamic> data =
                      //         document.data() as Map<String, dynamic>;
                      //
                      //     String? userName = data['id'];
                      //     bool? age = data['incall'];
                      //
                      //     return FirebaseAuth.instance.currentUser!.uid ==
                      //             userName
                      //         ? SizedBox()
                      //         : ListTile(
                      //             // title: Text('User ID: $HomePage'),
                      //             trailing: age.toString() == "true"
                      //                 ? SizedBox()
                      //                 : ElevatedButton(
                      //                     style: ElevatedButton.styleFrom(
                      //                         shape: RoundedRectangleBorder(
                      //                             borderRadius:
                      //                                 BorderRadius.circular(
                      //                                     12.0))),
                      //                     onPressed: () {
                      //                       addDocumentToCallingCollection(
                      //                           userName.toString(),
                      //                           FirebaseAuth
                      //                               .instance.currentUser!.uid);
                      //                     },
                      //                     child: Text("Call User"),
                      //                   ),
                      //
                      //             subtitle: Column(
                      //               crossAxisAlignment:
                      //                   CrossAxisAlignment.start,
                      //               children: [
                      //                 Text('User: $userName'.toString()),
                      //                 Text('Status: $age'.toString()),
                      //               ],
                      //             ),
                      //           );
                      //   },
                      // );
                    },
                  ),
                ),
                // ListTile(
                //   trailing: ElevatedButton(
                //     onPressed: () {
                //
                //     },
                //     child: Text("Call User"),
                //   ),
                //   title: Text('USER'),
                // ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _userStreamController.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox();
              } else {
                var userData = snapshot.data!.data()!;
                // Update your UI using userData
                return Column(
                  children: [
                    AlertDialog(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      title: const Text(
                        "Anonymous is calling...",
                        style: TextStyle(color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              FirebaseFirestore firestore =
                                  FirebaseFirestore.instance;

                              // Add the document to the "calling" collection
                              await firestore
                                  .collection('calling')
                                  .doc(userData['callee'])
                                  .delete();
                            },
                            child: const Text("Reject",
                                style: TextStyle(color: Colors.red))),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: () {
                              acceptDocumentToCallingCollection(
                                  userData['caller'],
                                  FirebaseAuth.instance.currentUser!.uid);
                            },
                            child: const Text("Accept"))
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ),
        isCalling
            ? SafeArea(
                child: Column(
                  children: [
                    AlertDialog(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      title: const Text(
                        "Ringing Bell.....",
                        style: TextStyle(color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              setState(() {
                                isCalling = false;
                              });
                            },
                            child: const Text("Cancel",
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
