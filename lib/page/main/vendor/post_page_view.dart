import 'package:carousel_slider/carousel_slider.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:Localsearch_User/utils/colors.dart';

class PostPageView extends StatefulWidget {
  const PostPageView({
    super.key,
    required this.currentIndex,
    required this.posts,
  });

  final int currentIndex;
  final Map<String, dynamic> posts;

  @override
  State<PostPageView> createState() => _PostPageViewState();
}

class _PostPageViewState extends State<PostPageView> {
  late int index;
  int currentImageIndex = 0;

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

  // SHOW TEXT DIALOG
  Future<void> showTextDialog(String text, double width) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(width * 0.033),
            child: SingleChildScrollView(
              child: Text(text),
            ),
          ),
          backgroundColor: primary2,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      appBar: AppBar(
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
            final currentPost = widget.posts.values.toList()[index];

            return Padding(
              padding: EdgeInsets.all(width * 0.006125),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await showTextDialog(currentPost[0], width);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.0125),
                      child: Text(
                        currentPost[0],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: white,
                          fontSize: width * 0.055,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Center(
                        child: CarouselSlider(
                          items: (currentPost[2] as List<dynamic>)
                              .map(
                                (e) => Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: primaryDark2,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(e),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          options: CarouselOptions(
                            enableInfiniteScroll:
                                currentPost[2].length > 1 ? true : false,
                            aspectRatio: 1,
                            viewportFraction: 1,
                            enlargeCenterPage: true,
                            onPageChanged: (index, reason) {
                              setState(() {
                                currentImageIndex = index;
                              });
                            },
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          index == 0
                              ? Container()
                              : Container(
                                  decoration: BoxDecoration(
                                    color: primary2,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        index--;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.arrow_left,
                                      color: primaryDark,
                                      size: width * 0.09,
                                    ),
                                    padding: EdgeInsets.all(width * 0.025),
                                  ),
                                ),
                          index == (widget.posts.length - 1)
                              ? Container()
                              : Container(
                                  decoration: BoxDecoration(
                                    color: primary2,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        index++;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.arrow_right_alt,
                                      color: primaryDark,
                                      size: width * 0.09,
                                    ),
                                    padding: EdgeInsets.all(width * 0.025),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   crossAxisAlignment: CrossAxisAlignment.center,
                  //   children: [
                  //     Container(
                  //       decoration: BoxDecoration(
                  //         color: primary2,
                  //         borderRadius: BorderRadius.circular(100),
                  //       ),
                  //       child: IconButton(
                  //         onPressed: () {
                  //           setState(() {
                  //             currentImageIndex++;
                  //           });
                  //         },
                  //         icon: Icon(
                  //           Icons.arrow_left,
                  //           color: primaryDark,
                  //           size: width * 0.09,
                  //         ),
                  //         padding: EdgeInsets.all(width * 0.025),
                  //       ),
                  //     ),
                  //     Container(
                  //       decoration: BoxDecoration(
                  //         color: primary2,
                  //         borderRadius: BorderRadius.circular(100),
                  //       ),
                  //       child: IconButton(
                  //         onPressed: () {
                  //           setState(() {
                  //             currentImageIndex++;
                  //           });
                  //         },
                  //         icon: Icon(
                  //           Icons.arrow_right,
                  //           color: primaryDark,
                  //           size: width * 0.09,
                  //         ),
                  //         padding: EdgeInsets.all(width * 0.025),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
