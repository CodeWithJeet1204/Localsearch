import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch_user/page/main/vendor/category/category_products_page.dart';
import 'package:localsearch_user/utils/colors.dart';
import 'package:localsearch_user/widgets/video_tutorial.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ShopCategoriesPage extends StatefulWidget {
  const ShopCategoriesPage({
    super.key,
    required this.shopType,
  });

  final String shopType;

  @override
  State<ShopCategoriesPage> createState() => _ShopCategoriesPageState();
}

class _ShopCategoriesPageState extends State<ShopCategoriesPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  Map<String, dynamic>? categoryData;
  int noOf = 12;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    getData();
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
        noOf = noOf + 4;
      });
      setState(() {
        isLoadMore = false;
      });
    }
  }

  // GET DATA
  Future<void> getData() async {
    final categoriesSnap = await store
        .collection('Shop Types And Category Data')
        .doc('Category Data')
        .get();

    final categoriesData = categoriesSnap.data()!;

    final Map<String, dynamic> myCategoryData =
        categoriesData['householdCategoryData'][widget.shopType];

    final sortedEntries = myCategoryData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final sortedCategoryData = Map<String, dynamic>.fromEntries(sortedEntries);

    setState(() {
      categoryData = sortedCategoryData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopType),
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
      body: categoryData == null
          ? Container()
          : SafeArea(
              child: GridView.builder(
                controller: scrollController,
                cacheExtent: height * 1.5,
                addAutomaticKeepAlives: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.825,
                ),
                itemCount:
                    noOf > categoryData!.length ? categoryData!.length : noOf,
                physics: const ClampingScrollPhysics(),
                itemBuilder: ((context, index) {
                  final name = categoryData!.keys.toList()[isLoadMore
                      ? index == 0
                          ? 0
                          : index - 1
                      : index];
                  final imageUrl = categoryData!.values.toList()[isLoadMore
                      ? index == 0
                          ? 0
                          : index - 1
                      : index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: ((context) => CategoryProductsPage(
                                categoryName: name,
                              )),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black,
                          width: 0.25,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: width * 0.015,
                        vertical: width * 0.015,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            padding: EdgeInsets.all(width * 0.0125),
                            child: AutoSizeText(
                              name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                // fontSize: width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: black,
                              ),
                            ),
                          ),
                          SizedBox(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(8),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.low,
                                repeat: ImageRepeat.noRepeat,
                              ),
                            ),
                          ),
                          // ClipRRect(
                          //   borderRadius: const BorderRadius.vertical(
                          //     bottom: Radius.circular(8),
                          //   ),
                          //   child: Image.network(
                          //     imageUrl,
                          //     fit: BoxFit.cover,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
    );
  }
}
