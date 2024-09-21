import 'package:localsearch/utils/colors.dart';
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.isLoading,
    this.width = double.infinity,
    required this.horizontalPadding,
    this.verticalPadding = 0,
  });

  final String text;
  final bool isLoading;
  final width;
  final double horizontalPadding;
  final double verticalPadding;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: buttonColor,
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: white,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
