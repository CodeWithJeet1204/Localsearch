import 'package:find_easy_user/page/auth/register_cred.dart';
import 'package:find_easy_user/page/main/main_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/button.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:find_easy_user/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberVerifyPage extends StatefulWidget {
  const NumberVerifyPage({
    super.key,
    required this.verificationId,
    required this.isLogging,
  });
  final String verificationId;
  final bool isLogging;

  @override
  State<NumberVerifyPage> createState() => _NumberVerifyPageState();
}

class _NumberVerifyPageState extends State<NumberVerifyPage> {
  final TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    bool isOTPVerifying = false;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(child: Container()),
              const Text(
                "An OTP has been sent to your Phone Number\nPls enter the OTP below",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryDark,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              MyTextFormField(
                hintText: "OTP - 6 Digits",
                controller: otpController,
                borderRadius: 12,
                horizontalPadding: 24,
                keyboardType: TextInputType.number,
                autoFillHints: const [AutofillHints.oneTimeCode],
              ),
              const SizedBox(height: 20),
              MyButton(
                text: "Verify",
                onTap: () async {
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
                      // userFirestoreData.addAll({
                      //   'Phone Number': auth.currentUser!.phoneNumber,
                      // });
                      setState(() {
                        isOTPVerifying = false;
                      });
                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: ((context) => widget.isLogging
                                ? const MainPage()
                                : const RegisterCredPage(
                                    // emailChosen: false,
                                    // numberChosen: true,
                                    // googleChosen: false,
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
                          mySnackBar(e.toString(), context);
                        }
                      });
                    }
                  } else {
                    mySnackBar("OTP should be 6 characters long", context);
                  }
                  return;
                },
                isLoading: isOTPVerifying,
                horizontalPadding: 24,
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ),
    );
  }
}
