import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch/page/main/vendor/product/product_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/image_show.dart';
import 'package:localsearch/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({
    super.key,
    required this.categoryName,
    this.vendorId,
  });

  final String categoryName;
  final String? vendorId;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  String? imageUrl;
  Map? products;
  int noOf = 10;
  int? total;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    getTotal();
    scrollController.addListener(scrollListener);
    getCategoryImageUrl();
    getProducts();
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
        await getProducts();
        setState(() {
          isLoadMore = false;
        });
      }
    }
  }

  // GET TOTAL
  Future<void> getTotal() async {
    final totalSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('categoryName', isEqualTo: widget.categoryName)
        .get();

    final totalLength = totalSnap.docs.length;

    setState(() {
      total = totalLength;
    });
  }

  // GET CATEGORY IMAGE URL
  Future<void> getCategoryImageUrl() async {
    final categoriesSnap = await store
        .collection('Shop Types And Category Data')
        .doc('Just Category Data')
        .get();

    final categoriesData = categoriesSnap.data()!;

    final householdCategories = categoriesData['householdCategories'];

    final categoryImageUrl = householdCategories[widget.categoryName];

    setState(() {
      imageUrl = categoryImageUrl;
    });
  }

  // GET PRODUCTS
  Future<void> getProducts() async {
    Map product = {};
    final productsSnap = widget.vendorId != null
        ? await store
            .collection('Business')
            .doc('Data')
            .collection('Products')
            .where('vendorId', isEqualTo: widget.vendorId)
            .where('categoryName', isEqualTo: widget.categoryName)
            .limit(noOf)
            .get()
        : await store
            .collection('Business')
            .doc('Data')
            .collection('Products')
            .where('categoryName', isEqualTo: widget.categoryName)
            .limit(noOf)
            .get();

    for (var productData in productsSnap.docs) {
      final id = productData['productId'];
      final name = productData['productName'];
      final price = productData['productPrice'];
      final imageUrl = productData['images'][0];
      final productsData = productData.data();

      product[id] = [name, price, imageUrl, productsData];
    }

    setState(() {
      products = product;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body: imageUrl == null || products == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.0125,
                ),
                child: LayoutBuilder(
                  builder: ((context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    return NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                          scrollListener();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await showDialog(
                                      context: context,
                                      builder: ((context) => ImageShow(
                                            imageUrl: imageUrl!,
                                            width: width,
                                          )),
                                    );
                                  },
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(imageUrl!),
                                    radius: width * 0.1,
                                  ),
                                ),
                                SizedBox(width: width * 0.05),
                                Text(
                                  widget.categoryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: width * 0.055,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            products!.isEmpty
                                ? const SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: Text('No Products'),
                                    ),
                                  )
                                : SizedBox(
                                    width: width,
                                    height:
                                        getScreenHeight(width) - width * 0.285,
                                    child: GridView.builder(
                                      controller: scrollController,
                                      cacheExtent: height * 1.5,
                                      addAutomaticKeepAlives: true,
                                      shrinkWrap: true,
                                      physics: ClampingScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.7125,
                                      ),
                                      itemCount: products!.length,
                                      itemBuilder: ((context, index) {
                                        final id =
                                            products!.keys.toList()[isLoadMore
                                                ? index == 0
                                                    ? 0
                                                    : index - 1
                                                : index];
                                        final name =
                                            products!.values.toList()[isLoadMore
                                                ? index == 0
                                                    ? 0
                                                    : index - 1
                                                : index][0];
                                        final price =
                                            products!.values.toList()[isLoadMore
                                                ? index == 0
                                                    ? 0
                                                    : index - 1
                                                : index][1];
                                        final imageUrl =
                                            products!.values.toList()[isLoadMore
                                                ? index == 0
                                                    ? 0
                                                    : index - 1
                                                : index][2];

                                        return StreamBuilder(
                                            stream: getIfWishlist(id!),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: ((context) =>
                                                            ProductPage(
                                                              productData: products!
                                                                      .values
                                                                      .toList()[
                                                                  index][3],
                                                            )),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                      width * 0.00625,
                                                    ),
                                                    margin: EdgeInsets.all(
                                                      width * 0.003125,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: darkGrey,
                                                        width: 0.25,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Image.network(
                                                          imageUrl,
                                                          width: width * 0.5,
                                                          height: width * 0.5,
                                                          fit: BoxFit.cover,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceAround,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                SizedBox(
                                                                  width: width *
                                                                      0.3125,
                                                                  child: Text(
                                                                    name,
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          width *
                                                                              0.0475,
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: width *
                                                                      0.3125,
                                                                  child: Text(
                                                                    price == ''
                                                                        ? 'Rs. --'
                                                                        : 'Rs. $price',
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          width *
                                                                              0.04125,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            IconButton(
                                                              onPressed:
                                                                  () async {
                                                                await wishlistProduct(
                                                                  id!,
                                                                );
                                                              },
                                                              icon: Icon(
                                                                snapshot.data!
                                                                    ? Icons
                                                                        .favorite
                                                                    : Icons
                                                                        .favorite_border,
                                                                color:
                                                                    Colors.red,
                                                                size: width *
                                                                    0.0775,
                                                              ),
                                                              splashColor:
                                                                  Colors.red,
                                                              tooltip:
                                                                  'Wishlist',
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }

                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            });
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
