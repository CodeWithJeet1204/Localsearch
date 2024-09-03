import 'package:Localsearch_User/page/main/vendor/product/product_page.dart';
import 'package:Localsearch_User/widgets/post_skeleton_container.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:Localsearch_User/page/main/vendor/vendor_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductsScrollPage extends StatefulWidget {
  const ProductsScrollPage({super.key});

  @override
  State<ProductsScrollPage> createState() => _ProductsScrollPageState();
}

class _ProductsScrollPageState extends State<ProductsScrollPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> products = {};
  Map<String, dynamic> vendors = {};
  bool isData = false;
  int noOf = 4;
  int? total;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    getTotal();
    scrollController.addListener(scrollListener);
    getPosts();
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
        print('increasing');
        setState(() {
          isLoadMore = true;
        });
        noOf = noOf + 1;
        await getPosts();
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
        .where('isPost', isEqualTo: true)
        .get();

    final totalLength = totalSnap.docs.length;

    setState(() {
      total = totalLength;
    });
  }

  // GET POSTS
  Future<void> getPosts() async {
    List myVendorIds = [];
    Map<String, dynamic> myProducts = {};
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .orderBy('datetime', descending: true)
        .limit(noOf)
        .get();

    for (final productSnap in productsSnap.docs) {
      final productData = productSnap.data();
      final String productId = productData['productId'];
      final String name = productData['productName'];
      final List? imageUrl = productData['images'];
      final String price = productData['productPrice'];
      final Map<String, dynamic> wishlistsTimestamp =
          productData['productWishlistTimestamp'];
      final String vendorId = productData['vendorId'];
      final Timestamp datetime = productData['datetime'];
      final bool isPost = productData['isPost'];

      if (isPost) {
        // for (var i = 0; i < 1; i++) {
        myProducts['$productId' /*$i*/] = [
          name,
          imageUrl,
          price,
          vendorId,
          datetime,
          wishlistsTimestamp.containsKey(auth.currentUser!.uid),
        ];

        // myProducts = Map.fromEntries(
        //   myProducts.entries.toList()
        //     ..sort(
        //       (a, b) => (b.value[4] as Timestamp).compareTo(
        //         a.value[4] as Timestamp,
        //       ),
        //     ),
        // );

        if (!myVendorIds.contains(vendorId)) {
          await getVendorInfo(vendorId);
          myVendorIds.add(vendorId);
        }
        // }
      }
    }

    setState(() {
      products = myProducts;
      isData = true;
    });
  }

  // GET VENDOR INFO
  Future<void> getVendorInfo(String vendorId) async {
    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(vendorId)
        .get();

    final vendorData = vendorSnap.data();

    if (vendorData != null) {
      final id = vendorSnap.id;
      final name = vendorData['Name'];
      final imageUrl = vendorData['Image'];

      setState(() {
        vendors[id] = [name, imageUrl];
      });
    }
  }

  // WISHLIST PRODUCT
  Future<void> wishlistProduct(String productId, bool alreadyInWishlist) async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    List<dynamic> userWishlist = userData['wishlists'] as List<dynamic>;

    if (!alreadyInWishlist) {
      userWishlist.add(productId);
    } else {
      userWishlist.remove(productId);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'wishlists': userWishlist,
    });

    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .get();

    final productData = productSnap.data()!;

    Map<String, dynamic> wishlists = productData['productWishlistTimestamp'];

    if (!alreadyInWishlist) {
      wishlists.addAll({
        auth.currentUser!.uid: DateTime.now(),
      });
    } else {
      wishlists.remove(auth.currentUser!.uid);
    }

    await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .update({
      'productWishlistTimestamp': wishlists,
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
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
        automaticallyImplyLeading: false,
      ),
      body: !isData
          ? SizedBox(
              width: width,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 4,
                physics: const ClampingScrollPhysics(),
                itemBuilder: ((context, index) {
                  return PostSkeletonContainer(
                    width: width,
                    height: width * 1.25,
                  );
                }),
              ),
            )
          : products.isEmpty
              ? const Center(
                  child: Text('No Posts Available'),
                )
              : SafeArea(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await getTotal();
                      setState(() {
                        noOf = 2;
                      });
                      await getPosts();
                    },
                    color: primaryDark,
                    backgroundColor: const Color.fromARGB(255, 243, 253, 255),
                    semanticsLabel: 'Refresh',
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.00625,
                      ),
                      child: ListView.builder(
                        controller: scrollController,
                        cacheExtent: height * 1.5,
                        addAutomaticKeepAlives: true,
                        primary: false,
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount:
                            isLoadMore ? products.length + 1 : products.length,
                        itemBuilder: ((context, index) {
                          final String id = products.keys
                              .toList()[isLoadMore ? index - 1 : index];

                          final String name = products.values
                              .toList()[isLoadMore ? index - 1 : index][0];
                          final List? imageUrl = products.values
                              .toList()[isLoadMore ? index - 1 : index][1];
                          final String? price = products.values
                              .toList()[isLoadMore ? index - 1 : index][2];
                          final String vendorId = products.values
                              .toList()[isLoadMore ? index - 1 : index][3];
                          final bool isWishlist = products.values
                              .toList()[isLoadMore ? index - 1 : index][5];

                          bool isWishListed = isWishlist;

                          final String vendorName =
                              vendors.isEmpty ? '' : vendors[vendorId][0];
                          final String vendorImageUrl =
                              vendors.isEmpty ? '' : vendors[vendorId][1];

                          return index <= products.length
                              ? GestureDetector(
                                  onTap: () async {
                                    final productSnap = await store
                                        .collection('Business')
                                        .doc('Data')
                                        .collection('Products')
                                        .doc(id)
                                        .get();

                                    final productData = productSnap.data()!;
                                    if (context.mounted) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProductPage(
                                            productData: productData,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: width,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          width: 0.06125,
                                          color: black,
                                        ),
                                        right: BorderSide(
                                          width: 0.06125,
                                          color: black,
                                        ),
                                        top: BorderSide(
                                          width: 0.06125,
                                          color: black,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        // VENDOR INFO
                                        vendors.isEmpty
                                            ? Container()
                                            : Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.0125,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .push(
                                                          MaterialPageRoute(
                                                            builder:
                                                                ((context) =>
                                                                    VendorPage(
                                                                      vendorId:
                                                                          vendorId,
                                                                    )),
                                                          ),
                                                        );
                                                      },
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          CircleAvatar(
                                                            radius:
                                                                width * 0.04,
                                                            backgroundColor:
                                                                primary2,
                                                            backgroundImage:
                                                                NetworkImage(
                                                              vendorImageUrl,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                width * 0.0125,
                                                          ),
                                                          Text(
                                                            vendorName,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // SHARE
                                                    IconButton(
                                                      onPressed: () {},
                                                      icon: const Icon(
                                                        FeatherIcons.share2,
                                                      ),
                                                      tooltip: 'Share Post',
                                                    ),
                                                  ],
                                                ),
                                              ),

                                        // IMAGES
                                        Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Container(
                                              width: width,
                                              height: width,
                                              decoration: const BoxDecoration(
                                                color: Color.fromRGBO(
                                                  237,
                                                  237,
                                                  237,
                                                  1,
                                                ),
                                              ),
                                              child: CarouselSlider(
                                                items: imageUrl!
                                                    .map(
                                                      (e) => Image.network(
                                                        e,
                                                        width: width,
                                                        height: width,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                    .toList(),
                                                options: CarouselOptions(
                                                  enableInfiniteScroll:
                                                      imageUrl.length > 1
                                                          ? true
                                                          : false,
                                                  viewportFraction: 1,
                                                  aspectRatio: 0.7875,
                                                  enlargeCenterPage: false,
                                                ),
                                              ),
                                            ),

                                            // DOTS
                                            // isTextPost
                                            //     ? Container()
                                            //     : Padding(
                                            //         padding: const EdgeInsets.only(
                                            //           bottom: 8,
                                            //         ),
                                            //         child: Row(
                                            //           mainAxisAlignment:
                                            //               MainAxisAlignment.center,
                                            //           crossAxisAlignment:
                                            //               CrossAxisAlignment.center,
                                            //           children: (imageUrl).map((e) {
                                            //             int index = imageUrl.indexOf(e);

                                            //             return Container(
                                            //               width: 8,
                                            //               height: 8,
                                            //               margin: const EdgeInsets.all(4),
                                            //               decoration: BoxDecoration(
                                            //                 shape: BoxShape.circle,
                                            //                 color: currentIndex == index
                                            //                     ? primaryDark
                                            //                     : primary2,
                                            //               ),
                                            //             );
                                            //           }).toList(),
                                            //         ),
                                            //       ),
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
                                                  MainAxisAlignment.spaceAround,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // NAME
                                                Padding(
                                                  padding: EdgeInsets.all(
                                                    width * 0.0125,
                                                  ),
                                                  child: SizedBox(
                                                    width: width * 0.75,
                                                    child: Text(
                                                      name,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.start,
                                                    ),
                                                  ),
                                                ),

                                                // PRICE
                                                Padding(
                                                  padding: EdgeInsets.all(
                                                    width * 0.0125,
                                                  ),
                                                  child: SizedBox(
                                                    width: width * 0.75,
                                                    child: Text(
                                                      price == ''
                                                          ? 'Rs. --'
                                                          : 'Rs. $price',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.start,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // WISHLIST
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: width * 0.0125,
                                              ),
                                              child: IconButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    products[id][5] =
                                                        !isWishListed;
                                                  });
                                                  await wishlistProduct(
                                                    id,
                                                    !products[id][5],
                                                  );
                                                },
                                                icon: Icon(
                                                  products[id][5]
                                                      ? Icons.favorite_rounded
                                                      : Icons
                                                          .favorite_outline_rounded,
                                                  size: width * 0.095,
                                                  color: Colors.red,
                                                ),
                                                color: Colors.red,
                                                tooltip: 'WISHLIST',
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                                )
                              : isLoadMore
                                  ? SizedBox(
                                      height: 45,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : Container();
                        }),
                      ),
                    ),
                  ),
                ),
    );
  }
}
