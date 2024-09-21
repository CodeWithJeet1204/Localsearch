import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UnderDevelopmentPage extends StatelessWidget {
  const UnderDevelopmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Under Development'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'This app is currently under development\nTry again after some time',
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),
            MyTextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              text: 'OK',
              textColor: primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}
