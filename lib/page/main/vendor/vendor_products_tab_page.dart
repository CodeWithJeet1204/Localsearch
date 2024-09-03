import 'package:Localsearch_User/page/main/vendor/product/product_page.dart';
import 'package:Localsearch_User/page/main/vendor/vendor_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/product_quick_view.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VendorProductsTabPage extends StatefulWidget {
  const VendorProductsTabPage({
    super.key,
    required this.width,
    required this.myProducts,
    required this.myProductSort,
    required this.height,
  });

  final width;
  final height;
  final String? myProductSort;
  final Map<String, dynamic> myProducts;

  @override
  State<VendorProductsTabPage> createState() => _VendorProductsTabPageState();
}

class _VendorProductsTabPageState extends State<VendorProductsTabPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> products = {};
  String? productSort;
  int noOf = 8;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    scrollController.addListener(scrollListener);
    products = widget.myProducts;
    productSort = widget.myProductSort;
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

  // SORT PRODUCTS
  void sortProducts(EventSorting sorting) {
    List<MapEntry<String, dynamic>> sortedEntries =
        widget.myProducts.entries.toList();

    switch (sorting) {
      case EventSorting.recentlyAdded:
        sortedEntries.sort((a, b) =>
            (b.value[4] as Timestamp).compareTo(a.value[4] as Timestamp));
        break;
      case EventSorting.highestRated:
        sortedEntries.sort((a, b) {
          final ratingA = calculateAverageRating(a.value[3]);
          final ratingB = calculateAverageRating(b.value[3]);
          return ratingB.compareTo(ratingA);
        });
        break;
      case EventSorting.mostViewed:
        sortedEntries.sort((a, b) => ((b.value[5] as List).length)
            .compareTo((a.value[5] as List).length));
        break;
      case EventSorting.lowestPrice:
        sortedEntries.sort((a, b) {
          final priceA = double.parse(a.value[2]);
          final priceB = double.parse(b.value[2]);
          return priceA.compareTo(priceB);
        });
        break;
      case EventSorting.highestPrice:
        sortedEntries.sort((a, b) {
          final priceA = double.parse(a.value[2]);
          final priceB = double.parse(b.value[2]);
          return priceB.compareTo(priceA);
        });
        break;
    }

    setState(() {
      products = Map.fromEntries(sortedEntries);
    });
  }

  // CALCULATE AVERAGE RATINGS
  double calculateAverageRating(Map<String, dynamic> ratings) {
    if (ratings.isEmpty) return 0.0;

    final allRatings = ratings.values.map((e) => e[0] as double).toList();

    final sum = allRatings.reduce((value, element) => value + element);

    final averageRating = sum / allRatings.length;

    return averageRating;
  }

  // GET SCREEN HEIGHT
  double getScreenHeight() {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final paddingTop = mediaQuery.padding.top;
    final paddingBottom = mediaQuery.padding.bottom;

    final availableHeight = screenHeight - paddingTop - paddingBottom;
    return availableHeight;
  }

  // GET IF WISHLIST
  Stream<bool> getIfWishlist(String productId) {
    return store
        .collection('Users')
        .doc(auth.currentUser!.uid)
        .snapshots()
        .map((userSnap) {
      final userData = userSnap.data()!;
      final userWishlist = userData['wishlists'] as List;

      return userWishlist.contains(productId);
    });
  }

  // WISHLIST PRODUCT
  Future<void> wishlistProduct(String productId) async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    List<dynamic> userWishlist = userData['wishlists'] as List<dynamic>;

    bool alreadyInWishlist = userWishlist.contains(productId);

    if (!alreadyInWishlist) {
      userWishlist.add(productId);
    } else {
      userWishlist.remove(productId);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'wishlists': userWishlist,
    });

    final productDoc = store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId);

    final productSnap = await productDoc.get();
    final productData = productSnap.data()!;

    Map wishlists = productData['productWishlistTimestamp'];

    if (!alreadyInWishlist) {
      wishlists.addAll({
        auth.currentUser!.uid: DateTime.now(),
      });
    } else {
      wishlists.remove(auth.currentUser!.uid);
    }

    await productDoc.update({
      'productWishlistTimestamp': wishlists,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels ==
                scrollInfo.metrics.maxScrollExtent) {
              scrollListener();
            }
            return false;
          },
          child: SingleChildScrollView(
            child: Column(
              children: [
                widget.myProducts.isEmpty
                    ? Container()
                    : SizedBox(
                        height: getScreenHeight() * 0.0675,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: widget.width * 0.01,
                            horizontal: widget.width * 0.0125,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.width * 0.0125,
                            ),
                            decoration: BoxDecoration(
                              color: primary3,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              underline: const SizedBox(),
                              dropdownColor: primary2,
                              value: productSort,
                              iconEnabledColor: primaryDark,
                              items: [
                                'Recently Added',
                                'Highest Rated',
                                'Most Viewed',
                                'Price - Highest to Lowest',
                                'Price - Lowest to Highest'
                              ]
                                  .map((e) => DropdownMenuItem<String>(
                                        value: e,
                                        child: Text(e),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  productSort = value;
                                });
                                try {
                                  sortProducts(
                                    value == 'Recently Added'
                                        ? EventSorting.recentlyAdded
                                        : value == 'Highest Rated'
                                            ? EventSorting.highestRated
                                            : value == 'Most Viewed'
                                                ? EventSorting.mostViewed
                                                : value ==
                                                        'Price - Highest to Lowest'
                                                    ? EventSorting.highestPrice
                                                    : EventSorting.lowestPrice,
                                  );
                                } catch (e) {
                                  mySnackBar('Something went wrong', context);
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                // PRODUCTS
                products.isEmpty
                    ? Container()
                    : SizedBox(
                        width: widget.width,
                        height: getScreenHeight() * 0.675,
                        child: GridView.builder(
                          primary: false,
                          controller: scrollController,
                          cacheExtent: getScreenHeight() * 1.5,
                          addAutomaticKeepAlives: true,
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: widget.width * 0.6 / widget.width,
                          ),
                          itemCount:
                              noOf > products.length ? products.length : noOf,
                          itemBuilder: ((context, index) {
                            final id = products.keys.toList()[isLoadMore
                                ? index == 0
                                    ? 0
                                    : index - 1
                                : index];
                            final name = products.values.toList()[isLoadMore
                                ? index == 0
                                    ? 0
                                    : index - 1
                                : index][0];
                            final imageUrl = products.values.toList()[isLoadMore
                                ? index == 0
                                    ? 0
                                    : index - 1
                                : index][1];
                            final price = products.values.toList()[isLoadMore
                                ? index == 0
                                    ? 0
                                    : index - 1
                                : index][2];
                            final ratings = products.values.toList()[isLoadMore
                                ? index == 0
                                    ? 0
                                    : index - 1
                                : index][3];
                            final productData =
                                products.values.toList()[isLoadMore
                                    ? index == 0
                                        ? 0
                                        : index - 1
                                    : index][6];

                            return StreamBuilder(
                                stream: getIfWishlist(id),
                                builder: (context, snapshot) {
                                  final isWishListed = snapshot.data ?? false;
                                  return GestureDetector(
                                    onTap: () async {
                                      if (context.mounted) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) => ProductPage(
                                                  productData: productData,
                                                )),
                                          ),
                                        );
                                      }
                                    },
                                    onDoubleTap: () async {
                                      await showDialog(
                                        context: context,
                                        builder: ((context) => ProductQuickView(
                                              productId: id,
                                            )),
                                      );
                                    },
                                    onLongPress: () async {
                                      await showDialog(
                                        context: context,
                                        builder: ((context) => ProductQuickView(
                                              productId: id,
                                            )),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          width: 0.25,
                                          color: Colors.grey.withOpacity(
                                            0.25,
                                          ),
                                        ),
                                      ),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.0125,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              Center(
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.5,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.58,
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: const Color.fromRGBO(
                                                    255,
                                                    92,
                                                    78,
                                                    1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    4,
                                                  ),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      widget.width * 0.0125,
                                                  vertical:
                                                      widget.width * 0.00625,
                                                ),
                                                margin: EdgeInsets.all(
                                                  widget.width * 0.00625,
                                                ),
                                                child: Text(
                                                  '${(ratings as Map).isEmpty ? '--' : ((ratings.values.map((e) => e?[0] ?? 0).toList().reduce((a, b) => a + b) / (ratings.values.isEmpty ? 1 : ratings.values.length)) as double).toStringAsFixed(1)} ⭐',
                                                  style: const TextStyle(
                                                    color: white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      left:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.00625,
                                                      right:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.00625,
                                                      top:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.0225,
                                                    ),
                                                    child: SizedBox(
                                                      width: widget.width * 0.3,
                                                      child: Text(
                                                        name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize:
                                                              widget.width *
                                                                  0.0475,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.0125,
                                                    ),
                                                    child: Text(
                                                      price == ''
                                                          ? 'Rs. --'
                                                          : 'Rs. $price',
                                                      style: TextStyle(
                                                        fontSize: widget.width *
                                                            0.0475,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              IconButton(
                                                onPressed: () async {
                                                  await wishlistProduct(id);
                                                },
                                                icon: Icon(
                                                  isWishListed
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: Colors.red,
                                                ),
                                                color: Colors.red,
                                                iconSize: widget.width * 0.09,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                });
                          }),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
