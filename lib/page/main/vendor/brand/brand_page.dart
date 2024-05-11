import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/page/main/product/product_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/image_show.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BrandPage extends StatefulWidget {
  const BrandPage({
    super.key,
    required this.brandId,
  });

  final String brandId;

  @override
  State<BrandPage> createState() => _BrandPageState();
}

class _BrandPageState extends State<BrandPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  String? id;
  String? name;
  String? imageUrl;
  Map? products;

  // INIT STATE
  @override
  void initState() {
    getData();
    getProducts();
    super.initState();
  }

  // GET DATA
  Future<void> getData() async {
    final brandSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Brands')
        .doc(widget.brandId)
        .get();

    final brandData = brandSnap.data()!;
    final brandId = brandData['brandId'];
    final brandName = brandData['brandName'];
    final brandImageUrl = brandData['imageUrl'];

    setState(() {
      id = brandId;
      name = brandName;
      imageUrl = brandImageUrl;
    });
  }

  // GET PRODUCTS
  Future<void> getProducts() async {
    Map product = {};
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('productBrandId', isEqualTo: widget.brandId)
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

    int noOfWishList = productData['productWishlist'] ?? 0;

    if (!alreadyInWishlist) {
      noOfWishList++;
    } else {
      noOfWishList--;
    }

    await productDoc.update({
      'productWishlist': noOfWishList,
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
      appBar: AppBar(),
      body: id == null || name == null || imageUrl == null || products == null
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

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
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
                                name!,
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
                              ? Container()
                              : SizedBox(
                                  width: width,
                                  height:
                                      getScreenHeight(width) - width * 0.285,
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: products!.length <= 3
                                        ? const NeverScrollableScrollPhysics()
                                        : const ClampingScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                    ),
                                    itemCount: products!.length,
                                    itemBuilder: ((context, index) {
                                      final id = products!.keys.toList()[index];
                                      final name =
                                          products!.values.toList()[index][0];
                                      final price =
                                          products!.values.toList()[index][1];
                                      final imageUrl =
                                          products!.values.toList()[index][2];

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
                                                                            0.04,
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
                                                                            0.045,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
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
                                                              color: Colors.red,
                                                              size: width *
                                                                  0.0775,
                                                            ),
                                                            splashColor:
                                                                Colors.red,
                                                            tooltip: 'Wishlist',
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
                    );
                  }),
                ),
              ),
            ),
    );
  }
}
