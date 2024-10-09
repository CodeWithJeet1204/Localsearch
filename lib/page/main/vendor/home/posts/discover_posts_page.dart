import 'package:localsearch/page/main/vendor/product/product_page.dart';
import 'package:localsearch/widgets/post_skeleton_container.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localsearch/page/main/vendor/vendor_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/widgets/sign_in_dialog.dart';

class DiscoverPostsPage extends StatefulWidget {
  const DiscoverPostsPage({super.key});

  @override
  State<DiscoverPostsPage> createState() => _DiscoverPostsPageState();
}

class _DiscoverPostsPageState extends State<DiscoverPostsPage>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<DiscoverPostsPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> productsAndPosts = {};
  bool isData = false;
  int noOf = 4;
  int? total;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    getTotal();
    scrollController.addListener(scrollListener);
    getPostsAndProducts();
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // WANT KEEP ALIVE
  @override
  bool get wantKeepAlive => true;

  // SCROLL LISTENER
  Future<void> scrollListener() async {
    if (total != null && noOf < total!) {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        noOf = noOf + 4;
        await getPostsAndProducts();
      }
    }
  }

  // GET TOTAL
  Future<void> getTotal() async {
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('isPost', isEqualTo: true)
        .get();

    final postsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Posts')
        .get();

    final totalLength = productsSnap.docs.length + postsSnap.docs.length;

    setState(() {
      total = totalLength;
    });
  }

  // GET PRODUCTS AND POSTS
  Future<void> getPostsAndProducts() async {
    Map<String, dynamic> myProductsAndPosts = {};
    Map<String, Map<String, dynamic>> myVendors = {};

    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('isPost', isEqualTo: true)
        .orderBy('datetime', descending: true)
        .limit(noOf)
        .get();

    for (final productSnap in productsSnap.docs) {
      final productData = productSnap.data();
      final String productId = productData['productId'];
      final String name = productData['productName'];
      final List? imageUrl = productData['images'];
      final price = productData['productPrice'];
      final Map<String, dynamic> wishlistsTimestamp =
          productData['productWishlistTimestamp'];
      final String vendorId = productData['vendorId'];
      final Timestamp datetime = productData['datetime'];
      // final int views = productData['viewsTimestamp'].length;

      if (!myVendors.keys.toList().contains(vendorId)) {
        final vendorSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Shops')
            .doc(vendorId)
            .get();

        final vendorData = vendorSnap.data()!;
        myVendors[vendorId] = vendorData;
      }

      myProductsAndPosts[productId] = [
        name,
        imageUrl,
        price,
        vendorId,
        datetime,
        auth.currentUser == null
            ? false
            : wishlistsTimestamp.containsKey(auth.currentUser!.uid),
        myVendors[vendorId]!['Name'],
        myVendors[vendorId]!['Image'],
        'product',
        // views,
      ];
    }

    final postsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Post')
        .orderBy('postDateTime', descending: true)
        .limit(noOf)
        .get();

    for (final postSnap in postsSnap.docs) {
      final postData = postSnap.data();
      final String id = postData['postId'];
      final String text = postData['postText'];
      final price = postData['postPrice'];
      final List? imageUrl = postData['postImage'];
      final String vendorId = postData['postVendorId'];
      final Timestamp datetime = postData['postDateTime'];
      // final int views = postData['postViews'];

      if (!myVendors.keys.toList().contains(vendorId)) {
        final vendorSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Shops')
            .doc(vendorId)
            .get();

        final vendorData = vendorSnap.data()!;
        myVendors[vendorId] = vendorData;
      }

      myProductsAndPosts[id] = [
        text,
        imageUrl,
        price,
        vendorId,
        datetime,
        false,
        myVendors[vendorId]!['Name'],
        myVendors[vendorId]!['Image'],
        'post',
        // views,
      ];
    }

    final sortedProductsAndPosts = Map.fromEntries(
      myProductsAndPosts.entries.toList()
        ..sort((a, b) {
          DateTime dateA = (a.value[4] as Timestamp).toDate();
          DateTime dateB = (b.value[4] as Timestamp).toDate();
          return dateB.compareTo(dateA);
        }),
    );

    myProductsAndPosts = sortedProductsAndPosts;

    setState(() {
      productsAndPosts = myProductsAndPosts;
      isData = true;
    });
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
    super.build(context);
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
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
          : productsAndPosts.isEmpty
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
                      await getPostsAndProducts();
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
                        itemCount: noOf > productsAndPosts.length
                            ? productsAndPosts.length
                            : noOf,
                        itemBuilder: ((context, index) {
                          final String productId =
                              productsAndPosts.keys.toList()[index];

                          final String name =
                              productsAndPosts.values.toList()[index][0];
                          final List? imageUrl =
                              productsAndPosts.values.toList()[index][1];
                          final price =
                              productsAndPosts.values.toList()[index][2];
                          final String vendorId =
                              productsAndPosts.values.toList()[index][3];
                          final bool isWishlist =
                              productsAndPosts.values.toList()[index][5];
                          final isProduct =
                              productsAndPosts.values.toList()[index][8] ==
                                  'product';

                          final vendorName =
                              productsAndPosts.values.toList()[index][6];
                          final vendorImageUrl =
                              productsAndPosts.values.toList()[index][7];

                          bool isWishlisted = isWishlist;

                          return GestureDetector(
                            onTap: isProduct
                                ? () async {
                                    final productSnap = await store
                                        .collection('Business')
                                        .doc('Data')
                                        .collection('Products')
                                        .doc(productId)
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
                                  }
                                : null,
                            child: Container(
                              width: width,
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(width: 0.06125),
                                  right: BorderSide(width: 0.06125),
                                  top: BorderSide(width: 0.06125),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0125,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VendorPage(
                                                  vendorId: vendorId,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                radius: width * 0.04,
                                                backgroundColor: primary2,
                                                backgroundImage: NetworkImage(
                                                  vendorImageUrl
                                                      .toString()
                                                      .trim(),
                                                ),
                                              ),
                                              SizedBox(width: width * 0.0125),
                                              SizedBox(
                                                width: width * 0.7125,
                                                child: Text(
                                                  vendorName.toString().trim(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // SHARE
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(FeatherIcons.share2),
                                          tooltip: 'Share Post',
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: width,
                                    height: width,
                                    decoration: const BoxDecoration(
                                      color: Color.fromRGBO(237, 237, 237, 1),
                                    ),
                                    child: CarouselSlider(
                                      items: imageUrl!
                                          .map(
                                            (e) => Image.network(
                                              e.toString().trim(),
                                              width: width,
                                              height: width,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                          .toList(),
                                      options: CarouselOptions(
                                        enableInfiniteScroll: false,
                                        viewportFraction: 1,
                                        aspectRatio: 0.7875,
                                        enlargeCenterPage: false,
                                      ),
                                    ),
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
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                isProduct
                                                    ? Icon(
                                                        Icons.link,
                                                        color: primaryDark,
                                                        size: width * 0.066,
                                                      )
                                                    : Container(),
                                                SizedBox(
                                                  width: width * 0.725,
                                                  child: Text(
                                                    name.toString().trim(),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.start,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // PRICE
                                          Padding(
                                            padding:
                                                EdgeInsets.all(width * 0.0125),
                                            child: SizedBox(
                                              width: width * 0.75,
                                              child: Text(
                                                'Rs. ${price.runtimeType == int ? price : price.round()}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.start,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // WISHLIST
                                      isProduct
                                          ? Padding(
                                              padding: EdgeInsets.only(
                                                right: width * 0.0125,
                                              ),
                                              child: IconButton(
                                                onPressed: () async {
                                                  if (auth.currentUser !=
                                                      null) {
                                                    setState(() {
                                                      productsAndPosts[
                                                              productId][5] =
                                                          !isWishlisted;
                                                    });
                                                    await wishlistProduct(
                                                      productId,
                                                      !isWishlisted,
                                                    );
                                                  } else {
                                                    await showSignInDialog(
                                                      context,
                                                    );
                                                  }
                                                },
                                                icon: Icon(
                                                  isWishlisted
                                                      ? Icons.favorite_rounded
                                                      : Icons
                                                          .favorite_outline_rounded,
                                                  size: width * 0.095,
                                                  color: Colors.red,
                                                ),
                                                color: Colors.red,
                                                tooltip: 'Wishlist',
                                              ),
                                            )
                                          : Container(),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
    );
  }
}
