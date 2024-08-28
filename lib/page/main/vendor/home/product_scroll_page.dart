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

  // INIT STATE
  @override
  void initState() {
    getProducts();
    super.initState();
  }

  // GET POSTS
  Future<void> getProducts() async {
    Map<String, dynamic> myProducts = {};
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .get();

    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final List wishlists = userData['wishlists'];

    for (final productSnap in productsSnap.docs) {
      final productData = productSnap.data();
      final String productId = productData['productId'];
      final String name = productData['productName'];
      final List? imageUrl = productData['images'];
      final String price = productData['productPrice'];
      final String vendorId = productData['vendorId'];
      final Timestamp datetime = productData['datetime'];

      myProducts[productId] = [
        name,
        imageUrl,
        price,
        vendorId,
        datetime,
        wishlists.contains(productId),
      ];

      myProducts = Map.fromEntries(
        myProducts.entries.toList()
          ..sort(
            (a, b) => (b.value[4] as Timestamp).compareTo(
              a.value[4] as Timestamp,
            ),
          ),
      );

      await getVendorInfo(vendorId);
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
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
              width: MediaQuery.of(context).size.width,
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
                      await getProducts();
                    },
                    color: primaryDark,
                    backgroundColor: const Color.fromARGB(255, 243, 253, 255),
                    semanticsLabel: 'Refresh',
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.00625,
                      ),
                      child: SizedBox(
                        width: width,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: products.length,
                          itemBuilder: ((context, index) {
                            final String id = products.keys.toList()[index];

                            final String name =
                                products.values.toList()[index][0];
                            final List? imageUrl =
                                products.values.toList()[index][1];
                            final String? price =
                                products.values.toList()[index][2];
                            final String vendorId =
                                products.values.toList()[index][3];
                            final bool isWishlist =
                                products.values.toList()[index][5];

                            bool isWishListed = isWishlist;

                            final String vendorName =
                                vendors.isEmpty ? '' : vendors[vendorId][0];
                            final String vendorImageUrl =
                                vendors.isEmpty ? '' : vendors[vendorId][1];

                            return GestureDetector(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: ((context) =>
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
                                                        radius: width * 0.04,
                                                        backgroundColor:
                                                            primary2,
                                                        backgroundImage:
                                                            NetworkImage(
                                                          vendorImageUrl,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: width * 0.0125,
                                                      ),
                                                      Text(
                                                        vendorName,
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

                                    // IMAGES
                                    Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        Container(
                                          width: width,
                                          height: width,
                                          decoration: const BoxDecoration(
                                            color: Color.fromRGBO(
                                                237, 237, 237, 1),
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
                                                  width * 0.0125),
                                              child: SizedBox(
                                                width: width * 0.75,
                                                child: Text(
                                                  name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
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
                                                  'Rs. $price',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
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
                                                products[id][5] = !isWishListed;
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
