import 'package:localsearch/page/main/vendor/product/product_page.dart';
import 'package:localsearch/providers/main_page_provider.dart';
import 'package:localsearch/widgets/post_skeleton_container.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localsearch/page/main/vendor/vendor_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/widgets/sign_in_dialog.dart';
import 'package:localsearch/widgets/text_button.dart';
import 'package:provider/provider.dart';

class FollowedPostsPage extends StatefulWidget {
  const FollowedPostsPage({super.key});

  @override
  State<FollowedPostsPage> createState() => _FollowedPostsPageState();
}

class _FollowedPostsPageState extends State<FollowedPostsPage>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<FollowedPostsPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> postsAndProducts = {};
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
    List followedShops = [];

    if (auth.currentUser != null) {
      final userSnap =
          await store.collection('Users').doc(auth.currentUser!.uid).get();

      final userData = userSnap.data()!;
      followedShops = userData['followedShops'];
    }

    if (followedShops.toList().isNotEmpty) {
      final productsSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .where('vendorId', whereIn: followedShops)
          .where('isPost', isEqualTo: true)
          .get();

      final postsSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Posts')
          .where('postVendorId', whereIn: followedShops)
          .get();

      final totalLength = productsSnap.docs.length + postsSnap.docs.length;

      setState(() {
        total = totalLength;
      });
    }
  }

  // GET POSTS AND PRODUCTS
  Future<void> getPostsAndProducts() async {
    Map<String, dynamic> myPostsAndProducts = {};
    Map<String, Map<String, dynamic>> myVendors = {};
    List followedShops = [];

    if (auth.currentUser != null) {
      final userSnap =
          await store.collection('Users').doc(auth.currentUser!.uid).get();

      final userData = userSnap.data()!;

      followedShops = userData['followedShops'];
    }

    if (followedShops.isNotEmpty) {
      final productsSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .where('vendorId', whereIn: followedShops)
          .where('isPost', isEqualTo: true)
          .orderBy('datetime', descending: true)
          .get();

      await Future.wait(
        productsSnap.docs.map((productSnap) async {
          final productData = productSnap.data();
          final String productId = productData['productId'];
          final String name = productData['productName'];
          final List? imageUrl = productData['images'];
          final price = productData['productPrice'];
          final Map<String, dynamic> wishlistsTimestamp =
              productData['productWishlistTimestamp'];
          final String vendorId = productData['vendorId'];
          final Timestamp datetime = productData['datetime'];

          if (!myVendors.containsKey(vendorId)) {
            final vendorSnap = await store
                .collection('Business')
                .doc('Owners')
                .collection('Shops')
                .doc(vendorId)
                .get();

            final vendorData = vendorSnap.data()!;
            myVendors[vendorId] = vendorData;
          }

          myPostsAndProducts[productId] = [
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
          ];
        }),
      );

      final postsSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Post')
          .where('postVendorId', whereIn: followedShops)
          .orderBy('postDateTime', descending: true)
          .get();

      await Future.wait(
        postsSnap.docs.map((postSnap) async {
          final postData = postSnap.data();
          final String id = postData['postId'];
          final String text = postData['postText'].toString().trim().isEmpty
              ? 'No Post Name'
              : postData['postText'];
          final price = postData['postPrice'];
          final List? imageUrl = postData['postImage'];
          final String vendorId = postData['postVendorId'];
          final Timestamp datetime = postData['postDateTime'];

          if (!myVendors.containsKey(vendorId)) {
            final vendorSnap = await store
                .collection('Business')
                .doc('Owners')
                .collection('Shops')
                .doc(vendorId)
                .get();

            final vendorData = vendorSnap.data()!;
            myVendors[vendorId] = vendorData;
          }

          myPostsAndProducts[id] = [
            text,
            imageUrl,
            price,
            vendorId,
            datetime,
            false,
            myVendors[vendorId]!['Name'],
            myVendors[vendorId]!['Image'],
            'post',
          ];
        }),
      );

      final sortedProductsAndPosts = Map.fromEntries(
        myPostsAndProducts.entries.toList()
          ..sort((a, b) {
            DateTime dateA = (a.value[4] as Timestamp).toDate();
            DateTime dateB = (b.value[4] as Timestamp).toDate();
            return dateB.compareTo(dateA);
          }),
      );

      myPostsAndProducts = sortedProductsAndPosts;
    }

    setState(() {
      postsAndProducts = myPostsAndProducts;
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
    final mainPageProvider = Provider.of<MainPageProvider>(context);
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        mainPageProvider.goToHomePage();
      },
      child: Scaffold(
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
                  child: auth.currentUser == null
                      ? Center(
                          child: SizedBox(
                            height: 160,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Sign In to Follow Shops',
                                  textAlign: TextAlign.center,
                                ),
                                MyTextButton(
                                  onPressed: () async {
                                    await showSignInDialog(
                                      context,
                                    );
                                  },
                                  text: 'SIGN IN',
                                  textColor: primaryDark,
                                ),
                              ],
                            ),
                          ),
                        )
                      : postsAndProducts.isEmpty
                          ? SizedBox(
                              height: 80,
                              child: const Center(
                                child: Text(
                                  'Follow Shops to see Posts',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : Padding(
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
                                itemCount: postsAndProducts.length,
                                itemBuilder: ((context, index) {
                                  final String id =
                                      postsAndProducts.keys.toList()[index];

                                  final String name = postsAndProducts.values
                                      .toList()[index][0];
                                  final List? imageUrl = postsAndProducts.values
                                      .toList()[index][1];
                                  final price = postsAndProducts.values
                                      .toList()[index][2];
                                  final String vendorId =
                                      postsAndProducts.values.toList()[index]
                                          [3];
                                  final bool isWishlist =
                                      postsAndProducts.values.toList()[index]
                                          [5];
                                  final isProduct = postsAndProducts.values
                                          .toList()[index][8] ==
                                      'product';

                                  bool isWishListed = isWishlist;

                                  final String vendorName =
                                      postsAndProducts.values.toList()[index]
                                          [6];
                                  final String vendorImageUrl =
                                      postsAndProducts.values.toList()[index]
                                          [7];

                                  return GestureDetector(
                                    onTap: isProduct
                                        ? () async {
                                            final productSnap = await store
                                                .collection('Business')
                                                .doc('Data')
                                                .collection('Products')
                                                .doc(id)
                                                .get();

                                            final productData =
                                                productSnap.data()!;
                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProductPage(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Padding(
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
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: width * 0.04,
                                                        backgroundColor:
                                                            primary2,
                                                        backgroundImage:
                                                            NetworkImage(
                                                          vendorImageUrl
                                                              .toString()
                                                              .trim(),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: width * 0.0125,
                                                      ),
                                                      Text(
                                                        vendorName
                                                            .toString()
                                                            .trim(),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                                    MainAxisAlignment
                                                        .spaceAround,
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
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        isProduct
                                                            ? Icon(
                                                                Icons.link,
                                                                color:
                                                                    primaryDark,
                                                                size: width *
                                                                    0.066,
                                                              )
                                                            : Container(),
                                                        SizedBox(
                                                          width: width * 0.725,
                                                          child: Text(
                                                            name
                                                                .toString()
                                                                .trim(),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            textAlign:
                                                                TextAlign.start,
                                                          ),
                                                        ),
                                                      ],
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
                                                            ? 'Price: N/A'
                                                            : 'Rs. ${price.runtimeType == int ? price : double.parse(price.toString()).round()}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.start,
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
                                                              postsAndProducts[
                                                                      id][5] =
                                                                  !isWishListed;
                                                            });
                                                            await wishlistProduct(
                                                              id,
                                                              !postsAndProducts[
                                                                  id][5],
                                                            );
                                                          } else {
                                                            await showSignInDialog(
                                                              context,
                                                            );
                                                          }
                                                        },
                                                        icon: Icon(
                                                          postsAndProducts[id]
                                                                  [5]
                                                              ? Icons
                                                                  .favorite_rounded
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
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                ),
              ),
      ),
    );
  }
}
