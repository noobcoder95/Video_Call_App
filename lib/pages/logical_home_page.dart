import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_call/pages/Welcome/welcome_screen.dart';
import 'contact_list.dart';

class LogicalHomePage extends StatelessWidget {
  const LogicalHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasData) {
            debugPrint("Going to Homepage");
            return const MessagesScreen();
          } else if (snapshot.hasError) {
            return const Center(
              child: Text("Something Went Wrong"),
            );
          } else {
            debugPrint("Going to LoginPage");
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
