import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class DatabaseServices {
  Future addUserInfo(String uid, userInfoMap) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).set(userInfoMap).catchError((e) => debugPrint("addUserInfo Error is ------------>>> ${e.toString()}"));
  }
}
