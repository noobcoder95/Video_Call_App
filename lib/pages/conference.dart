import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:share/share.dart';
import 'package:video_call/pages/Welcome/components/constants.dart';

class Conference extends StatefulWidget {
  const Conference({Key? key}) : super(key: key);

  @override
  _Conference createState() => _Conference();
}

class _Conference extends State<Conference> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: onBackPress,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: kPrimaryColor,
            elevation: 0.6,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Video Conferrence',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Container(
            margin: const EdgeInsets.only(top: 210),
            child: Padding(
              padding: const EdgeInsets.all(19.0),
              child: Container(
                alignment: Alignment.center,
                height: 200,
                child: const ChatRoomForm(),
              ),
            ),
          ),
        )
    );
  }

  Future<bool> onBackPress()
  {
    Navigator.pop(context);
    return Future.value(false);
  }
}

class ChatRoomForm extends StatefulWidget {
  const ChatRoomForm({Key? key}) : super(key: key);

  @override
  State<ChatRoomForm> createState() => _ChatRoomFormState();
}

class _ChatRoomFormState extends State<ChatRoomForm> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();
  late String roomCode;

  joinVideoConferrencingRoom() async {
    if (_formKey.currentState!.validate()) {
      String serverUrl;
      serverUrl = "https://meet.jit.si";

      Map<FeatureFlag, bool> featureFlags = {
        FeatureFlag.isWelcomePageEnabled: false,
      };

      if (!kIsWeb) {
        // Here is an example, disabling features for each platform
        if (Platform.isAndroid) {
          // Disable ConnectionService usage on Android to avoid issues (see README)
          featureFlags[FeatureFlag.isCallIntegrationEnabled] = false;
        } else if (Platform.isIOS) {
          // Disable PIP on iOS as it looks weird
          featureFlags[FeatureFlag.isPipEnabled] = false;
        }
      }

      // Define meetings options here
      var options = JitsiMeetingOptions(roomNameOrUrl: roomCode,
          serverUrl: serverUrl,
          userDisplayName: user.displayName,
          userEmail: user.email,
          userAvatarUrl: user.photoURL,
          featureFlags: featureFlags);

      debugPrint("JitsiMeetingOptions: $options");
      await JitsiMeetWrapper.joinMeeting(options: options,
          listener: JitsiMeetingListener(
              onConferenceWillJoin: (message) {
                debugPrint(message);
              },
              onConferenceJoined: (message) {
                debugPrint(message);
              },
              onConferenceTerminated: (message, obj) {
                debugPrint(message);
              })
      );
    } else {
      debugPrint("please enter some code to join");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
                decoration: const InputDecoration(hintText: "Enter or Create Room Code"),
                onChanged: (val) {
                  roomCode = val;
                  debugPrint(val);
                },
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "cant't be empty!";
                  } else {
                    val = "";
                    return null;
                  }
                },
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    joinVideoConferrencingRoom();
                  },
                  child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(29)),
                      height: 50,
                      width: MediaQuery.of(context).size.width / 2.4,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              CupertinoIcons.video_camera,
                              size: 36,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 9,
                            ),
                            Text(
                              "Enter",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ])),
                ),
                const SizedBox(
                  width: 19,
                ),
                GestureDetector(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      Share.share(roomCode);
                    } else {
                      // ignore: avoid_print
                      print("Please provide some room code");
                    }
                  },
                  child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: kPrimaryLightColor,
                          borderRadius: BorderRadius.circular(29)),
                      height: 50,
                      width: MediaQuery.of(context).size.width / 2.4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.share,
                            color: Colors.black,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Text(
                            "Share",
                            style: TextStyle(color: Colors.black, fontSize: 17),
                          ),
                        ],
                      )),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}