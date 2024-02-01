import 'package:find_easy_user/utils/colors.dart';
import 'package:flutter/material.dart';

class MyCollapseContainer extends StatefulWidget {
  const MyCollapseContainer({
    super.key,
    required this.headText,
    required this.isShow,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.bodyWidget,
    required this.onTap,
    required this.horizontalMargin,
    this.verticalMargin = 0,
  });

  final String headText;
  final bool isShow;
  final Widget bodyWidget;
  final void Function() onTap;
  final double horizontalMargin;
  final double verticalMargin;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  State<MyCollapseContainer> createState() => _MyCollapseContainerState();
}

class _MyCollapseContainerState extends State<MyCollapseContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primary2.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: widget.horizontalMargin,
        vertical: widget.verticalMargin,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding,
        vertical: widget.verticalPadding,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.headText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    widget.isShow
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          widget.isShow
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: widget.bodyWidget,
                )
              : Container(),
        ],
      ),
    );
  }
}
