import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VendorShortsTabTile extends StatefulWidget {
  const VendorShortsTabTile({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  State<VendorShortsTabTile> createState() => _VendorShortsTabTileState();
}

class _VendorShortsTabTileState extends State<VendorShortsTabTile> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  late FlickManager flickManager;
  bool isWishListed = false;
  bool isWishlistLocked = false;
  bool isVideoPlaying = true;
  bool isData = false;

  // INIT STATE
  @override
  void initState() {
    if (widget.data['productId'] != null) {
      getIfWishlist();
    }
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.networkUrl(
        Uri.parse(
          widget.data['shortsURL'],
        ),
      ),
    );
    flickManager.flickVideoManager!.videoPlayerController?.addListener(() {
      if (flickManager
              .flickVideoManager!.videoPlayerController!.value.position ==
          flickManager
              .flickVideoManager!.videoPlayerController!.value.duration) {
        flickManager.flickControlManager!.seekTo(
          const Duration(
            seconds: 0,
          ),
        );
        flickManager.flickControlManager!.play();
      }
    });
    setState(() {
      isData = true;
    });
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  // PAUSE PLAY SHORT
  void pausePlayShort() {
    flickManager.flickControlManager?.togglePlay();

    setState(() {
      isVideoPlaying = !isVideoPlaying;
    });
  }

  // GET IF WISHLIST
  Future<void> getIfWishlist() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    final userWishlist = userData['wishlists'] as List;

    setState(() {
      if (userWishlist.contains(widget.data['productId'])) {
        isWishListed = true;
      } else {
        isWishListed = false;
      }
      isData = true;
    });
  }

  // WISHLIST PRODUCT
  Future<void> wishlistProduct() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    List<dynamic> userWishlist = userData['wishlists'] as List<dynamic>;

    bool alreadyInWishlist = userWishlist.contains(widget.data['productId']);

    if (!alreadyInWishlist) {
      userWishlist.add(widget.data['productId']);
    } else {
      userWishlist.remove(widget.data['productId']);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'wishlists': userWishlist,
    });

    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.data['productId'])
        .get();

    final productData = productSnap.data()!;

    Map wishlists = productData['productWishlistTimestamp'];

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
        .doc(widget.data['productId'])
        .update({
      'productWishlistTimestamp': wishlists,
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

    return isData
        ? VisibilityDetector(
            key: const Key('Shorts'),
            onVisibilityChanged: (info) {
              flickManager.flickControlManager?.togglePlay();
            },
            child: Scaffold(
              body: Stack(
                children: [
                  GestureDetector(
                    onTap: pausePlayShort,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FlickVideoPlayer(
                          flickManager: flickManager,
                          flickVideoWithControls: const FlickVideoWithControls(
                            videoFit: BoxFit.contain,
                            playerLoadingFallback: Align(
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                color: white,
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: !isVideoPlaying,
                          child: IconButton(
                            onPressed: pausePlayShort,
                            icon: const Icon(
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
                              widget.data['productId'] == null
                                  ? Container()
                                  : Padding(
                                      padding:
                                          EdgeInsets.only(left: width * 0.05),
                                      child: IconButton(
                                        onPressed: () async {
                                          isWishlistLocked
                                              ? null
                                              : setState(() {
                                                  isWishListed = !isWishListed;
                                                });
                                          isWishlistLocked
                                              ? null
                                              : await wishlistProduct();
                                        },
                                        icon: Icon(
                                          isWishListed
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_outline_rounded,
                                          size: width * 0.095,
                                          color: Colors.red,
                                        ),
                                        color: Colors.red,
                                        tooltip: 'Wishlist',
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
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          width * 0.006125,
                                        ),
                                        child: Text(
                                          widget.data['productName'] ??
                                              widget.data['caption'] ??
                                              '<No Shorts Name>',
                                          style: TextStyle(
                                            color: white,
                                            fontSize: width * 0.05,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  widget.data['productId'] == null
                                      ? Container()
                                      : Padding(
                                          padding: EdgeInsets.only(
                                            left: width * 0.05,
                                          ),
                                          child: IconButton(
                                            onPressed: () {},
                                            icon: Icon(
                                              FeatherIcons.share2,
                                              size: width * 0.095,
                                              color: white,
                                            ),
                                            tooltip: 'SHARE',
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
              ),
            ),
          )
        : Stack(
            children: [
              const Center(
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
                    widget.data['productId'] == null
                        ? Container()
                        : Padding(
                            padding: EdgeInsets.only(left: width * 0.05),
                            child: IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.favorite_outline_rounded,
                                size: width * 0.095,
                                color: Colors.red,
                              ),
                              color: Colors.red,
                              tooltip: 'Wishlist',
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        widget.data['productId'] == null
                            ? Container()
                            : Padding(
                                padding: EdgeInsets.only(left: width * 0.05),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    FeatherIcons.share2,
                                    size: width * 0.095,
                                    color: white,
                                  ),
                                  tooltip: 'SHARE',
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
}
