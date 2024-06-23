// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localy_user/models/business_categories.dart';
import 'package:localy_user/page/main/all_discount_page.dart';
import 'package:localy_user/page/main/vendor/category/all_shop_types_page.dart';
import 'package:localy_user/page/main/vendor/category/shop_categories_page.dart';
import 'package:localy_user/page/main/vendor/product/product_page.dart';
import 'package:localy_user/page/main/search/search_page.dart';
import 'package:localy_user/page/main/vendor/vendor_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/skeleton_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localy_user/widgets/video_tutorial.dart';

class ProductHomePage extends StatefulWidget {
  const ProductHomePage({super.key});

  @override
  State<ProductHomePage> createState() => _ProductHomePageState();
}

class _ProductHomePageState extends State<ProductHomePage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  String recentShop = '';
  List<String> recentShopProducts = [];
  List<String> recentShopProductsImages = [];
  List<String> recentShopProductsNames = [];
  List<Map<String, dynamic>> recentShopProductsData = [];
  Map<String, dynamic> wishlist = {};
  Map<String, dynamic> followedShops = {};
  bool getRecentData = false;
  bool getWishlistData = false;
  bool getFollowedData = false;
  int noOfDiscounts = 0;

  List<int> numbers = [0, 1, 2, 3];
  List<int> reverseNumbers = [4, 5, 6, 7];

  // INIT STATE
  @override
  void initState() {
    getNoOfDiscounts();
    getRecentShop();
    getWishlist();
    getFollowedShops();
    super.initState();
  }

  // DID CHANGE DEPENDENCIES
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getRecentShop();
  }

  // GET NO. OF DISCOUNTS
  Future<void> getNoOfDiscounts() async {
    int myNoOfDiscounts = 0;
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .get();

    discountSnap.docs.forEach((discount) {
      final discountData = discount.data();

      final Timestamp endDateTime = discountData['discountEndDateTime'];

      if (endDateTime.toDate().isAfter(DateTime.now())) {
        myNoOfDiscounts++;
      }
    });

    setState(() {
      noOfDiscounts = myNoOfDiscounts;
    });
  }

  // GET RECENT SHOP
  Future<void> getRecentShop() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    if (context.mounted) {
      if (mounted) {
        setState(() {
          recentShop = userData['recentShop'];
        });
      }
    }

    await getNoOfProductsOfRecentShop();
  }

  // GET NO OF PRODUCTS OF RECENT SHOP
  Future<void> getNoOfProductsOfRecentShop() async {
    final recentProducts = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('vendorId', isEqualTo: recentShop)
        .get();

    for (final doc in recentProducts.docs) {
      if (!recentShopProducts.contains(doc['productId'])) {
        recentShopProducts.add(doc['productId']);
      }
    }

    await getRecentShopProductInfo();
  }

  // GET RECENT SHOP PRODUCT INFO
  Future<int> getRecentShopProductInfo() async {
    List<String> temporaryNameList = [];
    List<String> temporaryImageList = [];
    List<Map<String, dynamic>> temporaryDataList = [];
    recentShopProducts.forEach((productId) async {
      final productData = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(productId)
          .get();

      temporaryNameList.add(productData['productName']);
      temporaryImageList.add(productData['images'][0]);
      temporaryDataList.add(productData.data()!);
      if (context.mounted) {
        if (mounted) {
          setState(() {
            recentShopProductsNames = temporaryNameList;
            recentShopProductsImages = temporaryImageList;
            recentShopProductsData = temporaryDataList;
          });
        }
      }
    });

    setState(() {
      getRecentData = true;
    });

    return recentShopProductsImages.length;
  }

  // GET WISHLIST
  Future<void> getWishlist() async {
    Map<String, List> myWishlist = {};
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final List wishlists = userData['wishlists'];

    wishlists.forEach((productId) async {
      final productSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(productId)
          .get();

      final productData = productSnap.data()!;

      final String name = productData['productName'];
      final String imageUrl = productData['images'][0];

      myWishlist[productId] = [name, imageUrl, productData];
    });

    setState(() {
      wishlist = myWishlist;
      getWishlistData = true;
    });
  }

  // GET FOLLOWED SHOPS
  Future<void> getFollowedShops() async {
    Map<String, List> myFollowedShops = {};
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final List followedShop = userData['followedShops'];

    followedShop.forEach((vendorId) async {
      final vendorSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .doc(vendorId)
          .get();

      final vendorData = vendorSnap.data();

      if (vendorData != null) {
        final String? name = vendorData['Name'];
        final String? imageUrl = vendorData['Image'];

        myFollowedShops[vendorId] = [name, imageUrl];
      }
    });

    setState(() {
      followedShops = myFollowedShops;
      getFollowedData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.0125,
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              await getRecentShop();
              await getWishlist();
              await getFollowedShops();
            },
            color: primaryDark,
            backgroundColor: const Color.fromARGB(255, 243, 253, 255),
            semanticsLabel: 'Refresh',
            child: LayoutBuilder(
              builder: ((context, constraints) {
                final double width = constraints.maxWidth;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEARCH
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.0125,
                          vertical: width * 0.0125,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: ((context) => const SearchPage()),
                              ),
                            );
                          },
                          splashColor: white.withOpacity(0.125),
                          customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            width: width,
                            height: width * 0.15,
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.05,
                            ),
                            decoration: BoxDecoration(
                              color: primary2.withOpacity(0.1),
                              border: Border.all(
                                color: primaryDark.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Search...',
                                  style: TextStyle(
                                    color: primaryDark2.withOpacity(0.8),
                                    fontSize: width * 0.045,
                                  ),
                                ),
                                Icon(
                                  FeatherIcons.search,
                                  color: primaryDark2.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ONGOING DISCOUNTS
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => AllDiscountPage()),
                          );
                        },
                        child: Container(
                          width: width,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade300,
                                Colors.orange.shade300,
                                Colors.yellow.shade300,
                                Colors.green.shade300,
                                Colors.blue.shade300,
                                Colors.indigo.shade300,
                                Color.fromRGBO(143, 30, 255, 1),
                              ],
                            ),
                            border: Border.all(
                              width: 2,
                              color: primaryDark,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: width * 0.0125,
                            vertical: 4,
                          ),
                          child: Text(
                            "ONGOING OFFERS - $noOfDiscounts",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryDark,
                              fontSize: width * 0.066,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      Divider(),

                      // SHOP TYPES
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.025,
                          vertical: width * 0.025,
                        ),
                        child: Text(
                          'Shop Types',
                          style: TextStyle(
                            color: primaryDark,
                            fontSize: width * 0.0675,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // SHOP TYPES BOX
                      Container(
                        width: width,
                        height: width * 0.65,
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: lightGrey,
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.only(
                          right: width * 0.02,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: width,
                              height: width * 0.3,
                              child: ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 4,
                                itemBuilder: ((context, index) {
                                  final String name =
                                      businessCategories[numbers[index]][0];
                                  final String imageUrl =
                                      businessCategories[numbers[index]][1];

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.025,
                                      vertical: width * 0.015,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) =>
                                                ShopCategoriesPage(
                                                  shopName: name,
                                                )),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: width * 0.2,
                                        height: width * 0.25,
                                        decoration: BoxDecoration(
                                          color: white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.0125,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  height: width * 0.175,
                                                ),
                                              ),
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: primaryDark,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: width * 0.725,
                                  height: width * 0.3,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: 3,
                                    itemBuilder: ((context, index) {
                                      final String name = businessCategories[
                                          reverseNumbers[index]][0];
                                      final String imageUrl =
                                          businessCategories[
                                              reverseNumbers[index]][1];

                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.025,
                                          vertical: width * 0.015,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    ShopCategoriesPage(
                                                      shopName: name,
                                                    )),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: width * 0.2,
                                            height: width * 0.25,
                                            decoration: BoxDecoration(
                                              color: white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.0125,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image.network(
                                                      imageUrl,
                                                      height: width * 0.175,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Text(
                                                    name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                                // SEE ALL
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: ((context) =>
                                            const AllShopTypesPage()),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: width * 0.225,
                                    height: width * 0.25,
                                    decoration: BoxDecoration(
                                      color: primary2.withOpacity(0.125),
                                      border: Border.all(
                                        width: 0.125,
                                        color: primaryDark,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          FeatherIcons.grid,
                                          color: primaryDark,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'See All',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // CONTINUE SHOPPING
                      recentShop == ''
                          ? Container()
                          : !getRecentData
                              ? Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: SkeletonContainer(
                                    width: width * 0.6,
                                    height: 32,
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.025,
                                  ),
                                  child: Text(
                                    'Continue Shopping',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: width * 0.07,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                      // CONTINUE SHOPPING PRODUCTS
                      recentShop == ''
                          ? Container()
                          : !getRecentData
                              ? SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 4,
                                    itemBuilder: ((context, index) {
                                      return Container(
                                        width: width * 0.28,
                                        height: width * 0.4,
                                        decoration: BoxDecoration(
                                          color: lightGrey,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        margin: EdgeInsets.all(width * 0.0225),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SkeletonContainer(
                                              width: width * 0.25,
                                              height: width * 0.275,
                                            ),
                                            SkeletonContainer(
                                              width: width * 0.225,
                                              height: width * 0.033,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              : SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        recentShopProductsImages.length > 4
                                            ? 4
                                            : recentShopProductsImages.length,
                                    itemBuilder: ((context, index) {
                                      final String name =
                                          recentShopProductsNames[index];
                                      final String imageUrl =
                                          recentShopProductsImages[index];

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) =>
                                                  ProductPage(
                                                    productData:
                                                        recentShopProductsData[
                                                            index],
                                                  )),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: width * 0.3,
                                          height: width * 0.2,
                                          decoration: BoxDecoration(
                                            color: white,
                                            border: Border.all(
                                              width: 0.25,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          padding: EdgeInsets.all(
                                            width * 0.00625,
                                          ),
                                          margin: EdgeInsets.all(
                                            width * 0.0125,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: width * 0.3,
                                                  height: width * 0.3,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: width * 0.00625,
                                                  left: width * 0.0125,
                                                ),
                                                child: Text(
                                                  name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: width * 0.05,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                      // WISHLIST
                      wishlist.isEmpty
                          ? Container()
                          : !getWishlistData
                              ? Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: SkeletonContainer(
                                    width: width * 0.6,
                                    height: 32,
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.025,
                                  ),
                                  child: Text(
                                    'Your Wishlists ❤️',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: width * 0.07,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                      // WISHLIST PRODUCTS
                      wishlist.isEmpty
                          ? Container()
                          : !getWishlistData
                              ? SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 4,
                                    itemBuilder: ((context, index) {
                                      return Padding(
                                        padding: EdgeInsets.all(width * 0.0225),
                                        child: Container(
                                          width: width * 0.28,
                                          height: width * 0.4,
                                          decoration: BoxDecoration(
                                            color: lightGrey,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SkeletonContainer(
                                                width: width * 0.25,
                                                height: width * 0.275,
                                              ),
                                              SkeletonContainer(
                                                width: width * 0.225,
                                                height: width * 0.033,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              : SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: wishlist.length > 4
                                        ? 4
                                        : wishlist.length,
                                    itemBuilder: ((context, index) {
                                      final String name =
                                          wishlist.values.toList()[index][0];
                                      final String imageUrl =
                                          wishlist.values.toList()[index][1];
                                      final Map<String, dynamic> productData =
                                          wishlist.values.toList()[index][2];

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) =>
                                                  ProductPage(
                                                    productData: productData,
                                                  )),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: width * 0.3,
                                          height: width * 0.2,
                                          decoration: BoxDecoration(
                                            color: white,
                                            border: Border.all(
                                              width: 0.25,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          padding: EdgeInsets.all(
                                            width * 0.00625,
                                          ),
                                          margin: EdgeInsets.all(
                                            width * 0.0125,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: width * 0.3,
                                                  height: width * 0.3,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: width * 0.00625,
                                                  left: width * 0.0125,
                                                ),
                                                child: Text(
                                                  name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: width * 0.05,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                      // FOLLOWED
                      followedShops.isEmpty
                          ? Container()
                          : !getFollowedData
                              ? Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: SkeletonContainer(
                                    width: width * 0.6,
                                    height: 32,
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.025,
                                  ),
                                  child: Text(
                                    'Followed Shops',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: width * 0.07,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                      // FOLLOWED SHOPS
                      followedShops.isEmpty
                          ? Container()
                          : !getFollowedData
                              ? SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 4,
                                    itemBuilder: ((context, index) {
                                      return Padding(
                                        padding: EdgeInsets.all(width * 0.0225),
                                        child: Container(
                                          width: width * 0.28,
                                          height: width * 0.4,
                                          decoration: BoxDecoration(
                                            color: lightGrey,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SkeletonContainer(
                                                width: width * 0.25,
                                                height: width * 0.275,
                                              ),
                                              SkeletonContainer(
                                                width: width * 0.225,
                                                height: width * 0.033,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              : SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: followedShops.length > 4
                                        ? 4
                                        : followedShops.length,
                                    itemBuilder: ((context, index) {
                                      final String vendorId =
                                          followedShops.keys.toList()[index];
                                      final String name = followedShops.values
                                          .toList()[index][0];
                                      final String imageUrl =
                                          followedShops.values.toList()[index]
                                              [1];

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) => VendorPage(
                                                    vendorId: vendorId,
                                                  )),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: width * 0.3,
                                          height: width * 0.2,
                                          decoration: BoxDecoration(
                                            color: white,
                                            border: Border.all(
                                              width: 0.25,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          padding: EdgeInsets.all(
                                            width * 0.00625,
                                          ),
                                          margin: EdgeInsets.all(
                                            width * 0.0125,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: width * 0.3,
                                                  height: width * 0.3,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: width * 0.00625,
                                                  left: width * 0.0125,
                                                ),
                                                child: Text(
                                                  name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: width * 0.05,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
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
      ),
    );
  }
}
