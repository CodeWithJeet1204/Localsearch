import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:localy_user/utils/colors.dart';

class PostPageView extends StatefulWidget {
  const PostPageView({
    super.key,
    required this.currentIndex,
    required this.posts,
    required this.vendors,
    required this.products,
  });

  final int currentIndex;
  final Map<String, dynamic> posts;
  final Map<String, dynamic> vendors;
  final Map<String, dynamic> products;

  @override
  State<PostPageView> createState() => _PostPageViewState();
}

class _PostPageViewState extends State<PostPageView> {
  late int index;

  // INIT STATE
  @override
  void initState() {
    index = widget.currentIndex;
    super.initState();
  }

  // CALCULATE AVERAGE RATINGS
  double calculateAverageRatings(Map<String, dynamic> ratings) {
    if (ratings.isEmpty) return 0.0;

    final allRatings = ratings.values.map((e) => e[0] as int).toList();

    final sum = allRatings.reduce((value, element) => value + element);

    final averageRating = sum / allRatings.length;

    return averageRating;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      appBar: AppBar(
        title: Text(
          widget.posts.values.toList()[widget.currentIndex][0],
          style: TextStyle(
            color: white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              FeatherIcons.x,
              color: white,
            ),
            color: white,
            tooltip: 'CLOSE',
          ),
        ],
        automaticallyImplyLeading: false,
        foregroundColor: white,
        backgroundColor: black,
        shadowColor: black,
        surfaceTintColor: black,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.0225),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Rs. ${widget.products.values.toList()[index]['productPrice']}',
                        style: TextStyle(
                          color: white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
