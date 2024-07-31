import 'package:Localsearch_User/utils/colors.dart';
import 'package:flutter/material.dart';

class SmallTextContainer extends StatelessWidget {
  const SmallTextContainer({
    super.key,
    required this.text,
    required this.onPressed,
    required this.width,
  });

  final String text;
  final void Function()? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.0125,
        vertical: width * 0.025,
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        splashColor: white,
        child: Container(
          width: width,
          height: width * 0.15,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: primary2.withOpacity(0.25),
            border: Border.all(
              width: 0.25,
              color: primaryDark,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: width * 0.05),
            child: Text(
              overflow: TextOverflow.ellipsis,
              text,
              style: TextStyle(
                color: primaryDark,
                fontWeight: FontWeight.w500,
                fontSize: width * 0.05,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
