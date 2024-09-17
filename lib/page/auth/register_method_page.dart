import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch_user/firebase/auth_methods.dart';
import 'package:localsearch_user/page/auth/login_page.dart';
import 'package:localsearch_user/page/auth/register_details_page.dart';
import 'package:localsearch_user/page/auth/verify/email_verify.dart';
import 'package:localsearch_user/page/auth/verify/number_verify.dart';
import 'package:localsearch_user/page/main/main_page.dart';
import 'package:localsearch_user/utils/colors.dart';
import 'package:localsearch_user/widgets/button.dart';
import 'package:localsearch_user/widgets/collapse_container.dart';
import 'package:localsearch_user/widgets/head_text.dart';
import 'package:localsearch_user/widgets/snack_bar.dart';
import 'package:localsearch_user/widgets/text_button.dart';
import 'package:localsearch_user/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterMethodPage extends StatefulWidget {
  const RegisterMethodPage({super.key});

  @override
  State<RegisterMethodPage> createState() => _RegisterMethodPageState();
}

class _RegisterMethodPageState extends State<RegisterMethodPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final GlobalKey<FormState> registerEmailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> registerNumberFormKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  String phoneText = 'SIGNUP';
  String googleText = 'Signup With GOOGLE';
  bool isGoogleRegistering = false;
  bool isEmailRegistering = false;
  bool isPhoneRegistering = false;

  // DISPOSE
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // REGISTER WITH EMAIL
  Future<void> registerWithEmail() async {
    if (passwordController.text == confirmPasswordController.text) {
      if (registerEmailFormKey.currentState!.validate()) {
        try {
          setState(() {
            isEmailRegistering = true;
          });

          final vendorExistsSnap = await store
              .collection('Business')
              .doc('Owners')
              .collection('Users')
              .where('Email', isEqualTo: emailController.text)
              .where('registration', isEqualTo: 'email')
              .get();

          if (vendorExistsSnap.docs.isNotEmpty) {
            if (mounted) {
              setState(() {
                isEmailRegistering = false;
              });
              return mySnackBar(
                'This account was created in Business app, use a different Email here',
                context,
              );
            }
          }

          final userExistsSnap = await store
              .collection('Users')
              .where('Email', isEqualTo: emailController.text)
              .where('registration', isEqualTo: 'email')
              .get();

          if (userExistsSnap.docs.isNotEmpty) {
            if (mounted) {
              setState(() {
                isEmailRegistering = false;
              });
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => MainPage(),
                ),
                (route) => false,
              );
              return mySnackBar(
                'This account is already registered. Signing you in',
                context,
              );
            }
          }

          await AuthMethods().signUpWithEmail(
            email: emailController.text,
            password: passwordController.text,
            context: context,
          );

          if (auth.currentUser != null) {
            // final userExistsSnap = await store
            //     .collection('Users')
            //     .doc(auth.currentUser!.uid)
            //     .get();

            // if (userExistsSnap.exists) {
            //   Navigator.of(context).pushAndRemoveUntil(
            //     MaterialPageRoute(
            //       builder: (context) => LoginPage(),
            //     ),
            //     (route) => false,
            //   );
            //   if (mounted) {
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => MainPage(),
            //       ),
            //     );
            //     return mySnackBar(
            //       'You have already registered before, logging you in',
            //       context,
            //     );
            //   }
            // }

            await store.collection('Users').doc(auth.currentUser!.uid).set({
              'Email': emailController.text,
              'registration': 'email',
              'Name': null,
              'Phone Number': null,
              'recentShop': '',
              'followedShops': [],
              'wishlists': [],
              'likedProducts': [],
              'recentSearches': [],
              'recentProducts': [],
              'hasReviewed': false,
              'hasReviewedIndex': 0,
              // 'followedOrganizers': [],
              // 'wishlistEvents': [],
              // 'fcmToken': '',
            });
          } else {
            setState(() {
              isEmailRegistering = false;
            });
          }
        } catch (e) {
          setState(() {
            isEmailRegistering = false;
          });
          if (mounted) {
            mySnackBar(
              'Error: ${e.toString()}',
              context,
            );
          }
        }

        setState(() {
          isEmailRegistering = false;
        });

        if (auth.currentUser!.email != null) {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          if (context.mounted) {
            if (mounted) {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EmailVerifyPage(),
                ),
              );
            }
          }
        }
      } else {
        mySnackBar(
          'Passwords do not match',
          context,
        );
      }
    } else {
      mySnackBar(
        'Passwords dont match, check again!',
        context,
      );
    }
  }

  // REGISTER WITH PHONE
  Future<void> registerWithPhone() async {
    if (registerNumberFormKey.currentState!.validate()) {
      try {
        setState(() {
          isPhoneRegistering = true;
        });

        final vendorExistsSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Users')
            .where('Phone Number', isEqualTo: '+91 ${phoneController.text}')
            .where('registration', isEqualTo: 'phone number')
            .get();

        if (vendorExistsSnap.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              isPhoneRegistering = false;
            });
            return mySnackBar(
              'This account was created in Business app, use a different Phone Number here',
              context,
            );
          }
        }

        final userExistsSnap = await store
            .collection('Users')
            .where('Phone Number', isEqualTo: '+91 ${phoneController.text}')
            .where('registration', isEqualTo: 'google')
            .get();

        if (userExistsSnap.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              isPhoneRegistering = false;
            });
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Already Registered'),
                content: Text(
                  'This account is already registered. Login with this number',
                ),
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => LoginPage(),
              ),
              (route) => false,
            );
          }
          return;
        }

        await auth.verifyPhoneNumber(
            phoneNumber: '+91 ${phoneController.text}',
            verificationCompleted: (_) {
              setState(() {
                isPhoneRegistering = false;
              });
            },
            verificationFailed: (e) {
              if (context.mounted) {
                setState(() {
                  isPhoneRegistering = false;
                  phoneText = 'SIGNUP';
                });
                mySnackBar(
                  e.toString(),
                  context,
                );
              }
            },
            codeSent: (
              String verificationId,
              int? token,
            ) {
              setState(() {
                isPhoneRegistering = false;
                phoneText = 'SIGNUP';
              });
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NumberVerifyPage(
                    verificationId: verificationId,
                    isLogging: false,
                    phoneNumber: phoneController.text,
                  ),
                ),
              );
            },
            codeAutoRetrievalTimeout: (e) {
              if (context.mounted) {
                setState(() {
                  isPhoneRegistering = false;
                  phoneText = 'SIGNUP';
                });
                mySnackBar(
                  e.toString(),
                  context,
                );
              }
            });
      } catch (e) {
        setState(() {
          isPhoneRegistering = false;
          phoneText = 'SIGNUP';
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

  // REGISTER WITH GOOGLE
  Future<void> registerWithGoogle(FirebaseAuth auth) async {
    try {
      setState(() {
        isGoogleRegistering = true;
      });
      await AuthMethods().signInWithGoogle(context);
      await auth.currentUser!.reload();
      if (auth.currentUser != null) {
        final vendorExistsSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Users')
            .where('Email', isEqualTo: auth.currentUser!.email)
            .where('registration', isEqualTo: 'google')
            .get();

        if (vendorExistsSnap.docs.isNotEmpty) {
          await auth.signOut();
          if (mounted) {
            setState(() {
              isGoogleRegistering = false;
            });
            return mySnackBar(
              'This account was created in Business app, use a different Google Account here',
              context,
            );
          }
        }

        final userExistsSnap = await store
            .collection('Users')
            .where('Email', isEqualTo: auth.currentUser!.email)
            .where('registration', isEqualTo: 'google')
            .get();

        if (userExistsSnap.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              isGoogleRegistering = false;
            });
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => MainPage(),
              ),
              (route) => false,
            );
            return mySnackBar(
              'This account is already registered. Signing you in',
              context,
            );
          }
        }

        await store.collection('Users').doc(auth.currentUser!.uid).set({
          'Email': emailController.text.toString(),
          'registration': 'google',
          'Name': null,
          'Phone Number': null,
          'recentShop': '',
          'followedShops': [],
          'wishlists': [],
          'likedProducts': [],
          'recentSearches': [],
          'recentProducts': [],
          'hasReviewed': false,
          'hasReviewedIndex': 0,
          // 'followedOrganizers': [],
          // 'wishlistEvents': [],
          // 'fcmToken': '',
        });

        setState(() {
          isGoogleRegistering = false;
        });
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        if (context.mounted) {
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegisterDetailsPage(
                  emailPhoneGoogleChosen: 3,
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          mySnackBar(
            'Some error occured\nTry signing with Email / Phone Number',
            context,
          );
        }
      }
      setState(() {
        isGoogleRegistering = false;
      });
    } catch (e) {
      setState(() {
        isGoogleRegistering = false;
      });
      if (mounted) {
        mySnackBar(
          e.toString(),
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: /*width < screenSize
            ?*/
              SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // REGISTER HEADTEXT
            SizedBox(height: width * 0.35),
            const HeadText(
              text: 'REGISTER',
            ),
            SizedBox(height: width * 0.3),

            Column(
              children: [
                // EMAIL
                MyCollapseContainer(
                  width: MediaQuery.of(context).size.width,
                  text: 'Email',
                  children: Padding(
                    padding: EdgeInsets.all(width * 0.0225),
                    child: Form(
                      key: registerEmailFormKey,
                      child: Column(
                        children: [
                          // EMAIL
                          MyTextFormField(
                            hintText: 'Email',
                            controller: emailController,
                            borderRadius: 16,
                            horizontalPadding:
                                MediaQuery.of(context).size.width * 0.066,
                            keyboardType: TextInputType.emailAddress,
                            autoFillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 8),

                          // PASSWORD
                          MyTextFormField(
                            hintText: 'Password',
                            controller: passwordController,
                            borderRadius: 16,
                            horizontalPadding:
                                MediaQuery.of(context).size.width * 0.066,
                            isPassword: true,
                            autoFillHints: const [AutofillHints.newPassword],
                          ),
                          MyTextFormField(
                            hintText: 'Confirm Password',
                            controller: confirmPasswordController,
                            borderRadius: 16,
                            horizontalPadding:
                                MediaQuery.of(context).size.width * 0.066,
                            verticalPadding: 8,
                            isPassword: true,
                            autoFillHints: const [AutofillHints.newPassword],
                          ),
                          const SizedBox(height: 8),
                          MyButton(
                            text: 'SIGNUP',
                            onTap: () async {
                              await registerWithEmail();
                            },
                            horizontalPadding: width * 0.066,
                            isLoading: isEmailRegistering,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // PHONE NUMBER
                MyCollapseContainer(
                  width: MediaQuery.of(context).size.width,
                  text: 'Phone Number',
                  children: Padding(
                    padding: EdgeInsets.all(width * 0.0225),
                    child: Form(
                      key: registerNumberFormKey,
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
                              onTapOutside: (event) =>
                                  FocusScope.of(context).unfocus(),
                              maxLines: 1,
                              minLines: 1,
                              decoration: InputDecoration(
                                prefixText: '+91 ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                              await registerWithPhone();
                            },
                            horizontalPadding:
                                MediaQuery.of(context).size.width * 0.066,
                            isLoading: isPhoneRegistering,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // GOOGLE
                GestureDetector(
                  onTap: () async {
                    await registerWithGoogle(
                      auth,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).size.width * 0.035,
                      0,
                      MediaQuery.of(context).size.width * 0.035,
                      MediaQuery.of(context).viewInsets.bottom,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.width * 0.033,
                    ),
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
                            overflow: TextOverflow.ellipsis,
                            googleText,
                            style: TextStyle(
                              color: buttonColor,
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: width * 0.33),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      overflow: TextOverflow.ellipsis,
                      'Already have an account?',
                    ),
                    MyTextButton(
                      onPressed: () {
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                      text: 'SIGN IN',
                      textColor: buttonColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      )
          // : Row(
          //     children: [
          //       Container(
          //         width: width * 0.66,
          //         alignment: Alignment.center,
          //         child: const HeadText(
          //           text: 'REGISTER',
          //         ),
          //       ),
          //       Container(
          //         width: width * 0.33,
          //         alignment: Alignment.center,
          //         child: Column(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             // EMAIL
          //             MyCollapseContainer(
          //               width: MediaQuery.of(context).size.width,
          //               text: 'Email',
          //               children: Padding(
          //                 padding: EdgeInsets.symmetric(
          //                   horizontal: width < screenSize
          //                       ? width * 0.0125
          //                       : width * 0.0,
          //                   vertical: width * 0.025,
          //                 ),
          //                 child: Form(
          //                   key: registerEmailFormKey,
          //                   child: Column(
          //                     children: [
          //                       // EMAIL
          //                       MyTextFormField(
          //                         hintText: 'Email',
          //                         controller: emailController,
          //                         borderRadius: 16,
          //                         horizontalPadding: width < screenSize
          //                             ? width * 0.066
          //                             : width * 0.05,
          //                         keyboardType: TextInputType.emailAddress,
          //                         autoFillHints: const [AutofillHints.email],
          //                       ),
          //                       const SizedBox(height: 8),

          //                       // PASSWORD
          //                       MyTextFormField(
          //                         hintText: 'Password',
          //                         controller: passwordController,
          //                         borderRadius: 16,
          //                         horizontalPadding: width < screenSize
          //                             ? width * 0.066
          //                             : width * 0.05,
          //                         isPassword: true,
          //                         autoFillHints: const [
          //                           AutofillHints.newPassword
          //                         ],
          //                       ),
          //                       MyTextFormField(
          //                         hintText: 'Confirm Password',
          //                         controller: confirmPasswordController,
          //                         borderRadius: 16,
          //                         horizontalPadding: width < screenSize
          //                             ? width * 0.066
          //                             : width * 0.05,
          //                         verticalPadding: 8,
          //                         isPassword: true,
          //                         autoFillHints: const [
          //                           AutofillHints.newPassword
          //                         ],
          //                       ),
          //                       const SizedBox(height: 8),
          //                       MyButton(
          //                         text: 'SIGNUP',
          //                         onTap: () async {
          //                           await registerWithEmail();
          //                         },
          //                         horizontalPadding: width < screenSize
          //                             ? width * 0.066
          //                             : width * 0.05,
          //                         isLoading: isEmailRegistering,
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               ),
          //             ),
          //             const SizedBox(height: 12),

          //             // PHONE NUMBER
          //             MyCollapseContainer(
          //               width: MediaQuery.of(context).size.width,
          //               text: 'Phone Number',
          //               children: Padding(
          //                 padding: EdgeInsets.all(width * 0.0225),
          //                 child: Form(
          //                   key: registerNumberFormKey,
          //                   child: Column(
          //                     children: [
          //                       MyTextFormField(
          //                         hintText: 'Phone Number',
          //                         controller: phoneController,
          //                         borderRadius: 16,
          //                         horizontalPadding: width < screenSize
          //                             ? width * 0.066
          //                             : width * 0.05,
          //                         keyboardType: TextInputType.number,
          //                         autoFillHints: const [
          //                           AutofillHints.telephoneNumber
          //                         ],
          //                       ),
          //                       const SizedBox(height: 8),
          //                       MyButton(
          //                         text: phoneText,
          //                         onTap: () async {
          //                           await registerWithPhone();
          //                         },
          //                         horizontalPadding: width < screenSize
          //                             ? width * 0.066
          //                             : width * 0.05,
          //                         isLoading: isPhoneRegistering,
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               ),
          //             ),
          //             const SizedBox(height: 16),

          //             // GOOGLE
          //             // GestureDetector(
          //             //   onTap: () async {
          //             //     setState(() {
          //             //       isGoogleRegistering = true;
          //             //     });
          //             //     try {
          //             // Sign In With Google
          //             //       signInMethodProvider.chooseGoogle();
          //             //       await AuthMethods().signInWithGoogle(context);
          //             //       await _auth.currentUser!.reload();
          //             //       if (auth.currentUser != null) {
          //             //         await store
          //             //             .collection('Business')
          //             //             .doc('Owners')
          //             //             .collection('Users')
          //             //             .doc(_auth.currentUser!.uid)
          //             //             .set({
          //             //           'Email':
          //             //               auth.currentUser!.email,
          //             //           'Name': FirebaseAuth
          //             //               .instance.currentUser!.displayName,
          //             //           'Image': null,
          //             //           'Phone Number': null,
          //             //         });
          //             //         await store
          //             //             .collection('Business')
          //             //             .doc('Owners')
          //             //             .collection('Shops')
          //             //             .doc(_auth.currentUser!.uid)
          //             //             .update({
          //             //           'Name': null,
          //             //           'Views': null,
          //             //           'GSTNumber': null,
          //             //           'Address': null,
          //             //           'Special Note': null,
          //             //           'Industry': null,
          //             //           'Image': null,
          //             //           'Type': null,
          //             //           'MembershipName': null,
          //             //           'MembershipDuration': null,
          //             //           'MembershipTime': null,
          //             //         });
          //             //         SystemChannels.textInput.invokeMethod('TextInput.hide');
          //             //         if (context.mounted) {
          //             //           Navigator.of(context).pop();
          //             //           Navigator.of(context).push(
          //             //             MaterialPageRoute(
          //             //               builder: ((context) =>
          //             //                   const UserRegisterDetailsPage()),
          //             //             ),
          //             //           );
          //             //         }
          //             //       } else {
          //             //         if (context.mounted) {
          //             //           mySnackBar(
          //             //             context,
          //             //             'Some error occured\nTry signing with Email / Phone Number',
          //             //           );
          //             //         }
          //             //       }
          //             //       setState(() {
          //             //         isGoogleRegistering = false;
          //             //       });
          //             //      } catch (e) {
          //             //        setState(() {
          //             //          isGoogleRegistering = false;
          //             //        });
          //             //        if (context.mounted) {
          //             //          mySnackBar(context, e.toString());
          //             //        }
          //             //      }
          //             //    },
          //             //   child: Container(
          //             //     margin: EdgeInsets.symmetric(
          //             //       horizontal: width < screenSize
          //             //           ? width * 0.035
          //             //           : width * 0.0275,
          //             //     ),
          //             //     padding: EdgeInsets.symmetric(
          //             //       vertical: width < screenSize
          //             //           ? width * 0.033
          //             //           : width * 0.0125,
          //             //     ),
          //             //     alignment: Alignment.center,
          //             //     width: double.infinity,
          //             //     decoration: BoxDecoration(
          //             //       borderRadius: BorderRadius.circular(10),
          //             //       color: primary2.withOpacity(0.75),
          //             //     ),
          //             //     child: isGoogleRegistering
          //             //         ? const Center(
          //             //             child: CircularProgressIndicator(
          //             //               color: primaryDark,
          //             //             ),
          //             //           )
          //             //         : Text(
          //             //             googleText,
          //             //             style: TextStyle(
          //             //               color: buttonColor,
          //             //               fontWeight: FontWeight.w600,
          //             //               fontSize: width < screenSize
          //             //                   ? width * 0.05
          //             //                   : width * 0.025,
          //             //             ),
          //             //           ),
          //             //   ),
          //             // ),

          //             Row(
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               crossAxisAlignment: CrossAxisAlignment.center,
          //               children: [
          //                 const Text(
          //                   overflow: TextOverflow.ellipsis,
          //                   'Already have an account?',
          //                 ),
          //                 MyTextButton(
          //                   onPressed: () {
          //                     SystemChannels.textInput
          //                         .invokeMethod('TextInput.hide');
          //                     Navigator.of(context).pop();
          //                     Navigator.of(context).push(
          //                       MaterialPageRoute(
          //                           builder: (context) => const LoginPage()),
          //                     );
          //                   },
          //                   text: 'SIGN IN',
          //                   textColor: buttonColor,
          //                 ),
          //               ],
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),

          ),
    );
  }
}
