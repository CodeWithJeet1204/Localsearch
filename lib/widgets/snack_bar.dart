import 'package:localsearch/utils/colors.dart';
import 'package:flutter/material.dart';

void mySnackBar(String text, BuildContext context) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style: const TextStyle(
          color: Color.fromARGB(255, 240, 252, 255),
        ),
      ),
      elevation: 2,
      backgroundColor: primaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      dismissDirection: DismissDirection.down,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
