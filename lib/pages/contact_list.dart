import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_call/pages/conference.dart';
import '../main.dart';
import '../services/database.dart';
import 'Welcome/components/constants.dart';

class MessagesScreen extends StatefulWidget
{
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State createState() => MessagesScreenState();
}

class MessagesScreenState extends State<MessagesScreen>
{
  final ScrollController _listScrollController = ScrollController();
  int _limit = 20;
  // ignore: prefer_final_fields
  int _limitIncrement = 20;
  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState()
  {
    initOneSignal();
    saveUserInfoInDatabase();
    super.initState();
    _listScrollController.addListener(scrollListener);
  }
  
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text(
            'Video Call App',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(
                FontAwesomeIcons.arrowRightFromBracket,
                color: Colors.white),
            onPressed: () => openModal(),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: const Icon(
                    FontAwesomeIcons.peopleGroup,
                    color: Colors.white),
                onPressed: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const Conference()));
                },
              ),
            )
          ],
          centerTitle: true),
      body: Stack(
        children: <Widget>[
          // List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').limit(_limit).snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                List docs = [];
                if(snapshot.data != null)
                {
                  int _lengthDocs = snapshot.data!.docs.length;

                  for(int i = 0; i < _lengthDocs; i++)
                  {
                    if(snapshot.data!.docs[i].id != user.uid)
                    {
                      docs.add(snapshot.data!.docs[i]);
                    }
                  }
                }

                if(docs.isNotEmpty)
                {
                  return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemCount: snapshot.data?.docs.length,
                      controller: _listScrollController,
                      itemBuilder: (context, index)=> buildItem(context, snapshot.data?.docs[index])
                  );
                }
                else
                {
                  return const Center(
                    child: Text('No User Found', style: TextStyle(color: Colors.grey)),
                  );
                }
              } else {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xff029bd7)),
                  ),
                );
              }
            },
          ),
        ],
      )
    );
  }

  void initOneSignal() async
  {
    if (!mounted) return;

    var oneSignal = OneSignal.shared;

    oneSignal.setLogLevel(OSLogLevel.none, OSLogLevel.none);

    oneSignal.setNotificationOpenedHandler((OSNotificationOpenedResult result)
    {
      if(!mounted)
      {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyApp()));
        if(result.notification.collapseId != null)
        {
          showCupertinoDialog(
              context: context,
              builder: (context) {
                return CupertinoAlertDialog(
                  title: const Text("Incoming Video Call"),
                  content: const Text("Do you want to receive this call?"),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await oneSignal.clearOneSignalNotifications();
                      },
                      child: const Text("No"),
                    ),
                    CupertinoDialogAction(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        joinVideoConferrencingRoom(result.notification.collapseId!);
                        await oneSignal.clearOneSignalNotifications();
                      },
                      child: const Text("Yes"),
                    ),
                  ],
                );
              });
        }
      }
      else
      {
        if(result.notification.collapseId != null)
        {
          showCupertinoDialog(
              context: context,
              builder: (context) {
                return CupertinoAlertDialog(
                  title: const Text("Incoming Video Call"),
                  content: const Text("Do you want to receive this call?"),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await oneSignal.clearOneSignalNotifications();
                      },
                      child: const Text("Cancel"),
                    ),
                    CupertinoDialogAction(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        joinVideoConferrencingRoom(result.notification.collapseId!);
                        await oneSignal.clearOneSignalNotifications();
                      },
                      child: const Text("Yes"),
                    ),
                  ],
                );
              });
        }
      }
      this.setState(() {});
    });

    oneSignal.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event)
    {
      if(!mounted)
      {
        event.complete(event.notification);
      }
      else
      {
        if(event.notification.collapseId != null)
        {
          showCupertinoDialog(
              context: context,
              builder: (context) {
                return CupertinoAlertDialog(
                  title: const Text("Incoming Video Call"),
                  content: const Text("Do you want to receive this call?"),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await oneSignal.clearOneSignalNotifications();
                      },
                      child: const Text("Cancel"),
                    ),
                    CupertinoDialogAction(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        joinVideoConferrencingRoom(event.notification.collapseId!);
                        await oneSignal.clearOneSignalNotifications();
                      },
                      child: const Text("Yes"),
                    ),
                  ],
                );
              });
        }
      }
      this.setState(() {});
    });

    oneSignal.setInAppMessageClickedHandler((OSInAppMessageAction action)
    {
      this.setState(() {});
    });

    oneSignal.setSubscriptionObserver((OSSubscriptionStateChanges changes)
    {
      //Some functions/methods in the future here
    });

    oneSignal.setPermissionObserver((OSPermissionStateChanges changes)
    {
      //Some functions/methods in the future here
    });

    oneSignal.setOnWillDisplayInAppMessageHandler((message)
    {
      //Some functions/methods in the future here
    });

    oneSignal.setOnDidDisplayInAppMessageHandler((message)
    {
      //Some functions/methods in the future here
    });

    oneSignal.setOnWillDismissInAppMessageHandler((message)
    {
      //Some functions/methods in the future here
    });

    oneSignal.setOnDidDismissInAppMessageHandler((message)
    {
      //Some functions/methods in the future here
    });

    // NOTE: Replace with your own app ID from https://www.onesignal.com
    oneSignal.setAppId("0f671a29-2e02-42d0-99e0-72f39d4d9b39");
    oneSignal.promptUserForPushNotificationPermission().then((accepted) {});

    // iOS-only method to open launch URLs in Safari when set to false
    if(Platform.isIOS)
    {
      oneSignal.setLaunchURLsInApp(false);
    }

    oneSignal.setExternalUserId(user.uid);
    this.setState(() {});
    oneSignal.disablePush(false);
  }

  void sendNotification(String toUid, String key) async
  {
    const String app_id = "0f671a29-2e02-42d0-99e0-72f39d4d9b39";
    var body = jsonEncode({
      "include_external_user_ids": [toUid],
      "app_id": app_id,
      "contents": {"en": 'Incoming Video Call'},
      "headings": {"en": user.displayName},
      "collapse_id": key.substring(0, 3) + key.substring(key.length - 4, key.length - 1),
      "small_icon": "launcher_icon",
      "large_icon": "launcher_icon",
      "android_visibility": 1,
      "priority": 10
    });
    http.Response response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        body: body,
        headers: {
          "content-type": "application/json",
          "Authorization":
          "Basic ZGJhOTkyYzgtYjAzYi00Y2E4LTg3MjYtNTJiMzRiNjRlNGY4"
        });
    if (response.statusCode == 200) {
      debugPrint("NOTIFICATION SENT SUCCESSFULLY");
    } else {
      debugPrint('Notification Error | Error Code: ${response.statusCode}');
    }
  }

  Widget buildItem(BuildContext context, DocumentSnapshot? document)
  {
    if (document != null)
    {
      // ignore: no_leading_underscores_for_local_identifiers
      UserSnapshot _userChat = UserSnapshot.fromDocument(document);
      if(user.uid == _userChat.id)
      {
        return const SizedBox.shrink();
      }
      else
      {
        return Container(
          margin: const EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
          child: TextButton(
            onPressed: () async
            {
              String roomKey = '${user.uid}-${DateTime.now().millisecondsSinceEpoch}';
              joinVideoConferrencingRoom(roomKey, opt: true);
              sendNotification(_userChat.id, roomKey);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(const Color(0xffE8E8E8)),
              shape: MaterialStateProperty.all<OutlinedBorder>(
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Material(
                  borderRadius: const BorderRadius.all(Radius.circular(25.0)),
                  clipBehavior: Clip.hardEdge,
                  child: _userChat.photoUrl.isNotEmpty
                      ? Image.network(
                    _userChat.photoUrl,
                    fit: BoxFit.cover,
                    width: 50.0,
                    height: 50.0,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xff029bd7),
                            value: loadingProgress.expectedTotalBytes != null &&
                                loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, object, stackTrace) {
                      return const Icon(
                        Icons.account_circle,
                        size: 50.0,
                        color: Color(0xffaeaeae),
                      );
                    },
                  )
                      : const Icon(
                    Icons.account_circle,
                    size: 50.0,
                    color: Color(0xffaeaeae),
                  ),
                ),
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 20.0),
                    child: Column(
                      children: <Widget>[
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                          child: Text(
                              _userChat.userName,
                              maxLines: 1,
                              style: const TextStyle(color: Color(0xff203152), fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                          child: Text(
                            _userChat.userEmail,
                            maxLines: 1,
                            style: const TextStyle(color: Color(0xff203152), fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    else
    {
      return const SizedBox.shrink();
    }
  }

  void scrollListener()
  {
    if (_listScrollController.offset >= _listScrollController.position.maxScrollExtent &&
        !_listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  joinVideoConferrencingRoom(String key, {bool opt = false}) async {
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
    var options = JitsiMeetingOptions(roomNameOrUrl: opt == true ? key.substring(0, 3) + key.substring(key.length - 4, key.length - 1) : key,
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
  }

  Future saveUserInfoInDatabase() async {
    final user = FirebaseAuth.instance.currentUser!;
    Map<String, dynamic> userInfoMap = {
      "userEmail": user.email,
      "userName": user.displayName,
      "userImageUrl": user.photoURL ?? '',
      "addedPhoneNumber": user.phoneNumber ?? '',
    };
    await DatabaseServices()
        .addUserInfo(user.uid, userInfoMap)
        .whenComplete(() => debugPrint("UserInfo added Complete! 😏😏😏😏😏😏"));
  }
  
  void openModal() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Loggin You Out"),
          content: const Text("Are you sure you want to Log Out From this Account?"),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            CupertinoDialogAction(
              onPressed: () {
                logOutFromThisAccount(context);
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }
  
  Future logOutFromThisAccount(BuildContext context) async {
    Navigator.of(context).pop();
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().disconnect();
    await GoogleSignIn().signOut();
  }
}

class UserSnapshot {
  UserSnapshot({required this.id, required this.photoUrl, required this.userName, required this.userEmail});
  String id, photoUrl, userName, userEmail;

  factory UserSnapshot.fromDocument(DocumentSnapshot doc) {
    String userName = "";
    String userEmail = "";
    String photoUrl = "";
    try {
      userName = doc.get('userName');
    // ignore: empty_catches
    } catch (e) {}
    try {
      photoUrl = doc.get('photoUrl');
      // ignore: empty_catches
    } catch (e) {}
    try {
      userEmail = doc.get('userEmail');
    // ignore: empty_catches
    } catch (e) {}
    return UserSnapshot(
      id: doc.id,
      photoUrl: photoUrl,
      userName: userName,
      userEmail: userEmail,
    );
  }
}