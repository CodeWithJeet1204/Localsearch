import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch/page/auth/register_details_page.dart';
import 'package:localsearch/page/main/main_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/button.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:localsearch/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NumberVerifyPage extends StatefulWidget {
  const NumberVerifyPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.isLogging,
  });

  final String phoneNumber;
  final String verificationId;
  final bool isLogging;

  @override
  State<NumberVerifyPage> createState() => _NumberVerifyPageState();
}

class _NumberVerifyPageState extends State<NumberVerifyPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final otpController = TextEditingController();
  bool isOTPVerifying = false;

  // DISPOSE
  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  // VERIFY OTP
  Future<void> verifyOtp() async {
    if (otpController.text.length == 6) {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text,
      );
      try {
        setState(() {
          isOTPVerifying = true;
        });

        await auth.signInWithCredential(credential);
        if (auth.currentUser != null) {
          await auth.currentUser!.linkWithPhoneNumber(
            widget.phoneNumber,
          );

          if (auth.currentUser != null) {
            if (!widget.isLogging) {
              await store.collection('Users').doc(auth.currentUser!.uid).set({
                'Phone Number': widget.phoneNumber,
                'Registration': 'phone number',
                'Email': null,
                'Name': null,
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
            }
          }

          setState(() {
            isOTPVerifying = false;
          });

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => widget.isLogging
                    ? const MainPage()
                    : const RegisterDetailsPage(
                        emailPhoneGoogleChosen: 2,
                      ),
              ),
              (route) => false,
            );
          }
        }
      } catch (e) {
        setState(() {
          isOTPVerifying = false;
        });
        setState(() {
          if (context.mounted) {
            mySnackBar(
              e.toString(),
              context,
            );
          }
        });
      }
    } else {
      mySnackBar(
        'OTP should be 6 characters long',
        context,
      );
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                overflow: TextOverflow.ellipsis,
                'An OTP has been sent to your Phone Number\nPls enter the OTP below',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryDark,
                  fontSize: width * 0.045,
                ),
              ),
              const SizedBox(height: 10),
              MyTextFormField(
                hintText: 'OTP - 6 Digits',
                controller: otpController,
                borderRadius: 12,
                horizontalPadding: width * 0.066,
                keyboardType: TextInputType.number,
                autoFillHints: const [AutofillHints.oneTimeCode],
              ),
              const SizedBox(height: 20),
              isOTPVerifying
                  ? Container(
                      width: width * 0.89,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : MyButton(
                      text: 'VERIFY',
                      onTap: () async {
                        await verifyOtp();
                      },
                      isLoading: isOTPVerifying,
                      horizontalPadding: width * 0.066,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
