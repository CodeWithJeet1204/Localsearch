import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/see_more_text.dart';
import 'package:flutter/material.dart';

class ReviewContainer extends StatefulWidget {
  const ReviewContainer({
    super.key,
    required this.name,
    required this.rating,
    required this.review,
  });

  final String name;
  final double rating;
  final String review;

  @override
  State<ReviewContainer> createState() => _ReviewContainerState();
}

class _ReviewContainerState extends State<ReviewContainer> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.02,
        vertical: width * 0.02,
      ),
      margin: EdgeInsets.symmetric(
        vertical: width * 0.0125,
      ),
      decoration: BoxDecoration(
        color: primary2.withOpacity(0.0125),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.name,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: width * 0.033,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${widget.rating.toString()} ⭐',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SeeMoreText(
            widget.review,
            textStyle: TextStyle(
              fontSize: width * 0.045,
            ),
          ),
        ],
      ),
    );
  }
}
