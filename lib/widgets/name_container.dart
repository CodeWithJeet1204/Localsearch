import 'package:find_easy_user/utils/colors.dart';
import 'package:flutter/material.dart';

class NameContainer extends StatefulWidget {
  const NameContainer({
    super.key,
    required this.text,
    required this.imageUrl,
    required this.onTap,
    required this.width,
  });

  final String text;
  final String imageUrl;
  final void Function()? onTap;
  final double width;

  @override
  State<NameContainer> createState() => _NameContainerState();
}

class _NameContainerState extends State<NameContainer> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width * 0.475,
        height: 100,
        decoration: BoxDecoration(
          color: white,
          border: Border.all(
            width: 1,
            color: primaryDark,
          ),
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(widget.imageUrl),
            fit: BoxFit.cover,
            opacity: 0.33,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.width * 0.003125,
        ),
        margin: EdgeInsets.all(widget.width * 0.0125),
        child: Center(
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryDark,
              fontWeight: FontWeight.w500,
              fontSize: widget.width * 0.066,
            ),
          ),
        ),
      ),
    );
  }
}
