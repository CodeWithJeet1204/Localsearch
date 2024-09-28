// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:localsearch/firebase/auth_methods.dart';
// import 'package:localsearch/page/auth/register_details_page.dart';
// import 'package:localsearch/page/main/main_page.dart';
// import 'package:localsearch/utils/colors.dart';
// import 'package:localsearch/widgets/button.dart';
// import 'package:localsearch/widgets/snack_bar.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class EmailVerifyPage extends StatefulWidget {
//   const EmailVerifyPage({
//     super.key,
//     this.updatingEmail,
//   });

//   final String? updatingEmail;

//   @override
//   State<EmailVerifyPage> createState() => _EmailVerifyPageState();
// }

// class _EmailVerifyPageState extends State<EmailVerifyPage> {
//   final auth = FirebaseAuth.instance;
//   final store = FirebaseFirestore.instance;
//   final authMethods = AuthMethods();
//   bool checkingEmailVerified = false;
//   bool canResendEmail = false;
//   Timer? timer;
//   bool isEmailVerified = false;

//   // INIT STATE
//   @override
//   void initState() {
//     super.initState();
//     widget.updatingEmail == null
//         ? sendEmailVerification()
//         : auth.currentUser!.verifyBeforeUpdateEmail(widget.updatingEmail!);

//     isEmailVerified = auth.currentUser!.emailVerified;

//     if (!isEmailVerified) {
//       timer = Timer.periodic(const Duration(seconds: 2), (_) async {
//         await checkEmailVerification(fromButton: false);
//       });
//     } else {
//       if (mounted) {
//         if (widget.updatingEmail == null) {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(
//               builder: ((context) => const RegisterDetailsPage(
//                     emailPhoneGoogleChosen: 1,
//                   )),
//             ),
//             (route) => false,
//           );
//         } else {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(
//               builder: ((context) => const MainPage()),
//             ),
//             (route) => false,
//           );
//         }
//       }
//     }
//   }

//   // CHECK EMAIL VERIFICATION
//   Future<void> checkEmailVerification({bool? fromButton}) async {
//     await auth.currentUser!.reload();

//     isEmailVerified = auth.currentUser!.emailVerified;

//     if (isEmailVerified) {
//       if (mounted) {
//         if (widget.updatingEmail == null) {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(
//               builder: ((context) => const RegisterDetailsPage(
//                     emailPhoneGoogleChosen: 1,
//                   )),
//             ),
//             (route) => false,
//           );
//         } else {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(
//               builder: ((context) => const MainPage()),
//             ),
//             (route) => false,
//           );
//         }
//       }
//     } else if (fromButton != null) {
//       if (mounted) {
//         mySnackBar('Pls verify your email', context);
//       }
//     }
//   }

//   // SEND EMAIL VERIFICATION
//   Future<void> sendEmailVerification() async {
//     try {
//       final user = auth.currentUser!;
//       await user.sendEmailVerification();
//       if (mounted) {
//         mySnackBar(
//           'Verification Email Sent',
//           context,
//         );
//       }

//       setState(() {
//         canResendEmail = false;
//       });
//       await Future.delayed(const Duration(seconds: 5));
//       setState(() {
//         canResendEmail = true;
//       });
//     } catch (e) {
//       if (mounted) {
//         mySnackBar(
//           e.toString(),
//           context,
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               auth.currentUser!.email!,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: primaryDark,
//                 fontSize: MediaQuery.of(context).size.width * 0.05,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             Text(
//               'An email has been sent to your account, pls click on it\nTo verify your account\n\nIf you want to resend email click below\n\n(It may take some time for email to arrive)',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: primaryDark,
//                 fontSize: MediaQuery.of(context).size.width * 0.045,
//               ),
//             ),
//             const SizedBox(height: 20),
//             MyButton(
//               text: 'I have Verified my Email',
//               onTap: () async {
//                 await checkEmailVerification(fromButton: true);
//               },
//               isLoading: checkingEmailVerified,
//               horizontalPadding: MediaQuery.of(context).size.width * 0.066,
//             ),
//             const SizedBox(height: 20),
//             Opacity(
//               opacity: canResendEmail ? 1 : 0.5,
//               child: MyButton(
//                 text: 'Resend Email',
//                 onTap: canResendEmail
//                     ? () async {
//                         widget.updatingEmail == null
//                             ? await sendEmailVerification()
//                             : await auth.currentUser!
//                                 .verifyBeforeUpdateEmail(widget.updatingEmail!);
//                       }
//                     : () {
//                         mySnackBar(
//                           'Wait for 5 seconds',
//                           context,
//                         );
//                       },
//                 isLoading: checkingEmailVerified,
//                 horizontalPadding: MediaQuery.of(context).size.width * 0.066,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
