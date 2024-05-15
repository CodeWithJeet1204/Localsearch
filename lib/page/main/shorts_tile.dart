import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/vendor/product/product_page.dart';
import 'package:find_easy_user/page/main/vendor/vendor_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ShortsTile extends StatefulWidget {
  const ShortsTile({
    super.key,
    required this.data,
    required this.snappedPageIndex,
    required this.currentIndex,
  });

  final Map<String, dynamic> data;
  final int snappedPageIndex;
  final int currentIndex;

  @override
  State<ShortsTile> createState() => _ShortsTileState();
}

class _ShortsTileState extends State<ShortsTile> {
  late VideoPlayerController videoController;
  late Future initializeVideoPlayer;
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  bool isWishListed = false;
  bool isWishlistLocked = false;
  bool isVideoPlaying = true;

  // INIT STATE
  @override
  void initState() {
    getIfWishlist(widget.data['productId']);
    videoController = VideoPlayerController.networkUrl(
      Uri.parse(
        widget.data['shortsURL'],
      ),
    );
    initializeVideoPlayer = videoController.initialize();
    videoController.setLooping(true);
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  // PAUSE PLAY SHORT
  void pausePlayShort() {
    isVideoPlaying ? videoController.pause() : videoController.play();
    setState(() {
      isVideoPlaying = !isVideoPlaying;
    });
  }

  // GET IF WISHLIST
  Future<void> getIfWishlist(String productId) async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    final userWishlist = userData['wishlists'] as List;

    setState(() {
      if (userWishlist.contains(productId)) {
        isWishListed = true;
      } else {
        isWishListed = false;
      }
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

    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .get();

    final productData = productSnap.data()!;

    int noOfWishList = productData['productWishlist'] ?? 0;

    if (!alreadyInWishlist) {
      noOfWishList++;
    } else {
      noOfWishList--;
    }

    await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .update({
      'productWishlist': noOfWishList,
    });
  }

  // GET VENDOR INFO
  Future<String> getVendorInfo(String vendorId) async {
    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    final vendorName = vendorData['Name'] as String;

    return vendorName;
  }

  // GET PRODUCT NAME
  Future<String> getProductName(String productId) async {
    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .get();

    final productData = productSnap.data()!;

    final productName = productData['productName'] as String;

    return productName;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    (widget.snappedPageIndex == widget.currentIndex && isVideoPlaying)
        ? videoController.play()
        : videoController.pause();

    return SafeArea(
      child: VisibilityDetector(
        key: Key('Shorts'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 0) {
            videoController.pause();
          } else {
            videoController.play();
          }
        },
        child: Container(
          color: black,
          child: FutureBuilder(
            future: initializeVideoPlayer,
            builder: ((context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: pausePlayShort,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(videoController),
                          Visibility(
                            visible: !isVideoPlaying,
                            child: IconButton(
                              onPressed: pausePlayShort,
                              icon: Icon(
                                Icons.play_arrow_rounded,
                                size: 80,
                                color: white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.025),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: width * 0.05),
                                  child: IconButton(
                                    onPressed: () async {
                                      isWishlistLocked
                                          ? null
                                          : setState(() {
                                              isWishListed = !isWishListed;
                                            });
                                      isWishlistLocked
                                          ? null
                                          : await wishlistProduct(
                                              widget.data['productId'],
                                            );
                                    },
                                    icon: Icon(
                                      isWishListed
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_outline_rounded,
                                      size: width * 0.095,
                                      color: Colors.red,
                                    ),
                                    tooltip: "WISHLIST",
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.only(
                                          left: width * 0.0125,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                FutureBuilder(
                                                  future: getVendorInfo(
                                                      widget.data['vendorId']),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasError) {
                                                      return Container();
                                                    }

                                                    if (snapshot.hasData) {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder:
                                                                  ((context) =>
                                                                      VendorPage(
                                                                        vendorId:
                                                                            widget.data['vendorId'],
                                                                      )),
                                                            ),
                                                          );
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                            width * 0.006125,
                                                          ),
                                                          child: Text(
                                                            snapshot.data!,
                                                            style: TextStyle(
                                                              color: white,
                                                              fontSize:
                                                                  width * 0.05,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    return Container();
                                                  },
                                                ),
                                              ],
                                            ),
                                            FutureBuilder(
                                              future: getProductName(
                                                  widget.data['productId']),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasError) {
                                                  return Container();
                                                }

                                                if (snapshot.hasData) {
                                                  return GestureDetector(
                                                    onTap: () async {
                                                      final productSnap =
                                                          await store
                                                              .collection(
                                                                  'Business')
                                                              .doc('Data')
                                                              .collection(
                                                                  'Products')
                                                              .doc(widget.data[
                                                                  'productId'])
                                                              .get();

                                                      final productData =
                                                          productSnap.data()!;

                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                          builder: ((context) =>
                                                              ProductPage(
                                                                productData:
                                                                    productData,
                                                              )),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding: EdgeInsets.all(
                                                        width * 0.006125,
                                                      ),
                                                      child: Text(
                                                        snapshot.data!,
                                                        style: TextStyle(
                                                          color: white,
                                                          fontSize:
                                                              width * 0.05,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return Container();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.only(left: width * 0.05),
                                      child: IconButton(
                                        onPressed: () {},
                                        icon: Icon(
                                          FeatherIcons.share2,
                                          size: width * 0.095,
                                          color: white,
                                        ),
                                        tooltip: "SHARE",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Stack(
                  children: [
                    Center(
                      child: CircularProgressIndicator(
                        color: white,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: width * 0.05),
                            child: IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.favorite_outline_rounded,
                                size: width * 0.095,
                                color: Colors.red,
                              ),
                              tooltip: "WISHLIST",
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.only(
                                    left: width * 0.0125,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(
                                              width * 0.006125,
                                            ),
                                            child: Container(),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(
                                          width * 0.006125,
                                        ),
                                        child: Container(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: width * 0.05),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    FeatherIcons.share2,
                                    size: width * 0.095,
                                    color: white,
                                  ),
                                  tooltip: "SHARE",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            }),
          ),
        ),
      ),
    );
  }
}
