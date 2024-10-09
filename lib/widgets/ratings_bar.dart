import 'package:flutter/material.dart';

class RatingsBars extends StatelessWidget {
  final Map<String, int> ratingMap;

  const RatingsBars({
    super.key,
    required this.ratingMap,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = ratingMap.values.reduce((int a, int b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingBar('5', ratingMap['5']!, maxCount, context),
        _buildRatingBar('4', ratingMap['4']!, maxCount, context),
        _buildRatingBar('3', ratingMap['3']!, maxCount, context),
        _buildRatingBar('2', ratingMap['2']!, maxCount, context),
        _buildRatingBar('1', ratingMap['1']!, maxCount, context),
      ],
    );
  }

  Widget _buildRatingBar(String rating, int count, int maxCount, context) {
    final width = MediaQuery.sizeOf(context).width;
    final double barWidth =
        (count.toDouble() / maxCount.toDouble()) * width * 0.25;

    return Row(
      children: [
        Text(
          '$rating ⭐ :',
          style: TextStyle(
            fontSize: width * 0.025,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 4,
          width: 1 + barWidth,
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: width * 0.025,
          ),
        ),
      ],
    );
  }
}
