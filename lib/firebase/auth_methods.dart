import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/page/auth/register_cred.dart';
import 'package:find_easy_user/page/auth/register_data.dart';
import 'package:find_easy_user/page/auth/verify/number_verify.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User get user => _auth.currentUser!;

  // Future<model.User> getUserDetails() async {
  //   User currentUser = _auth.currentUser!;

  //   DocumentSnapshot snap = await _firestore
  //       .collection('Business')
  //       .doc('Owners')
  //       .collection('Users')
  //       .doc(currentUser.uid)
  //       .get();

  //   return model.User.fromSnap(snap);
  // }

  // STATE PERSISTENCE
  Stream<User?> get authState => FirebaseAuth.instance.authStateChanges();

  // EMAIL SIGNUP
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        mySnackBar(e.message!, context);
      }
    }
  }

  // EMAIL VERIFICATION
  Future<void> sendEmailVerification(BuildContext context) async {
    try {
      _auth.currentUser!.sendEmailVerification();
      mySnackBar("Email Verification has been sent", context);
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        mySnackBar(e.message!, context);
      }
    }
  }

  // EMAIL LOGIN
  Future<void> loginWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (!_auth.currentUser!.emailVerified) {
        if (context.mounted) {
          await sendEmailVerification(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        mySnackBar(e.message!, context);
      }
    }
  }

  // GOOGLE SIGN IN
  final GoogleSignIn googleSignIn = GoogleSignIn(
    hostedDomain: "", // Prevent automatic sign-in
  );

  /*Future<void>*/ signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      // if (googleAuth.accessToken != null && googleAuth.idToken != null) {
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // ignore: unused_local_variable
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        if (userCredential.additionalUserInfo!.isNewUser) {
          userFirestoreData.addAll({
            "uid": FirebaseAuth.instance.currentUser!.uid,
            "Name": FirebaseAuth.instance.currentUser!.displayName,
            "Email": FirebaseAuth.instance.currentUser!.email,
            "Image": FirebaseAuth.instance.currentUser!.photoURL,
          });
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: ((context) => const RegisterCredPage(
                    // emailChosen: false,
                    // numberChosen: false,
                    // googleChosen: true,
                    )),
              ),
              (route) => false,
            );
          }
        }
      }
      // }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        mySnackBar(e.message!, context);
      }
    }
  }

  // PHONE SIGN IN
  Future<void> phoneSignIn(BuildContext context, String phoneNumber) async {
    // TextEditingController codeController = TextEditingController();
    // ADNROID / IOS

    _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (context.mounted) {
            mySnackBar(e.toString(), context);
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NumberVerifyPage(
                verificationId: verificationId,
                isLogging: false,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          mySnackBar(verificationId.toString(), context);
        });
  }

  // ANONYMOUS SIGN IN
  Future<void> signInAnonymously(BuildContext context) async {
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        mySnackBar(e.message!, context);
      }
    }
  }

  // SIGN OUT
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        mySnackBar(e.message!, context);
      }
    }
  }

  // DELETE ACCOUNT
  Future<void> deleteAccount(BuildContext context) async {
    try {
      await _auth.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        mySnackBar(e.message!, context);
      }
    }
  }
}
