import 'package:flutter/material.dart';
import 'package:localsearch/page/auth/sign_in_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/text_button.dart';

Future<void> showSignInDialog(BuildContext context) async {
  await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text('Sign In'),
          content: Text(
            'Sign in to continue',
          ),
          actions: [
            MyTextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              text: 'Cancel',
              textColor: primaryDark,
            ),
            MyTextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SignInPage(),
                  ),
                );
              },
              text: 'OK',
              textColor: primaryDark,
            ),
          ],
        );
      });
}
