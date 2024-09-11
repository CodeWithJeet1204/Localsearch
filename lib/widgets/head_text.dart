import 'package:localsearch_user/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeadText extends StatelessWidget {
  const HeadText({
    super.key,
    required this.text,
  });
  final String text;

  String textFormat(String text) {
    int length = text.length;
    String formattedText = '';
    for (var i = 0; i < length; i++) {
      formattedText += '${text[i]} ';
    }
    return formattedText;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      textFormat(text),
      textAlign: TextAlign.center,
      style: GoogleFonts.josefinSans(
        fontSize: text == 'MEMBERSHIPS' ? 28 : 32,
        color: primaryDark,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
