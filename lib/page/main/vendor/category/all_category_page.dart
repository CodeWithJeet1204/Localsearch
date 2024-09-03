import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Localsearch_User/page/main/vendor/category/category_page.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class AllCategoryPage extends StatefulWidget {
  const AllCategoryPage({
    super.key,
    required this.vendorId,
  });

  final String vendorId;

  @override
  State<AllCategoryPage> createState() => _AllCategoryPageState();
}

class _AllCategoryPageState extends State<AllCategoryPage> {
  final store = FirebaseFirestore.instance;
  Map<String, dynamic>? shopData;
  Map categories = {};
  bool isData = false;
  int noOf = 10;
  int? total;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    // getTotal();
    scrollController.addListener(scrollListener);
    getVendorInfo();
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
    if (total != null && noOf < total!) {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        setState(() {
          isLoadMore = true;
        });
        noOf = noOf + 4;
        await getCategories();
        setState(() {
          isLoadMore = false;
        });
      }
    }
  }

  // GET TOTAL
  Future<void> getTotal() async {
    int totalLength = 0;
    final shopList = shopData!['Type'];

    for (var shop in shopList) {
      final categoriesSnap = await store
          .collection('Business')
          .doc('Special Categories')
          .collection(shop)
          .limit(noOf)
          .get();

      final vendorSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .doc(widget.vendorId)
          .get();

      final vendorData = vendorSnap.data()!;

      final List categories = vendorData['Categories'];

      for (var shopCategory in categories) {
        for (var categoryData in categoriesSnap.docs) {
          final name = categoryData['specialCategoryName'] as String;

          if (shopCategory == name) {
            totalLength++;
          }
        }
      }
    }

    setState(() {
      total = totalLength;
    });
  }

  // GET VENDOR INFO
  Future<void> getVendorInfo() async {
    final shopSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final currentShopData = shopSnap.data()!;

    setState(() {
      shopData = currentShopData;
    });

    await getCategories();
  }

  // GET CATEGORIES
  Future<void> getCategories() async {
    Map<String, String> category = {};
    final shopList = shopData!['Type'];

    for (var shop in shopList) {
      final categoriesSnap = await store
          .collection('Business')
          .doc('Special Categories')
          .collection(shop)
          .get();

      for (var categoryData in categoriesSnap.docs) {
        final name = categoryData['specialCategoryName'] as String;
        final imageUrl = categoryData['specialCategoryImageUrl'] as String;

        category[name] = imageUrl;
      }
    }
    setState(() {
      categories = category;
      isData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Categories'),
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
      body: !isData
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: GridView.builder(
                controller: scrollController,
                cacheExtent: height * 1.5,
                addAutomaticKeepAlives: true,
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.775,
                ),
                itemCount: categories.length,
                physics: const ClampingScrollPhysics(),
                itemBuilder: ((context, index) {
                  final name = categories.keys.toList()[isLoadMore
                      ? index == 0
                          ? 0
                          : index - 1
                      : index];
                  final imageUrl = categories.values.toList()[isLoadMore
                      ? index == 0
                          ? 0
                          : index - 1
                      : index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: ((context) => CategoryPage(
                                categoryName: name,
                                vendorType: shopData!['Type'],
                              )),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 0.25,
                        ),
                      ),
                      margin: EdgeInsets.all(width * 0.0125),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: SizedBox(),
                          ),
                          AutoSizeText(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: width * 0.05125,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: SizedBox(),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              imageUrl,
                              width: width * 0.475,
                              height: width * 0.475,
                              fit: BoxFit.cover,
                            ),
                          ),
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
