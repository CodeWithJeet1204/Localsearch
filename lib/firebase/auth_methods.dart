import 'package:localsearch/page/auth/register_details_page.dart';
import 'package:localsearch/page/auth/verify/number_verify.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get user => _auth.currentUser!;

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
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (context.mounted) {
        mySnackBar(
          e.toString(),
          context,
        );
      }
    }
  }

  // EMAIL VERIFICATION
  Future<void> sendEmailVerification(BuildContext context) async {
    try {
      _auth.currentUser!.sendEmailVerification();
      mySnackBar(
        'Email Verification has been sent',
        context,
      );
    } catch (e) {
      if (context.mounted) {
        mySnackBar(
          e.toString(),
          context,
        );
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
    } catch (e) {
      if (context.mounted) {
        mySnackBar(
          e.toString(),
          context,
        );
      }
    }
  }

  // GOOGLE SIGN IN
  final GoogleSignIn googleSignIn = GoogleSignIn(
    hostedDomain: '',
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
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: ((context) => const RegisterDetailsPage(
                      emailPhoneGoogleChosen: 3,
                    )),
              ),
              (route) => false,
            );
          }
        }
      }
      // }
      return userCredential;
    } catch (e) {
      if (context.mounted) {
        mySnackBar(
          e.toString(),
          context,
        );
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
            mySnackBar(
              e.toString(),
              context,
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NumberVerifyPage(
                verificationId: verificationId,
                isLogging: false,
                phoneNumber: phoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          mySnackBar(
            verificationId.toString(),
            context,
          );
        });
  }

  // SIGN OUT
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (context.mounted) {
        mySnackBar(
          e.toString(),
          context,
        );
      }
    }
  }

  // DELETE ACCOUNT
  Future<void> deleteAccount(BuildContext context) async {
    try {
      await _auth.currentUser!.delete();
    } catch (e) {
      if (context.mounted) {
        mySnackBar(
          e.toString(),
          context,
        );
      }
    }
  }
}
