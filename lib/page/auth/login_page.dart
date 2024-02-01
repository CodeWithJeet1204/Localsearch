import 'dart:async';
import 'package:find_easy_user/firebase/auth_methods.dart';
import 'package:find_easy_user/page/auth/verify/number_verify.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/button.dart';
import 'package:find_easy_user/widgets/collapse_container.dart';
import 'package:find_easy_user/widgets/head_text.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:find_easy_user/widgets/text_button.dart';
import 'package:find_easy_user/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> numberLoginFormKey = GlobalKey<FormState>();
  String phoneText = "Verify";
  String googleText = "Sign in With GOOGLE";
  bool isGoogleLogging = false;
  bool isShowEmail = false;
  bool isShowNumber = false;
  bool isEmailLogging = false;
  bool isPhoneLogging = false;

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final auth = AuthMethods();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: 857,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(),
                ),
                const HeadText(text: "LOGIN"),
                Expanded(
                  flex: 2,
                  child: Container(),
                ),
                Column(
                  children: [
                    MyCollapseContainer(
                      headText: "Email",
                      isShow: isShowEmail,
                      horizontalMargin: 20,
                      horizontalPadding: 12,
                      verticalPadding: 8,
                      bodyWidget: Form(
                        key: numberLoginFormKey,
                        child: Column(
                          children: [
                            MyTextFormField(
                              hintText: "Email",
                              controller: emailController,
                              borderRadius: 16,
                              horizontalPadding: 24,
                              keyboardType: TextInputType.emailAddress,
                              autoFillHints: const [AutofillHints.email],
                            ),
                            const SizedBox(height: 8),
                            MyTextFormField(
                              hintText: "Password",
                              controller: passwordController,
                              borderRadius: 16,
                              horizontalPadding: 24,
                              isPassword: true,
                              autoFillHints: const [AutofillHints.password],
                            ),
                            const SizedBox(height: 8),
                            MyButton(
                              text: "LOGIN",
                              onTap: () async {
                                if (numberLoginFormKey.currentState!
                                    .validate()) {
                                  try {
                                    setState(() {
                                      isEmailLogging = true;
                                    });
                                    // Login
                                    await _auth.signInWithEmailAndPassword(
                                      email: emailController.text.toString(),
                                      password:
                                          passwordController.text.toString(),
                                    );
                                    setState(() {});
                                    // if (context.mounted) {
                                    //   Navigator.of(context)
                                    //       .popAndPushNamed('/profile');
                                    // }
                                    setState(() {
                                      isEmailLogging = false;
                                    });
                                  } catch (e) {
                                    setState(() {
                                      isEmailLogging = false;
                                    });
                                    if (context.mounted) {
                                      if (e !=
                                          "Null check operator used on a null value") {
                                        if (context.mounted) {
                                          mySnackBar(e.toString(), context);
                                        }
                                      }
                                    }
                                  }
                                }
                              },
                              horizontalPadding: 24,
                              isLoading: isEmailLogging,
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Timer(const Duration(milliseconds: 100), () {
                          setState(() {
                            isShowNumber = false;
                            isShowEmail = !isShowEmail;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    MyCollapseContainer(
                      headText: "Phone Number",
                      isShow: isShowNumber,
                      horizontalMargin: 20,
                      horizontalPadding: 12,
                      verticalPadding: 8,
                      bodyWidget: Form(
                        key: numberLoginFormKey,
                        child: Column(
                          children: [
                            MyTextFormField(
                              hintText: "Phone Number",
                              controller: phoneController,
                              borderRadius: 16,
                              horizontalPadding: 24,
                              keyboardType: TextInputType.number,
                              autoFillHints: const [
                                AutofillHints.telephoneNumberDevice
                              ],
                            ),
                            const SizedBox(height: 8),
                            MyButton(
                              text: phoneText,
                              onTap: () async {
                                if (numberLoginFormKey.currentState!
                                    .validate()) {
                                  try {
                                    setState(() {
                                      isPhoneLogging = true;
                                      phoneText = "PLEASE WAIT";
                                    });
                                    // Register with Phone
                                    if (phoneController.text.contains("+91")) {
                                      await auth.phoneSignIn(
                                          context, " ${phoneController.text}");
                                    } else if (phoneController.text
                                        .contains("+91 ")) {
                                      await auth.phoneSignIn(
                                          context, phoneController.text);
                                    } else {
                                      setState(() {
                                        isPhoneLogging = true;
                                      });
                                      await _auth.verifyPhoneNumber(
                                          phoneNumber:
                                              "+91 ${phoneController.text}",
                                          verificationCompleted: (_) {
                                            setState(() {
                                              isPhoneLogging = false;
                                            });
                                          },
                                          verificationFailed: (e) {
                                            if (context.mounted) {
                                              mySnackBar(e.toString(), context);
                                            }
                                            setState(() {
                                              isPhoneLogging = false;
                                            });
                                          },
                                          codeSent: (String verificationId,
                                              int? token) {
                                            SystemChannels.textInput
                                                .invokeMethod('TextInput.hide');
                                            Navigator.of(context).pop();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    NumberVerifyPage(
                                                  verificationId:
                                                      verificationId,
                                                  isLogging: true,
                                                ),
                                              ),
                                            );
                                            setState(() {
                                              isPhoneLogging = false;
                                            });
                                          },
                                          codeAutoRetrievalTimeout: (e) {
                                            if (context.mounted) {
                                              mySnackBar(e.toString(), context);
                                            }
                                            isPhoneLogging = false;
                                          });
                                    }
                                    setState(() {
                                      isPhoneLogging = false;
                                    });
                                  } catch (e) {
                                    setState(() {
                                      isPhoneLogging = false;
                                    });
                                    if (context.mounted) {
                                      mySnackBar(e.toString(), context);
                                    }
                                  }
                                }
                              },
                              horizontalPadding: 24,
                              isLoading: isPhoneLogging,
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Timer(const Duration(milliseconds: 100), () {
                          setState(() {
                            isShowEmail = false;
                            isShowNumber = !isShowNumber;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        try {
                          setState(() {
                            isShowEmail = false;
                            isShowNumber = false;
                            googleText = "PLEASE WAIT";
                            isGoogleLogging = true;
                          });
                          // Sign In With Google
                          await AuthMethods().signInWithGoogle(context);
                          // SystemChannels.textInput
                          //     .invokeMethod('TextInput.hide');
                          if (FirebaseAuth.instance.currentUser != null) {
                            setState(() {});
                          } else {
                            if (context.mounted) {
                              mySnackBar("Some error occured!", context);
                            }
                          }
                        } on FirebaseAuthException catch (e) {
                          if (context.mounted) {
                            mySnackBar(e.toString(), context);
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: primary2.withOpacity(0.75),
                        ),
                        child: isGoogleLogging
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: primaryDark,
                                ),
                              )
                            : Text(
                                googleText,
                                style: const TextStyle(
                                  color: buttonColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  flex: 2,
                  child: Container(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    MyTextButton(
                      onPressed: () {
                        setState(() {
                          isShowEmail = false;
                          isShowNumber = false;
                        });
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        Navigator.of(context).popAndPushNamed('/registerPay');
                      },
                      text: "REGISTER",
                      textColor: buttonColor,
                    ),
                  ],
                ),
                Expanded(
                  flex: 2,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
