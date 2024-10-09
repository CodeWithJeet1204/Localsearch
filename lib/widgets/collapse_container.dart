import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/utils/size.dart';
import 'package:flutter/material.dart';

class MyCollapseContainer extends StatefulWidget {
  const MyCollapseContainer({
    super.key,
    required this.children,
    required this.width,
    required this.text,
  });

  final String text;
  final Widget children;
  final double width;

  @override
  State<MyCollapseContainer> createState() => _MyCollapseContainerState();
}

class _MyCollapseContainerState extends State<MyCollapseContainer> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(
        widget.width < screenSize ? widget.width * 0.035 : widget.width * 0.025,
      ),
      child: ExpansionTile(
        title: Text(
          widget.text.toString().trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: widget.width < screenSize
                ? widget.width * 0.045
                : widget.width * 0.0175,
          ),
        ),
        initiallyExpanded: false,
        tilePadding: EdgeInsets.symmetric(
          horizontal: widget.width < screenSize
              ? widget.width * 0.0225
              : widget.width * 0.02,
        ),
        backgroundColor: primary2.withOpacity(0.5),
        collapsedBackgroundColor: primary2.withOpacity(0.8),
        textColor: primaryDark.withOpacity(0.9),
        collapsedTextColor: primaryDark,
        iconColor: primaryDark2.withOpacity(0.9),
        collapsedIconColor: primaryDark2,
        shape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryDark.withOpacity(0.1),
          ),
        ),
        collapsedShape: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryDark.withOpacity(0.33),
          ),
        ),
        children: [
          widget.children,
        ],
      ),
    );
  }
}
