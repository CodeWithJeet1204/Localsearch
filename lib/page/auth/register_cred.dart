import 'package:find_easy_user/firebase/auth_methods.dart';
import 'package:find_easy_user/page/auth/register_data.dart';
import 'package:find_easy_user/page/auth/verify/email_verify.dart';
import 'package:find_easy_user/page/auth/verify/number_verify.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/button.dart';
import 'package:find_easy_user/widgets/collapse_container.dart';
import 'package:find_easy_user/widgets/head_text.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:find_easy_user/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterCredPage extends StatefulWidget {
  const RegisterCredPage({super.key});

  @override
  State<RegisterCredPage> createState() => _RegisterCredPageState();
}

class _RegisterCredPageState extends State<RegisterCredPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  String phoneButtonText = "SIGNUP";
  String googleText = "Signup With GOOGLE";
  bool isGoogleRegistering = false;
  bool isShowEmail = false;
  bool isShowNumber = false;
  bool isEmailRegistering = false;
  bool isPhoneRegistering = false;
  bool isEmailChosen = false;
  bool isNumberChosen = false;
  bool isGoogleChosen = false;

  void navigateToEmailVerify() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    Navigator.of(context).popAndPushNamed('/emailVerify');
  }

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final AuthMethods auth = AuthMethods();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Container(),
                ),
                const HeadText(text: "REGISTER"),
                Expanded(
                  flex: 4,
                  child: Container(),
                ),
                Column(
                  children: [
                    // EMAIL
                    MyCollapseContainer(
                      headText: "Email",
                      isShow: isShowEmail,
                      horizontalMargin: 20,
                      horizontalPadding: 12,
                      verticalPadding: 8,
                      bodyWidget: Form(
                        key: registerFormKey,
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
                              autoFillHints: const [AutofillHints.newPassword],
                            ),
                            MyTextFormField(
                              hintText: "Confirm Password",
                              controller: confirmPasswordController,
                              borderRadius: 16,
                              horizontalPadding: 24,
                              verticalPadding: 8,
                              isPassword: true,
                              autoFillHints: const [AutofillHints.newPassword],
                            ),
                            const SizedBox(height: 8),
                            MyButton(
                              text: "SIGNUP",
                              onTap: () async {
                                if (passwordController.text ==
                                    confirmPasswordController.text) {
                                  if (registerFormKey.currentState!
                                      .validate()) {
                                    setState(() {
                                      isEmailRegistering = true;
                                    });

                                    try {
                                      await auth.signUpWithEmail(
                                        email: emailController.text,
                                        password: passwordController.text,
                                        context: context,
                                      );

                                      // Registration successful
                                      userFirestoreData.addAll({
                                        'Email':
                                            emailController.text.toString(),
                                      });

                                      isEmailChosen = true;
                                      setState(() {
                                        isEmailRegistering = false;
                                      });
                                      if (FirebaseAuth.instance.currentUser!
                                                  .email !=
                                              null ||
                                          _auth.currentUser!.email != null) {
                                        SystemChannels.textInput
                                            .invokeMethod('TextInput.hide');
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const EmailVerifyPage(),
                                            ),
                                          );
                                        }
                                      }
                                    } on FirebaseAuthException catch (e) {
                                      setState(() {
                                        isEmailRegistering = false;
                                      });

                                      if (e.code == 'email-already-in-use') {
                                        if (context.mounted) {
                                          mySnackBar(
                                            'This email is already in use.',
                                            context,
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          mySnackBar(
                                            e.message ?? 'An error occurred.',
                                            context,
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      setState(() {
                                        isEmailRegistering = false;
                                      });
                                      if (context.mounted) {
                                        mySnackBar(e.toString(), context);
                                      }
                                    }
                                  } else {
                                    mySnackBar(
                                      "Passwords do not match",
                                      context,
                                    );
                                  }
                                }
                              },
                              horizontalPadding: 24,
                              isLoading: isEmailRegistering,
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          isShowNumber = false;
                          isShowEmail = !isShowEmail;
                        });
                      },
                    ),

                    // PHONE NUMBER
                    const SizedBox(height: 12),
                    MyCollapseContainer(
                      headText: "Phone Number",
                      isShow: isShowNumber,
                      horizontalMargin: 20,
                      horizontalPadding: 12,
                      verticalPadding: 8,
                      bodyWidget: Form(
                        key: registerFormKey,
                        child: Column(
                          children: [
                            MyTextFormField(
                              hintText: "Phone Number",
                              controller: phoneController,
                              borderRadius: 16,
                              horizontalPadding: 24,
                              keyboardType: TextInputType.number,
                              autoFillHints: const [
                                AutofillHints.telephoneNumber
                              ],
                            ),
                            const SizedBox(height: 8),
                            MyButton(
                              text: phoneButtonText,
                              onTap: () async {
                                if (registerFormKey.currentState!.validate()) {
                                  try {
                                    setState(() {
                                      isPhoneRegistering = true;
                                      phoneButtonText = "Please Wait";
                                    });
                                    isNumberChosen = true;
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
                                        isPhoneRegistering = true;
                                      });
                                      await _auth.verifyPhoneNumber(
                                          phoneNumber:
                                              "+91 ${phoneController.text}",
                                          verificationCompleted: (_) {
                                            setState(() {
                                              isPhoneRegistering = false;
                                            });
                                          },
                                          verificationFailed: (e) {
                                            if (context.mounted) {
                                              mySnackBar(e.toString(), context);
                                            }
                                            setState(() {
                                              isPhoneRegistering = false;
                                              phoneButtonText = "SIGNUP";
                                            });
                                          },
                                          codeSent: (
                                            String verificationId,
                                            int? token,
                                          ) {
                                            SystemChannels.textInput
                                                .invokeMethod('TextInput.hide');
                                            Navigator.of(context).pop();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    NumberVerifyPage(
                                                  verificationId:
                                                      verificationId,
                                                  isLogging: false,
                                                ),
                                              ),
                                            );
                                            setState(() {
                                              isPhoneRegistering = false;
                                              phoneButtonText = "SIGNUP";
                                            });
                                          },
                                          codeAutoRetrievalTimeout: (e) {
                                            if (context.mounted) {
                                              mySnackBar(e.toString(), context);
                                            }
                                            setState(() {
                                              isPhoneRegistering = false;
                                              phoneButtonText = "SIGNUP";
                                            });
                                          });
                                    }
                                    setState(() {
                                      isPhoneRegistering = false;
                                      phoneButtonText = "SIGNUP";
                                    });
                                  } catch (e) {
                                    setState(() {
                                      isPhoneRegistering = false;
                                      phoneButtonText = "SIGNUP";
                                    });
                                    if (context.mounted) {
                                      mySnackBar(e.toString(), context);
                                    }
                                  }
                                }
                              },
                              horizontalPadding: 24,
                              isLoading: isPhoneRegistering,
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          isShowEmail = false;
                          isShowNumber = !isShowNumber;
                        });
                      },
                    ),

                    // GOOGLE
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          isShowEmail = false;
                          isShowNumber = false;
                          isGoogleRegistering = true;
                          googleText = "PLEASE WAIT";
                        });
                        try {
                          // Sign In With Google
                          await AuthMethods().signInWithGoogle(context);
                          await _auth.currentUser!.reload();
                          if (FirebaseAuth.instance.currentUser != null) {
                            userFirestoreData.addAll({
                              "Email": FirebaseAuth.instance.currentUser!.email,
                              "Name": FirebaseAuth
                                  .instance.currentUser!.displayName,
                              "uid": FirebaseAuth.instance.currentUser!.uid,
                              "Image":
                                  FirebaseAuth.instance.currentUser!.photoURL,
                            });
                            // SystemChannels.textInput.invokeMethod('TextInput.hide');
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: ((context) => const RegisterCredPage(
                                      // emailChosen: false,
                                      // numberChosen: false,
                                      // googleChosen: true,
                                      )),
                                ),
                              );
                            }
                          } else {}
                          setState(() {
                            isGoogleRegistering = false;
                          });
                        } on FirebaseAuthException catch (e) {
                          setState(() {
                            isShowEmail = false;
                            isShowNumber = false;
                            isGoogleRegistering = false;
                          });
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
                        child: isGoogleRegistering
                            ? const CircularProgressIndicator(
                                color: primaryDark,
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
                  flex: 1,
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
