import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/firebase/auth_methods.dart';
import 'package:find_easy_user/page/auth/register_details_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/button.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerifyPage extends StatefulWidget {
  const EmailVerifyPage({
    super.key,
  });

  @override
  State<EmailVerifyPage> createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends State<EmailVerifyPage> {
  // ignore: no_leading_underscores_for_local_identifiers
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final AuthMethods auth = AuthMethods();
  bool checkingEmailVerified = false;
  bool canResendEmail = false;
  bool isEmailVerified = false;

  // INIT STATE
  @override
  void initState() {
    super.initState();
    sendEmailVerification();
  }

  // CHECK EMAIL VERIFICATION
  Future<void> checkEmailVerification({bool? fromButton}) async {
    await FirebaseAuth.instance.currentUser!.reload();

    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (isEmailVerified) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: ((context) => const RegisterDetailsPage())),
          (route) => false,
        );
      }
    } else if (fromButton != null) {
      mySnackBar('Pls verify your email', context);
    }
  }

  // SEND EMAIL VERIFICATION
  void sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      if (context.mounted) {
        mySnackBar(
          "Verification Email Sent",
          context,
        );
      }

      setState(() {
        canResendEmail = false;
      });
      await Future.delayed(const Duration(seconds: 5));
      setState(() {
        canResendEmail = true;
      });
    } catch (e) {
      if (context.mounted) {
        mySnackBar(
          e.toString(),
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _auth.currentUser!.email!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryDark,
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "An email has been sent to your account, pls click on it\nTo verify your account\n\nIf you want to resend email click below\n\n(It may take some time for email to arrive)",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryDark,
                fontSize: MediaQuery.of(context).size.width * 0.045,
              ),
            ),
            const SizedBox(height: 20),
            MyButton(
              text: "I have Verified my Email",
              onTap: () async {
                await checkEmailVerification(fromButton: true);
              },
              isLoading: checkingEmailVerified,
              horizontalPadding: MediaQuery.of(context).size.width * 0.066,
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: canResendEmail ? 1 : 0.5,
              child: MyButton(
                text: "Resend Email",
                onTap: canResendEmail
                    ? sendEmailVerification
                    : () {
                        mySnackBar(
                          "Wait for 5 seconds",
                          context,
                        );
                      },
                isLoading: checkingEmailVerified,
                horizontalPadding: MediaQuery.of(context).size.width * 0.066,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
