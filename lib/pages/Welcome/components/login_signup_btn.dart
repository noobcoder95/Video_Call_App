import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/google_login.dart';
import 'constants.dart';

class LoginAndSignupBtn extends StatelessWidget {
  const LoginAndSignupBtn({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const FaIcon(
            FontAwesomeIcons.google,
            color: Colors.white,
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(13),
            primary: kPrimaryColor.withOpacity(0.7),
            onPrimary: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          label: Text(
            "  SIGN IN",
            style: TextStyle(
                fontSize: 18, fontFamily: GoogleFonts.lato().fontFamily),
          ),
          onPressed: () {
            signIn(context);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const FaIcon(
            FontAwesomeIcons.google,
            color: Colors.white,
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(13),
            primary: kPrimaryLightColor.withOpacity(0.7),
            onPrimary: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          label: Text(
            "  SIGN UP",
            style: TextStyle(
                fontSize: 18, fontFamily: GoogleFonts.lato().fontFamily),
          ),
          onPressed: () {
            signIn(context);
          },
        )
      ],
    );
  }

  Future signIn(BuildContext context) async {
    User? user = await GoogleLoginAuth.signInWithGoogle(context: context);

    if(user != null)
    {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "userEmail": user.email,
        "userName": user.displayName,
        "userImageUrl": user.photoURL ?? '',
        "addedPhoneNumber": user.phoneNumber ?? '',
      });
    }
  }
}
