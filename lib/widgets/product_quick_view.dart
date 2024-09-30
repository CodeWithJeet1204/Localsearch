import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductQuickView extends StatefulWidget {
  const ProductQuickView({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  State<ProductQuickView> createState() => _ProductQuickViewState();
}

class _ProductQuickViewState extends State<ProductQuickView> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  // String? name;
  // var price;
  List? images;
  // Map<String, dynamic>? ratings;
  // String? vendorId;
  // String? vendorName;
  // String? vendorImage;
  bool isData = false;
  // bool? isWishListed;
  // bool? wishlist;

  // INIT STATE
  @override
  void initState() {
    getImages();
    // getIfWishlist(widget.productId);
    super.initState();
  }

  // GET IMAGES
  Future<void> getImages() async {
    final productId = widget.productId;
    // String? vendorId;

    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .get();

    final productData = productSnap.data()!;

    // name = productData['productName'] ?? '';
    // price = productData['productPrice'];
    images = productData['images'] ?? [];
    // vendorId = productData['vendorId'] ?? '';
    // ratings = productData['ratings'] ?? {};

    // await getVendorInfo(vendorId!);
    setState(() {
      isData = true;
    });
  }

  // GET VENDOR INFO
  // Future<void> getVendorInfo(String currentVendorId) async {
  //   final vendorSnap = await store
  //       .collection('Business')
  //       .doc('Owners')
  //       .collection('Shops')
  //       .doc(currentVendorId)
  //       .get();
  //   final vendorData = vendorSnap.data()!;
  //   vendorId = currentVendorId;
  //   vendorName = vendorData['Name'] ?? '';
  //   vendorImage = vendorData['Image'] ?? '';
  //   setState(() {
  //     getData = true;
  //   });
  // }

  // GET IF WISHLIST
  // Future<void> getIfWishlist(String productId) async {
  //   final userSnap =
  //       await store.collection('Users').doc(auth.currentUser!.uid).get();
  //   final userData = userSnap.data()!;
  //   final userWishlist = userData['wishlists'] as List;
  //   setState(() {
  //     if (userWishlist.contains(productId)) {
  //       isWishListed = true;
  //       wishlist = true;
  //     } else {
  //       isWishListed = false;
  //       wishlist = false;
  //     }
  //   });
  // }

  // WISHLIST PRODUCT
  // Future<void> wishlistProduct(String productId) async {
  //   if (wishlist != null) {
  //     setState(() {
  //       wishlist = !wishlist!;
  //     });
  //   }
  //   final userSnap =
  //       await store.collection('Users').doc(auth.currentUser!.uid).get();
  //   final userData = userSnap.data()!;
  //   List<dynamic> userWishlist = userData['wishlists'] as List<dynamic>;
  //   bool alreadyInWishlist = userWishlist.contains(productId);
  //   if (!alreadyInWishlist) {
  //     userWishlist.add(productId);
  //   } else {
  //     userWishlist.remove(productId);
  //   }
  //   await store.collection('Users').doc(auth.currentUser!.uid).update({
  //     'wishlists': userWishlist,
  //   });
  //   final productDoc = store
  //       .collection('Business')
  //       .doc('Data')
  //       .collection('Products')
  //       .doc(productId);
  //   final productSnap = await productDoc.get();
  //   final productData = productSnap.data()!;
  //   Map wishlists = productData['productWishlistTimestamp'];
  //   if (!alreadyInWishlist) {
  //     wishlists.addAll({
  //       auth.currentUser!.uid: DateTime.now(),
  //     });
  //   } else {
  //     wishlists.remove(auth.currentUser!.uid);
  //   }
  //   await productDoc.update({
  //     'productWishlistTimestamp': wishlists,
  //   });
  //   await getIfWishlist(productId);
  // }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Dialog(
      elevation: 1,
      backgroundColor: white,
      child: Container(
        width: width * 0.7,
        height: width * 0.7,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: primaryDark,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: !isData
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // IMAGES CAROUSEL
                  CarouselSlider(
                    items: images!
                        .map(
                          (e) => Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 1,
                                color: primaryDark2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                11,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      e.toString().trim(),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    options: CarouselOptions(
                      enableInfiniteScroll: images!.length > 1 ? true : false,
                      aspectRatio: 1.2,
                      enlargeCenterPage: true,
                    ),
                  ),

                  // Column(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   crossAxisAlignment: CrossAxisAlignment.center,
                  //   children: [
                  //     Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         // NAME
                  //         Padding(
                  //           padding: const EdgeInsets.symmetric(vertical: 6),
                  //           child: SizedBox(
                  //             width: width * 0.5,
                  //             height: 36,
                  //             child: AutoSizeText(
                  //               name!,
                  //               maxLines: 2,
                  //               overflow: TextOverflow.ellipsis,
                  //               style: TextStyle(
                  //                 fontSize: width * 0.055,
                  //               ),
                  //             ),
                  //           ),
                  //         ),

                  //         // WISHLIST
                  //         isWishListed == null
                  //             ? Container()
                  //             : IconButton(
                  //                 onPressed: () async {
                  //                   await wishlistProduct(widget.productId);
                  //                 },
                  //                 icon: Icon(
                  //                   wishlist!
                  //                       ? Icons.favorite
                  //                       : Icons.favorite_border,
                  //                   color: Colors.red,
                  //                 ),
                  //                 color: Colors.red,
                  //                 iconSize: width * 0.075,
                  //               ),
                  //       ],
                  //     ),

                  //     // PRICE
                  //     Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Padding(
                  //           padding: const EdgeInsets.symmetric(vertical: 6),
                  //           child: Text(
                  //             'Rs. ${price.round()}',
                  //             style: TextStyle(
                  //               fontSize: width * 0.045,
                  //               fontWeight: FontWeight.w500,
                  //             ),
                  //           ),
                  //         ),

                  //         // RATINGS
                  //         Container(
                  //           decoration: BoxDecoration(
                  //             color: const Color.fromRGBO(
                  //               255,
                  //               92,
                  //               78,
                  //               1,
                  //             ),
                  //             borderRadius: BorderRadius.circular(4),
                  //           ),
                  //           padding: EdgeInsets.symmetric(
                  //             horizontal: width * 0.0125,
                  //             vertical: width * 0.00625,
                  //           ),
                  //           margin: EdgeInsets.all(
                  //             width * 0.00625,
                  //           ),
                  //           child: Text(
                  //             '${(ratings as Map).isEmpty ? '--' : ((ratings!.values.map((e) => e?[0] ?? 0).toList().reduce((a, b) => a + b) / (ratings!.values.isEmpty ? 1 : ratings!.values.length)) as double).toStringAsFixed(1)} ⭐',
                  //             style: const TextStyle(
                  //               color: white,
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ],
                  // ),

                  // // VENDOR INFO
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(vertical: 12),
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       Navigator.of(context).push(
                  //         MaterialPageRoute(
                  //           builder: ((context) => VendorPage(
                  //                 vendorId: vendorId!,
                  //               )),
                  //         ),
                  //       );
                  //     },
                  //     child: Row(
                  //       children: [
                  //         CircleAvatar(
                  //           backgroundImage: NetworkImage(vendorImage!),
                  //           radius: width * 0.04,
                  //         ),
                  //         Padding(
                  //           padding: const EdgeInsets.only(left: 8),
                  //           child: Text(
                  //             vendorName!,
                  //             style: TextStyle(
                  //               fontSize: width * 0.045,
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
      ),
    );
  }
}
