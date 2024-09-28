import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/page/main/main_page.dart';
import 'package:localsearch/widgets/button.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:localsearch/widgets/text_form_field.dart';

class SignInEmailAfterForgetPassword extends StatefulWidget {
  const SignInEmailAfterForgetPassword({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<SignInEmailAfterForgetPassword> createState() =>
      _SignInEmailAfterForgetPasswordState();
}

class _SignInEmailAfterForgetPasswordState
    extends State<SignInEmailAfterForgetPassword> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isEmailLogging = false;

  // LOGIN WITH EMAIL
  Future<void> loginWithEmail() async {
    if (passwordController.text.length > 6) {
      try {
        setState(() {
          isEmailLogging = true;
        });
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.toString(),
          password: passwordController.text.toString(),
        );
        if (mounted) {
          mySnackBar('Signed In', context);
        }
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainPage(),
            ),
            (route) => false,
          );
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In With Email'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            width * 0.0125,
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;

            return SingleChildScrollView(
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
                    autoFillHints: const [AutofillHints.password],
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
            );
          }),
        ),
      ),
    );
  }
}
