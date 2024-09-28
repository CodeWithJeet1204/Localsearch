import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:localsearch/page/auth/register_details_page.dart';
import 'package:localsearch/page/auth/verify/number_verify.dart';
import 'package:localsearch/page/main/main_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/button.dart';
import 'package:localsearch/widgets/collapse_container.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:localsearch/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final GlobalKey<FormState> signInEmailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> signInNumberFormKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  bool isGoogleSigningIn = false;
  bool isEmailSigningIn = false;
  bool isPhoneSigningIn = false;

  // DISPOSE
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // SIGN WITH EMAIL
  Future<void> signInWithEmail() async {
    if (signInEmailFormKey.currentState!.validate()) {
      try {
        setState(() {
          isEmailSigningIn = true;
        });

        final vendorExistsSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Users')
            .where('Email', isEqualTo: emailController.text)
            .where('Registration', isEqualTo: 'email')
            .get();

        if (vendorExistsSnap.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              isEmailSigningIn = false;
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
            .where('Registration', isEqualTo: 'email')
            .get();

        if (userExistsSnap.docs.isNotEmpty) {
          if (mounted) {
            await auth.signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );

            setState(() {
              isEmailSigningIn = false;
            });

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => MainPage(),
              ),
              (route) => false,
            );
            return mySnackBar(
              'Signed In',
              context,
            );
          }
          return;
        }

        await auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        await auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        if (auth.currentUser != null) {
          await store.collection('Users').doc(auth.currentUser!.uid).set({
            'Email': emailController.text,
            'Registration': 'email',
            'Name': null,
            'Phone Number': null,
            'recentShop': '',
            'followedShops': [],
            'wishlists': [],
            'likedProducts': [],
            'recentSearches': [],
            'recentProducts': [],
            'hasReviewedIndex': 0,
            // 'followedOrganizers': [],
            // 'wishlistEvents': [],
            // 'fcmToken': '',
          });

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const RegisterDetailsPage(
                  emailPhoneGoogleChosen: 1,
                ),
              ),
              (route) => false,
            );
          }
        } else {
          setState(() {
            isEmailSigningIn = false;
          });
          return mySnackBar(
            'Some error occured, try closing & opening the app',
            context,
          );
        }
      } catch (e) {
        setState(() {
          isEmailSigningIn = false;
        });
        if (mounted) {
          mySnackBar('Error: ${e.toString()}', context);
        }
      }

      setState(() {
        isEmailSigningIn = false;
      });
    }
  }

  // SIGN IN WITH PHONE
  Future<void> signInWithPhone() async {
    if (signInNumberFormKey.currentState!.validate()) {
      try {
        setState(() {
          isPhoneSigningIn = true;
        });

        final vendorExistsSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Users')
            .where('Phone Number', isEqualTo: '+91 ${phoneController.text}')
            .where('Registration', isEqualTo: 'phone number')
            .get();

        if (vendorExistsSnap.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              isPhoneSigningIn = false;
            });
            return mySnackBar(
              'This account was created in Business app, use a different Phone Number here',
              context,
            );
          }
        }

        final userExistsSnap = await store
            .collection('Users')
            .where('Phone Number', isGreaterThanOrEqualTo: phoneController.text)
            .where('Registration', isEqualTo: 'phone number')
            .get();

        if (userExistsSnap.docs.isNotEmpty) {
          if (mounted) {
            await auth.verifyPhoneNumber(
              phoneNumber: phoneController.text.contains('+91 ')
                  ? phoneController.text
                  : '+91 ${phoneController.text}',
              verificationCompleted: (_) {
                setState(() {
                  isPhoneSigningIn = false;
                });
              },
              verificationFailed: (e) {
                if (context.mounted) {
                  setState(() {
                    isPhoneSigningIn = false;
                  });
                  mySnackBar('Error: ${e.toString()}', context);
                }
              },
              codeSent: (
                String verificationId,
                int? token,
              ) {
                setState(() {
                  isPhoneSigningIn = false;
                });
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => NumberVerifyPage(
                      phoneNumber: phoneController.text.contains('+91 ')
                          ? phoneController.text
                          : '+91 ${phoneController.text}',
                      verificationId: verificationId,
                      isLogging: true,
                    ),
                  ),
                  (route) => false,
                );
              },
              codeAutoRetrievalTimeout: (e) {
                if (context.mounted) {
                  setState(() {
                    isPhoneSigningIn = false;
                  });
                  mySnackBar(e.toString(), context);
                }
              },
            );
          }
          return;
        }

        await auth.verifyPhoneNumber(
          phoneNumber: phoneController.text.contains('+91 ')
              ? phoneController.text
              : '+91 ${phoneController.text}',
          verificationCompleted: (_) {
            setState(() {
              isPhoneSigningIn = false;
            });
          },
          verificationFailed: (e) {
            if (context.mounted) {
              setState(() {
                isPhoneSigningIn = false;
              });
              mySnackBar('Error: ${e.toString()}', context);
            }
          },
          codeSent: (
            String verificationId,
            int? token,
          ) {
            setState(() {
              isPhoneSigningIn = false;
            });
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => NumberVerifyPage(
                  phoneNumber: phoneController.text.contains('+91 ')
                      ? phoneController.text
                      : '+91 ${phoneController.text}',
                  verificationId: verificationId,
                  isLogging: false,
                ),
              ),
              (route) => false,
            );
          },
          codeAutoRetrievalTimeout: (e) {
            if (context.mounted) {
              setState(() {
                isPhoneSigningIn = false;
              });
              mySnackBar('Error: ${e.toString()}', context);
            }
          },
        );

        // await store.collection('Users').doc(auth.currentUser!.uid).set({
        //   'Phone Number': phoneController.text.contains('+91')
        //       ? phoneController.text
        //       : '+91 ${phoneController.text}',
        //   'Registration': 'phone number',
        //   'Email': null,
        //   'Name': null,
        //   'recentShop': '',
        //   'followedShops': [],
        //   'wishlists': [],
        //   'likedProducts': [],
        //   'recentSearches': [],
        //   'recentProducts': [],
        //   // 'followedOrganizers': [],
        //   // 'wishlistEvents': [],
        //   // 'fcmToken': '',
        // });
        // if (mounted) {
        //   Navigator.of(context).pushAndRemoveUntil(
        //     MaterialPageRoute(
        //       builder: (context) => const RegisterDetailsPage(
        //         emailPhoneGoogleChosen: 2,
        //       ),
        //     ),
        //     (route) => false,
        //   );
        // }
      } catch (e) {
        setState(() {
          isPhoneSigningIn = false;
        });
        if (mounted) {
          mySnackBar(e.toString(), context);
        }
      }
    }
  }

  // SIGN IN WITH GOOGLE
  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        isGoogleSigningIn = true;
      });

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);

      if (auth.currentUser != null) {
        final vendorExistsSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Users')
            .where('Email', isEqualTo: auth.currentUser!.email)
            .where('Registration', isEqualTo: 'google')
            .get();

        if (vendorExistsSnap.docs.isNotEmpty) {
          await auth.signOut();
          if (mounted) {
            setState(() {
              isGoogleSigningIn = false;
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
            .where('Registration', isEqualTo: 'google')
            .get();

        if (userExistsSnap.docs.isNotEmpty &&
            (userCredential.additionalUserInfo == null
                ? true
                : !userCredential.additionalUserInfo!.isNewUser)) {
          if (mounted) {
            setState(() {
              isGoogleSigningIn = false;
            });
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => MainPage(),
              ),
              (route) => false,
            );
            return mySnackBar(
              'Signed In',
              context,
            );
          }
        }

        await store.collection('Users').doc(auth.currentUser!.uid).set({
          'Email': auth.currentUser!.email,
          'Registration': 'google',
          'Name': null,
          'Phone Number': null,
          'recentShop': '',
          'followedShops': [],
          'wishlists': [],
          'likedProducts': [],
          'recentSearches': [],
          'recentProducts': [],
          // 'followedOrganizers': [],
          // 'wishlistEvents': [],
          // 'fcmToken': '',
        });

        setState(() {
          isGoogleSigningIn = false;
        });

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const RegisterDetailsPage(
                emailPhoneGoogleChosen: 3,
              ),
            ),
            (route) => false,
          );
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
        isGoogleSigningIn = false;
      });
    } catch (e) {
      setState(() {
        isGoogleSigningIn = false;
      });
      print('error: ${e.toString()}');
      if (mounted) {
        mySnackBar(
          'Error: ${e.toString()}',
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
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            // EMAIL
            MyCollapseContainer(
              text: 'Email',
              width: width,
              children: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.066,
                  vertical: width * 0.0225,
                ),
                child: Form(
                  key: signInEmailFormKey,
                  child: Column(
                    children: [
                      MyTextFormField(
                        hintText: 'Email',
                        controller: emailController,
                        borderRadius: 16,
                        horizontalPadding: 0,
                        keyboardType: TextInputType.emailAddress,
                        autoFillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 8),
                      MyTextFormField(
                        hintText: 'Password',
                        controller: passwordController,
                        borderRadius: 16,
                        horizontalPadding: 0,
                        isPassword: true,
                        autoFillHints: const [AutofillHints.newPassword],
                      ),
                      const SizedBox(height: 8),
                      MyButton(
                        text: 'SIGN IN',
                        onTap: () async {
                          await signInWithEmail();
                        },
                        horizontalPadding: 0,
                        isLoading: isEmailSigningIn,
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
                await signInWithGoogle();
              },
              child: Container(
                width: width,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary2.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: width * 0.033,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: width * 0.035,
                ),
                child: isGoogleSigningIn
                    ? const CircularProgressIndicator(
                        color: primaryDark,
                      )
                    : Text(
                        "Sign In With GOOGLE",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryDark,
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 16),

            // PHONE NUMBER
            MyCollapseContainer(
              width: width,
              text: 'Phone Number',
              children: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.066,
                  vertical: width * 0.0225,
                ),
                child: Form(
                  key: signInNumberFormKey,
                  child: Column(
                    children: [
                      MyTextFormField(
                        hintText: 'Phone Number',
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        borderRadius: 12,
                        horizontalPadding: 0,
                        autoFillHints: [AutofillHints.telephoneNumber],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: MyButton(
                          text: 'SIGN IN',
                          onTap: () async {
                            await signInWithPhone();
                          },
                          horizontalPadding: 0,
                          isLoading: isPhoneSigningIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
          //               width: width,
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
          //               width: width,
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
          //                         isLoading: isPhoneSigningIn,
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
          //             //
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
