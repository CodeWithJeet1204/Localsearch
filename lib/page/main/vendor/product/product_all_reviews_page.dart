import 'package:localy_user/widgets/review_container.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class ProductAllReviewPage extends StatefulWidget {
  const ProductAllReviewPage({
    super.key,
    required this.rating,
    required this.reviews,
  });

  final Widget rating;
  final Map<String, dynamic> reviews;

  @override
  State<ProductAllReviewPage> createState() => _ProductAllReviewPageState();
}

class _ProductAllReviewPageState extends State<ProductAllReviewPage> {
  @override
  Widget build(BuildContext context) {
    widget.reviews.removeWhere((key, value) => value[1].isEmpty);
    final reviews = widget.reviews;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reviews'),
        actions: [
          IconButton(
            onPressed: () async {
              await showYouTubePlayerDialog(
                context,
                getYoutubeVideoId(
                  '',
                ),
              );
            },
            icon: Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: "Help",
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              double width = constraints.maxWidth;
              double height = constraints.maxHeight;

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: width * 0.0225,
                  ),
                  child: Column(
                    children: [
                      widget.rating,
                      SizedBox(
                        width: width,
                        height: height,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: reviews.length,
                          itemBuilder: ((context, index) {
                            final name = reviews.keys.toList()[index];
                            final rating = reviews.values.toList()[index][0];
                            final review = reviews.values.toList()[index][1];

                            return ReviewContainer(
                              name: name,
                              rating: rating,
                              review: review,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
