import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:Localsearch_User/page/main/vendor/product/product_page.dart';
import 'package:Localsearch_User/page/main/search/search_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/product_quick_view.dart';
import 'package:Localsearch_User/widgets/skeleton_container.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchWithProductsPage extends StatefulWidget {
  const SearchWithProductsPage({super.key});

  @override
  State<SearchWithProductsPage> createState() => _SearchWithProductsPageState();
}

class _SearchWithProductsPageState extends State<SearchWithProductsPage> {
  final store = FirebaseFirestore.instance;
  final int noOfProducts = 20;
  final List<String> productIds = [];
  final List<String> productImageUrls = [];
  bool getData = false;
  Map<String, dynamic>? productData;

  // INIT STATE
  @override
  void initState() {
    getProducts();
    super.initState();
  }

  // GET PRODUCTS
  Future<Map<String, dynamic>?>? getProducts({String? productId}) async {
    final QuerySnapshot productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .get();

    if (productId != null) {
      final currentProductSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(productId)
          .get();

      final productData = currentProductSnap.data()!;

      return productData;
    }

    final List<DocumentSnapshot> allProducts = productSnap.docs;
    final List<DocumentSnapshot> randomProducts = List.from(allProducts)
      ..shuffle();

    final List<DocumentSnapshot> displayedProducts = randomProducts.length > 20
        ? randomProducts.sublist(0, 20)
        : randomProducts;

    productIds.clear();
    productImageUrls.clear();

    for (var productDoc in displayedProducts) {
      final String productId = productDoc.id;
      final String productImageUrl =
          (productDoc.data() as Map<String, dynamic>)['images'][0];

      productIds.add(productId);
      productImageUrls.add(productImageUrl);
    }

    setState(() {
      getData = true;
    });

    return null;
  }

  // GET SCREEN HEIGHT
  double getScreenHeight(double width) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final paddingTop = mediaQuery.padding.top;
    final paddingBottom = mediaQuery.padding.bottom;
    final searchBarHeight = width * 0.125;

    final availableHeight =
        screenHeight - paddingTop - paddingBottom - searchBarHeight;
    return availableHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !getData
          ? SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: GridView.custom(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    gridDelegate: SliverQuiltedGridDelegate(
                      crossAxisCount: 4,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      repeatPattern: QuiltedGridRepeatPattern.inverted,
                      pattern: [
                        const QuiltedGridTile(2, 2),
                        const QuiltedGridTile(1, 1),
                        const QuiltedGridTile(1, 1),
                        const QuiltedGridTile(1, 1),
                        const QuiltedGridTile(1, 1),
                      ],
                    ),
                    childrenDelegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SkeletonContainer(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width,
                        );
                      },
                      childCount: 20,
                    ),
                  ),
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.0225,
                ),
                child: LayoutBuilder(builder: ((context, constraints) {
                  final width = constraints.maxWidth;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // SEARCH
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.0125,
                            vertical: width * 0.0125,
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: ((context) => const SearchPage()),
                                ),
                              );
                            },
                            splashColor: white.withOpacity(0.125),
                            customBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Container(
                              width: width,
                              height: width * 0.15,
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.05,
                              ),
                              decoration: BoxDecoration(
                                color: primary2.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: primaryDark.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Search...',
                                    style: TextStyle(
                                      color: primaryDark2.withOpacity(0.5),
                                      fontSize: width * 0.045,
                                    ),
                                  ),
                                  Icon(
                                    FeatherIcons.search,
                                    color: primaryDark2.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // PRODUCTS
                        SizedBox(
                          width: width,
                          height: getScreenHeight(width),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: width * 0.0125,
                              bottom: width * 0.2,
                            ),
                            child: GridView.custom(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              gridDelegate: SliverQuiltedGridDelegate(
                                crossAxisCount: 4,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                repeatPattern:
                                    QuiltedGridRepeatPattern.inverted,
                                pattern: [
                                  const QuiltedGridTile(2, 2),
                                  const QuiltedGridTile(1, 1),
                                  const QuiltedGridTile(1, 1),
                                  const QuiltedGridTile(1, 1),
                                  const QuiltedGridTile(1, 1),
                                ],
                              ),
                              childrenDelegate: SliverChildBuilderDelegate(
                                childCount: productIds.length,
                                (context, index) {
                                  final productId = productIds[index];
                                  final productImageUrl =
                                      productImageUrls[index];
                                  final productData =
                                      getProducts(productId: productId);

                                  return FutureBuilder<Map<String, dynamic>?>(
                                      future: getProducts(productId: productId),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return InkWell(
                                            onTap: () {
                                              if (productData != null) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ProductPage(
                                                      productData:
                                                          snapshot.data!,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                mySnackBar(
                                                  'Some error occured',
                                                  context,
                                                );
                                              }
                                            },
                                            onDoubleTap: () async {
                                              await showDialog(
                                                context: context,
                                                builder: ((context) =>
                                                    ProductQuickView(
                                                      productId: productId,
                                                    )),
                                              );
                                            },
                                            onLongPress: () async {
                                              await showDialog(
                                                context: context,
                                                builder: ((context) =>
                                                    ProductQuickView(
                                                      productId: productId,
                                                    )),
                                              );
                                            },
                                            splashColor: white,
                                            customBorder:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                  width * 0.00625),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                clipBehavior:
                                                    Clip.antiAliasWithSaveLayer,
                                                child: Image.network(
                                                  productImageUrl,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return Container();
                                      });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })),
              ),
            ),
    );
  }
}
