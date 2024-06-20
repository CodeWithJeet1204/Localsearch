// ignore_for_file: unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localy_user/firebase/auth_methods.dart';
import 'package:localy_user/page/auth/register_method_page.dart';
import 'package:localy_user/page/auth/verify/number_verify.dart';
import 'package:localy_user/page/main/main_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/utils/size.dart';
import 'package:localy_user/widgets/button.dart';
import 'package:localy_user/widgets/collapse_container.dart';
import 'package:localy_user/widgets/head_text.dart';
import 'package:localy_user/widgets/snack_bar.dart';
import 'package:localy_user/widgets/text_button.dart';
import 'package:localy_user/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final store = FirebaseFirestore.instance;
  final GlobalKey<FormState> emailLoginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> numberLoginFormKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  String phoneText = 'VERIFY';
  String googleText = 'Sign in with GOOGLE';
  bool isGoogleLogging = false;
  bool isEmailLogging = false;
  bool isPhoneLogging = false;

  // DISPOSE
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // LOGIN WITH EMAIL
  Future<void> loginWithEmail() async {
    if (emailLoginFormKey.currentState!.validate()) {
      // final businessDoc = await store
      //     .collection('Business')
      //     .doc('Owners')
      //     .collection('Users')
      //     .get();

      try {
        setState(() {
          isEmailLogging = true;
        });
        UserCredential? user =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.toString(),
          password: passwordController.text.toString(),
        );
        if (user != null) {
          if (mounted) {
            mySnackBar('Signed In', context);
          }
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: ((context) => const MainPage()),
              ),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            mySnackBar(
              'Some error occured',
              context,
            );
          }
        }
        setState(() {
          isEmailLogging = false;
        });
      } catch (e) {
        setState(() {
          isEmailLogging = false;
        });
        if (mounted) {
          mySnackBar(
            e.toString(),
            context,
          );
        }
      }
    }
  }

  // LOGIN WITH PHONE NUMBER
  Future<void> loginWithPhone() async {
    if (numberLoginFormKey.currentState!.validate()) {
      Future<bool> isPhoneRegistered() async {
        final phoneSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Users')
            .where('Phone Number', isEqualTo: phoneController.text)
            .get();

        return phoneSnap.docs.isNotEmpty;
      }

      Future<void> signInIfRegistered() async {
        final isRegistered = await isPhoneRegistered();
        if (isRegistered) {
          try {
            setState(() {
              isPhoneLogging = true;
            });
            // Register with Phone

            await FirebaseAuth.instance.verifyPhoneNumber(
                phoneNumber: '+91 ${phoneController.text}',
                timeout: const Duration(seconds: 120),
                verificationCompleted: (PhoneAuthCredential credential) async {
                  await FirebaseAuth.instance.signInWithCredential(credential);
                  setState(() {
                    isPhoneLogging = false;
                  });
                },
                verificationFailed: (e) {
                  if (context.mounted) {
                    mySnackBar(
                      e.toString(),
                      context,
                    );
                  }
                  setState(() {
                    isPhoneLogging = false;
                  });
                },
                codeSent: (String verificationId, int? token) {
                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NumberVerifyPage(
                        verificationId: verificationId,
                        isLogging: true,
                        phoneNumber: phoneController.text,
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

            setState(() {
              isPhoneLogging = false;
            });
          } catch (e) {
            setState(() {
              isPhoneLogging = false;
              phoneText = 'VERIFY';
            });
            if (mounted) {
              mySnackBar(e.toString(), context);
            }
          }
        } else {
          if (mounted) {
            mySnackBar(
              'You have not registered with this phone number',
              context,
            );
          }
        }
      }

      await signInIfRegistered();
    }
  }

  // LOGIN WITH GOOGLE
  Future<void> loginWithGoogle() async {
    try {
      setState(() {
        isGoogleLogging = true;
      });
      await AuthMethods().signInWithGoogle(context);
      if (FirebaseAuth.instance.currentUser != null) {
        setState(() {
          isGoogleLogging = false;
        });
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: ((context) => const MainPage()),
            ),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          mySnackBar('Some error occured!', context);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        mySnackBar(e.toString(), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final AuthMethods auth = AuthMethods();
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: MediaQuery.of(context).size.width < screenSize
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: width * 0.35),
                    const HeadText(
                      text: 'LOGIN',
                    ),
                    SizedBox(height: width * 0.3),
                    Column(
                      children: [
                        // EMAIL
                        MyCollapseContainer(
                          text: 'Email',
                          width: width,
                          children: Form(
                            key: emailLoginFormKey,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: width * 0.0225,
                                horizontal: width * 0.01,
                              ),
                              child: Column(
                                children: [
                                  MyTextFormField(
                                    hintText: 'Email',
                                    controller: emailController,
                                    borderRadius: 16,
                                    horizontalPadding: width * 0.066,
                                    keyboardType: TextInputType.emailAddress,
                                    autoFillHints: const [AutofillHints.email],
                                  ),
                                  const SizedBox(height: 8),
                                  MyTextFormField(
                                    hintText: 'Password',
                                    controller: passwordController,
                                    borderRadius: 16,
                                    horizontalPadding: width * 0.066,
                                    isPassword: true,
                                    autoFillHints: const [
                                      AutofillHints.password
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  MyButton(
                                    text: 'LOGIN',
                                    onTap: () async {
                                      await loginWithEmail();
                                    },
                                    horizontalPadding: width * 0.066,
                                    isLoading: isEmailLogging,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // PHONE NUMBER
                        MyCollapseContainer(
                          width: width,
                          text: 'Phone Number',
                          children: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0125,
                              vertical: width * 0.025,
                            ),
                            child: Form(
                              key: numberLoginFormKey,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.07,
                                    ),
                                    child: TextFormField(
                                      autofocus: false,
                                      controller: phoneController,
                                      keyboardType: TextInputType.number,
                                      maxLines: 1,
                                      minLines: 1,
                                      onTapOutside: (event) =>
                                          FocusScope.of(context).unfocus(),
                                      decoration: InputDecoration(
                                        prefixText: '+91 ',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.cyan.shade700,
                                          ),
                                        ),
                                        hintText: 'Phone Number',
                                      ),
                                      validator: (value) {
                                        if (value != null) {
                                          if (value.isEmpty) {
                                            return 'Please enter Phone Number';
                                          } else {
                                            if (value.length != 10) {
                                              return 'Number must be 10 chars long';
                                            }
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  MyButton(
                                    text: phoneText,
                                    onTap: () async {
                                      await loginWithPhone();
                                    },
                                    horizontalPadding: width * 0.066,
                                    isLoading: isPhoneLogging,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: width * 0.033),

                        // SIGN IN WITH GOOGLE
                        GestureDetector(
                          onTap: () async {
                            await loginWithGoogle();
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: width * 0.035,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: width * 0.033,
                            ),
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
                                    overflow: TextOverflow.ellipsis,
                                    googleText,
                                    style: TextStyle(
                                      color: buttonColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: width * 0.05,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: width * 0.33),

                    // DONT HAVE AN ACCOUNT ? TEXT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          overflow: TextOverflow.ellipsis,
                          'Don\'t have an account?',
                        ),
                        MyTextButton(
                          onPressed: () {
                            SystemChannels.textInput
                                .invokeMethod('TextInput.hide');
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterMethodPage()),
                            );
                          },
                          text: 'REGISTER',
                          textColor: buttonColor,
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: width * 0.66,
                    child: const HeadText(
                      text: 'LOGIN',
                    ),
                  ),
                  Container(
                    width: width * 0.33,
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              // EMAIL
                              MyCollapseContainer(
                                width: width,
                                text: 'Email',
                                children: Form(
                                  key: emailLoginFormKey,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width < screenSize
                                          ? width * 0.0125
                                          : width * 0.0,
                                      vertical: width * 0.025,
                                    ),
                                    child: Column(
                                      children: [
                                        MyTextFormField(
                                          hintText: 'Email',
                                          controller: emailController,
                                          borderRadius: 16,
                                          horizontalPadding: width < screenSize
                                              ? width * 0.066
                                              : width * 0.05,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autoFillHints: const [
                                            AutofillHints.email
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        MyTextFormField(
                                          hintText: 'Password',
                                          controller: passwordController,
                                          borderRadius: 16,
                                          horizontalPadding: width < screenSize
                                              ? width * 0.066
                                              : width * 0.05,
                                          isPassword: true,
                                          autoFillHints: const [
                                            AutofillHints.password
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        MyButton(
                                          text: 'LOGIN',
                                          onTap: () async {
                                            await loginWithEmail();
                                          },
                                          horizontalPadding: width < screenSize
                                              ? width * 0.066
                                              : width * 0.05,
                                          isLoading: isEmailLogging,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // PHONE NUMBER
                              MyCollapseContainer(
                                width: width,
                                text: 'Phone Number',
                                children: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width < screenSize
                                        ? width * 0.0125
                                        : width * 0.0,
                                    vertical: width * 0.025,
                                  ),
                                  child: Form(
                                    key: numberLoginFormKey,
                                    child: Column(
                                      children: [
                                        MyTextFormField(
                                          hintText: 'Phone Number',
                                          controller: phoneController,
                                          borderRadius: 16,
                                          horizontalPadding: width < screenSize
                                              ? width * 0.066
                                              : width * 0.05,
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
                                                });
                                                // Register with Phone
                                                if (phoneController.text
                                                    .contains('+91')) {
                                                  await auth.phoneSignIn(
                                                      context,
                                                      ' ${phoneController.text}');
                                                } else if (phoneController.text
                                                    .contains('+91 ')) {
                                                  await auth.phoneSignIn(
                                                      context,
                                                      phoneController.text);
                                                } else {
                                                  setState(() {
                                                    isPhoneLogging = true;
                                                  });
                                                  await _auth.verifyPhoneNumber(
                                                      phoneNumber:
                                                          '+91 ${phoneController.text}',
                                                      verificationCompleted:
                                                          (_) {
                                                        setState(() {
                                                          isPhoneLogging =
                                                              false;
                                                        });
                                                      },
                                                      verificationFailed: (e) {
                                                        if (context.mounted) {
                                                          mySnackBar(
                                                            e.toString(),
                                                            context,
                                                          );
                                                        }
                                                        setState(() {
                                                          isPhoneLogging =
                                                              false;
                                                        });
                                                      },
                                                      codeSent: (String
                                                              verificationId,
                                                          int? token) {
                                                        SystemChannels.textInput
                                                            .invokeMethod(
                                                                'TextInput.hide');
                                                        Navigator.of(context)
                                                            .pop();
                                                        Navigator.of(context)
                                                            .push(
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                NumberVerifyPage(
                                                              verificationId:
                                                                  verificationId,
                                                              isLogging: true,
                                                              phoneNumber:
                                                                  phoneController
                                                                      .text,
                                                            ),
                                                          ),
                                                        );
                                                        setState(() {
                                                          isPhoneLogging =
                                                              false;
                                                        });
                                                      },
                                                      codeAutoRetrievalTimeout:
                                                          (e) {
                                                        if (context.mounted) {
                                                          mySnackBar(
                                                            e.toString(),
                                                            context,
                                                          );
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
                                                  mySnackBar(
                                                    e.toString(),
                                                    context,
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          horizontalPadding: width < screenSize
                                              ? width * 0.066
                                              : width * 0.05,
                                          isLoading: isPhoneLogging,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // SIGN IN WITH GOOGLE
                              // GestureDetector(
                              //     onTap: () async {
                              //       try {
                              //         setState(() {
                              //           isGoogleLogging = true;
                              //         });
                              //         // Sign In With Google
                              //         await AuthMethods()
                              //             .signInWithGoogle(context);
                              //         // SystemChannels.textInput
                              //         //     .invokeMethod('TextInput.hide');
                              //         if (FirebaseAuth.instance.currentUser !=
                              //             null) {
                              //           setState(() {});
                              //         } else {
                              //           if (context.mounted) {
                              //             mySnackBar(
                              //                 context, 'Some error occured!');
                              //           }
                              //         }
                              //       } on FirebaseAuthException catch (e) {
                              //         if (context.mounted) {
                              //           mySnackBar(e.toString(), context);
                              //         }
                              //       }
                              //     },
                              //     child: Container(
                              //       margin: EdgeInsets.symmetric(
                              //         horizontal: width < screenSize
                              //             ? width * 0.035
                              //             : width * 0.0275,
                              //       ),
                              //       padding: EdgeInsets.symmetric(
                              //         vertical: width < screenSize
                              //             ? width * 0.033
                              //             : width * 0.0125,
                              //       ),
                              //       alignment: Alignment.center,
                              //       width: double.infinity,
                              //       decoration: BoxDecoration(
                              //         borderRadius: BorderRadius.circular(10),
                              //         color: primary2.withOpacity(0.75),
                              //       ),
                              //       child: isGoogleLogging
                              //           ? const Center(
                              //               child: CircularProgressIndicator(
                              //                 color: primaryDark,
                              //               ),
                              //             )
                              //           : Text(
                              //               googleText,
                              //               style: TextStyle(
                              //                 color: buttonColor,
                              //                 fontWeight: FontWeight.w600,
                              //                 fontSize: width < screenSize
                              //                     ? width * 0.05
                              //                     : width * 0.025,
                              //               ),
                              //             ),
                              //     ),
                              //   ),
                            ],
                          ),
                          const SizedBox(height: 120),

                          // DONT HAVE AN ACCOUNT ? TEXT
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Don\'t have an account?',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                MyTextButton(
                                  onPressed: () {
                                    SystemChannels.textInput
                                        .invokeMethod('TextInput.hide');
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterMethodPage()),
                                    );
                                  },
                                  text: 'REGISTER',
                                  textColor: buttonColor,
                                  fontSize: width * 0.0125,
                                ),
                              ],
                            ),
                          ),
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
