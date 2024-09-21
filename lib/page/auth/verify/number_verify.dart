import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch/page/auth/register_details_page.dart';
import 'package:localsearch/page/main/main_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/button.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:localsearch/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberVerifyPage extends StatefulWidget {
  const NumberVerifyPage({
    super.key,
    required this.verificationId,
    required this.isLogging,
    required this.phoneNumber,
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
          await auth.currentUser!
              .linkWithPhoneNumber('+91 ${widget.phoneNumber}');
          if (!widget.isLogging) {
            await store.collection('Users').doc(auth.currentUser!.uid).set({
              'Phone Number': '+91 ${widget.phoneNumber}',
              'registration': 'phone number',
              'Email': null,
              'Name': null,
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
          }
        }

        setState(() {
          isOTPVerifying = false;
        });
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: ((context) => widget.isLogging
                  ? const MainPage()
                  : const RegisterDetailsPage(
                      emailPhoneGoogleChosen: 2,
                    )),
            ),
          );
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(child: Container()),
              Text(
                overflow: TextOverflow.ellipsis,
                'An OTP has been sent to your Phone Number\nPls enter the OTP below',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryDark,
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                ),
              ),
              const SizedBox(height: 10),
              MyTextFormField(
                hintText: 'OTP - 6 Digits',
                controller: otpController,
                borderRadius: 12,
                horizontalPadding: MediaQuery.of(context).size.width * 0.066,
                keyboardType: TextInputType.number,
                autoFillHints: const [AutofillHints.oneTimeCode],
              ),
              const SizedBox(height: 20),
              isOTPVerifying
                  ? Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.055,
                        vertical: 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: buttonColor,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: white),
                      ),
                    )
                  : MyButton(
                      text: 'VERIFY',
                      onTap: () async {
                        await verifyOtp();
                      },
                      isLoading: isOTPVerifying,
                      horizontalPadding:
                          MediaQuery.of(context).size.width * 0.066,
                    ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ),
    );
  }
}
