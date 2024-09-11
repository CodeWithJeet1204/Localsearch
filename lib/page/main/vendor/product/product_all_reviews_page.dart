import 'package:localsearch_user/widgets/review_container.dart';
import 'package:localsearch_user/widgets/video_tutorial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductAllReviewPage extends StatefulWidget {
  const ProductAllReviewPage({
    super.key,
    required this.rating,
    required this.productId,
  });

  final Widget rating;
  final String productId;

  @override
  State<ProductAllReviewPage> createState() => _ProductAllReviewPageState();
}

class _ProductAllReviewPageState extends State<ProductAllReviewPage> {
  final store = FirebaseFirestore.instance;
  Map<String, dynamic>? reviews;
  int noOf = 16;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    scrollController.addListener(scrollListener);
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // SCROLL LISTENER
  Future<void> scrollListener() async {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      setState(() {
        isLoadMore = true;
      });
      setState(() {
        noOf = noOf + 8;
      });
      setState(() {
        isLoadMore = false;
      });
    }
  }

  // GET REVIEWS
  Future<void> getReviews() async {
    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.productId)
        .get();

    final productData = productSnap.data()!;

    final Map<String, dynamic> ratings = productData['ratings'];

    Map<String, dynamic> allUserReviews = {};

    for (String uid in ratings.keys) {
      final userDoc = await store.collection('Users').doc(uid).get();
      final userData = userDoc.data()!;
      final userName = userData['Name'];
      final rating = ratings[uid][0];
      final review = ratings[uid][1];
      allUserReviews[userName] = [rating, review];
    }

    allUserReviews.removeWhere((key, value) => value[1].isEmpty);

    setState(() {
      reviews = allUserReviews;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: 'Help',
          ),
        ],
      ),
      body: reviews == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.0125,
                ),
                child: LayoutBuilder(
                  builder: ((context, constraints) {
                    double width = constraints.maxWidth;
                    double height = constraints.maxHeight;

                    return NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                          scrollListener();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
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
                                  controller: scrollController,
                                  cacheExtent: height * 1.5,
                                  addAutomaticKeepAlives: true,
                                  shrinkWrap: true,
                                  itemCount: noOf > reviews!.length
                                      ? reviews!.length
                                      : noOf,
                                  physics: const ClampingScrollPhysics(),
                                  itemBuilder: ((context, index) {
                                    final name = reviews!.keys.toList()[index];
                                    final rating =
                                        reviews!.values.toList()[index][0];
                                    final review =
                                        reviews!.values.toList()[index][1];

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
                      ),
                    );
                  }),
                ),
              ),
            ),
    );
  }
}
