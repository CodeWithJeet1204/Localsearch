import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/skeleton_container.dart';
import 'package:flutter/material.dart';

class PostSkeletonContainer extends StatelessWidget {
  const PostSkeletonContainer({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(width * 0.0225),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SkeletonContainer(
                    width: width * 0.1,
                    height: width * 0.1,
                  ),
                  SizedBox(width: width * 0.025),
                  SkeletonContainer(width: width * 0.33, height: 20),
                ],
              ),
              SkeletonContainer(
                width: width * 0.1,
                height: width * 0.1,
              ),
            ],
          ),
          SizedBox(height: width * 0.0225),
          Center(
            child: SkeletonContainer(
              width: width * 0.9,
              height: width * 0.9,
            ),
          ),
          SizedBox(height: width * 0.0225),
          SkeletonContainer(width: width * 0.75, height: 24),
          SizedBox(height: width * 0.0225),
          SkeletonContainer(width: width * 0.25, height: 16),
        ],
      ),
    );
  }
}
