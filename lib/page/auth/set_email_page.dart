import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/page/auth/verify/email_verify.dart';
import 'package:localsearch/widgets/button.dart';
import 'package:localsearch/widgets/text_form_field.dart';

class SetEmailPage extends StatefulWidget {
  const SetEmailPage({super.key});

  @override
  State<SetEmailPage> createState() => _SetEmailPageState();
}

class _SetEmailPageState extends State<SetEmailPage> {
  final auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  bool isVerify = false;

  // SET EMAIL
  Future<void> setEmail() async {
    if (auth.currentUser!.email == null) {
      setState(() {
        isVerify = true;
      });
      await auth.currentUser!.verifyBeforeUpdateEmail(emailController.text);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EmailVerifyPage(
            updatingEmail: emailController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: !isVerify
              ? Column(
                  children: [
                    MyTextFormField(
                      hintText: 'Email',
                      controller: emailController,
                      borderRadius: 12,
                      horizontalPadding: 0,
                      autoFillHints: [],
                    ),
                    SizedBox(height: 12),
                    MyButton(
                      text: 'SET',
                      onTap: () async {
                        await setEmail();
                      },
                      isLoading: isVerify,
                      horizontalPadding: 0,
                    ),
                  ],
                )
              : Column(
                  children: [],
                ),
        ),
      ),
    );
  }
}
