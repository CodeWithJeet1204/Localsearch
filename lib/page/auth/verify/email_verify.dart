import 'dart:async';

import 'package:find_easy_user/firebase/auth_methods.dart';
import 'package:find_easy_user/page/auth/register_cred.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/button.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmailVerifyPage extends StatefulWidget {
  const EmailVerifyPage({
    super.key,
  });

  @override
  State<EmailVerifyPage> createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends State<EmailVerifyPage> {
  // @override
  // void initState() {
  //   super.initState();
  //   Timer.periodic(Duration(milliseconds: 100), (timer) async {
  //     await AuthMethods(FirebaseAuth.instance).user.reload();
  //     if (FirebaseAuth.instance.currentUser!.emailVerified) {
  //       Timer(Duration(seconds: 1), () {
  //         Navigator.of(context).pop();
  //         Navigator.of(context).push(
  //           MaterialPageRoute(
  //             builder: ((context) => UserRegisterDetailsPage(
  //                   emailChosen: true,
  //                   numberChosen: false,
  //                   googleChosen: false,
  //                 )),
  //           ),
  //         );
  //       });
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final AuthMethods auth = AuthMethods();
    String sendEmailText = "Send Email";

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Expanded(child: Container()),
                const Text(
                  "Click on the below button to send EMAIL VERIFICATION link\n",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryDark,
                    fontSize: 16,
                  ),
                ),
                MyButton(
                  text: sendEmailText,
                  onTap: () async {
                    await auth.sendEmailVerification(context);
                    setState(() {
                      sendEmailText = "Email Sent";
                    });
                  },
                  isLoading: false,
                  horizontalPadding: 20,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                const Text(
                  "An email has been sent to your account, pls click on it\nTo verify your account\n\nClick on the button after verifying the email\n\n(It may take some time for email to arrive)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryDark,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                MyButton(
                  text: "I have verified my email",
                  onTap: () async {
                    await auth.user.reload();
                    if (_auth.currentUser!.emailVerified) {
                      Timer(const Duration(milliseconds: 0), () {
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: ((context) => const RegisterCredPage(
                                // emailChosen: true,
                                // numberChosen: false,
                                // googleChosen: false,
                                )),
                          ),
                        );
                      });
                    } else {
                      if (context.mounted) {
                        mySnackBar("Email not verified", context);
                      }
                    }
                  },
                  isLoading: false,
                  horizontalPadding: 24,
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
