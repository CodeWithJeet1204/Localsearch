import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localy_user/page/main/vendor/product/product_page.dart';
import 'package:localy_user/page/main/vendor/brand/all_brand_page.dart';
import 'package:localy_user/page/main/vendor/brand/brand_page.dart';
import 'package:localy_user/page/main/vendor/category/all_category_page.dart';
import 'package:localy_user/page/main/vendor/category/category_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/image_show.dart';
import 'package:localy_user/widgets/see_more_text.dart';
import 'package:localy_user/widgets/snack_bar.dart';
import 'package:localy_user/widgets/text_button.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum EventSorting {
  recentlyAdded,
  highestRated,
  mostViewed,
  lowestPrice,
  highestPrice,
}

class VendorPage extends StatefulWidget {
  const VendorPage({
    super.key,
    required this.vendorId,
  });

  final String vendorId;

  @override
  State<VendorPage> createState() => _VendorPageState();
}

class _VendorPageState extends State<VendorPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, dynamic>? shopData;
  Map<String, dynamic>? ownerData;
  bool isFollowing = false;
  Map brands = {};
  List? allDiscounts;
  Map<String, String>? categories;
  Map<String, dynamic> products = {};
  String? productSort = 'Recently Added';
  final ScrollController scrollController = ScrollController();
  int numProductsLoaded = 7;

  // INIT STATE
  @override
  void initState() {
    getVendorInfo();
    getIfFollowing();
    getBrands();
    getDiscounts();
    getProducts();
    sortProducts(EventSorting.recentlyAdded);
    super.initState();
    scrollController.addListener(scrollListener);
    setRecentShop();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // SCROLL LISTENER
  void scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      loadMoreProducts();
    }
  }

  // LOAD MORE PRODUCTS
  void loadMoreProducts() {
    setState(() {
      numProductsLoaded += 7;
    });
  }

  // SET RECENT SHOP
  Future<void> setRecentShop() async {
    await Timer(
      const Duration(seconds: 5),
      () async {
        await setRecentAndUpdate();
      },
    );
  }

  // SET RECENT AND UPDATE
  Future<void> setRecentAndUpdate() async {
    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'recentShop': widget.vendorId,
    });

    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    int views = vendorData['Views'] ?? 0;
    List viewsTimestamp = vendorData['viewsTimestamp'] ?? [];

    viewsTimestamp.add(DateTime.now());

    views = views + 1;

    await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .update({
      'Views': views,
      'viewsTimestamp': viewsTimestamp,
    });
  }

  // GET IF FOLLOWING
  Future<void> getIfFollowing() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final following = userData['followedShops'];

    setState(() {
      if ((following as List).contains(widget.vendorId)) {
        isFollowing = true;
      } else {
        isFollowing = false;
      }
    });
  }

  // GET VENDOR INFO
  Future<void> getVendorInfo() async {
    final shopSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final currentShopData = shopSnap.data()!;

    setState(() {
      shopData = currentShopData;
    });

    final ownerSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Users')
        .doc(widget.vendorId)
        .get();

    final currentOwnerData = ownerSnap.data()!;

    setState(() {
      ownerData = currentOwnerData;
    });
    print('Owner1: $ownerData');
    print('Shop1: $shopData');

    await getCategories();
  }

  // FOLLOW SHOP
  Future<void> followShop() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final followedShops = userData['followedShops'] as List;

    if (followedShops.contains(widget.vendorId)) {
      followedShops.remove(widget.vendorId);
    } else {
      followedShops.add(widget.vendorId);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'followedShops': followedShops,
    });

    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    List followers = vendorData['Followers'];

    if (followers.contains(auth.currentUser!.uid)) {
      followers.remove(auth.currentUser!.uid);
    } else {
      followers.add(auth.currentUser!.uid);
    }

    await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .update({
      'Followers': followers,
    });

    await getIfFollowing();
  }

  // CALL VENDOR
  Future<void> callVendor() async {
    final Uri url = Uri(
      scheme: 'tel',
      path: ownerData!['Phone Number'],
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        mySnackBar('Some error occured', context);
      }
    }
  }

  // GET BRANDS
  Future<void> getBrands() async {
    Map brand = {};
    final brandSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Brands')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    for (var brandData in brandSnap.docs) {
      final id = brandData['brandId'];
      final imageUrl = brandData['imageUrl'];

      brand[id] = imageUrl;
    }

    setState(() {
      brands = brand;
    });
  }

  // GET DISCOUNTS
  Future<void> getDiscounts() async {
    final discountSnapshot = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    List<Map<String, dynamic>> allDiscount = [];

    for (QueryDocumentSnapshot<Map<String, dynamic>> doc
        in discountSnapshot.docs) {
      final data = doc.data();

      if ((data['discountEndDateTime'] as Timestamp)
              .toDate()
              .isAfter(DateTime.now()) &&
          !(data['discountStartDateTime'] as Timestamp)
              .toDate()
              .isAfter(DateTime.now())) {
        allDiscount.add(data);
      }
    }

    setState(() {
      allDiscounts = allDiscount;
    });
  }

  // GET CATEGORIES
  Future<void> getCategories() async {
    Map<String, String> category = {};
    print('Owner2: $ownerData');
    print('Shop2: $shopData');
    final categoriesSnap = await store
        .collection('Business')
        .doc('Special Categories')
        .collection(shopData!['Type'])
        .get();

    print(categoriesSnap.docs.length);

    for (var categoryData in categoriesSnap.docs) {
      final List vendorIds = categoryData['vendorId'];
      if (vendorIds.contains(widget.vendorId)) {
        final name = categoryData['specialCategoryName'] as String;
        final imageUrl = categoryData['specialCategoryImageUrl'] as String;

        category[name] = imageUrl;
      }
    }

    setState(() {
      categories = category;
    });
  }

  // GET PRODUCTS
  Future<void> getProducts() async {
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    Map<String, List<dynamic>> productsData = {};

    for (var productData in productsSnap.docs) {
      final id = productData['productId'];
      final name = productData['productName'];
      final imageUrl = productData['images'][0];
      final price = productData['productPrice'];
      final ratings = productData['ratings'];
      final datetime = productData['datetime'];
      final views = productData['productViews'];
      final data = productData.data();

      productsData[id] = [
        name,
        imageUrl,
        price,
        ratings,
        datetime,
        views,
        data,
      ];
    }

    setState(() {
      products = productsData;
    });
  }

  // SORT PRODUCTS
  void sortProducts(EventSorting sorting) {
    setState(() {
      switch (sorting) {
        case EventSorting.recentlyAdded:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) => (b.value[4] as Timestamp).compareTo(a.value[4])));
          break;
        case EventSorting.highestRated:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) => calculateAverageRating(b.value[3])
                .compareTo(calculateAverageRating(a.value[3]))));
          break;
        case EventSorting.mostViewed:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) => (b.value[5] as int).compareTo(a.value[5])));
          break;
        case EventSorting.lowestPrice:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) =>
                double.parse(a.value[2]).compareTo(double.parse(b.value[2]))));
          break;
        case EventSorting.highestPrice:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) =>
                double.parse(b.value[2]).compareTo(double.parse(a.value[2]))));
          break;
      }
    });
  }

  // CALCULATE AVERAGE RATINGS
  double calculateAverageRating(Map<String, dynamic> ratings) {
    if (ratings.isEmpty) return 0.0;

    final allRatings = ratings.values.map((e) => e[0] as int).toList();

    final sum = allRatings.reduce((value, element) => value + element);

    final averageRating = sum / allRatings.length;

    return averageRating;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(FeatherIcons.share2),
            tooltip: 'Share Shop',
          ),
          IconButton(
            onPressed: () async {
              await showYouTubePlayerDialog(
                context,
                getYoutubeVideoId(
                  '',
                ),
              );
            },
            icon: Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: "Help",
          ),
        ],
      ),
      body: shopData == null || ownerData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.00625,
                ),
                child: LayoutBuilder(builder: ((context, constraints) {
                  final width = constraints.maxWidth;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SHOP INFO
                        Container(
                          width: width,
                          decoration: BoxDecoration(
                            color: primary2.withOpacity(0.125),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.00625,
                            vertical: width * 0.0166,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // INFO
                              GestureDetector(
                                onTap: () async {
                                  await showDialog(
                                    context: context,
                                    builder: ((context) => ImageShow(
                                          imageUrl: shopData!['Image'],
                                          width: width,
                                        )),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: width * 0.1,
                                  backgroundImage: NetworkImage(
                                    shopData!['Image'],
                                  ),
                                ),
                              ),

                              SizedBox(height: width * 0.0225),

                              SizedBox(height: width * 0.0225),

                              Text(
                                shopData!['Type'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                ),
                              ),
                              SizedBox(height: width * 0.025),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // FOLLOW
                                  GestureDetector(
                                    onTap: () async {
                                      await followShop();
                                    },
                                    child: Container(
                                      width: width * 0.4125,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isFollowing ? black : lightGrey,
                                        border: Border.all(
                                          color:
                                              isFollowing ? lightGrey : black,
                                          width: 0.75,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: TextStyle(
                                          color: isFollowing ? white : black,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // CALL
                                  GestureDetector(
                                    onTap: () async {
                                      await callVendor();
                                    },
                                    child: Container(
                                      width: width * 0.25,
                                      height: 40,
                                      alignment: Alignment.center,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.00625,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.5),
                                        border: Border.all(
                                          color: primaryDark.withOpacity(0.5),
                                          width: 0.25,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Call',
                                            style: TextStyle(
                                              color: primaryDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Icon(FeatherIcons.phone),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // WHATSAPP
                                  GestureDetector(
                                    onTap: () async {
                                      final String phoneNumber =
                                          ownerData!['Phone Number'];
                                      final String message =
                                          'Hey, I found you on Localy\n';
                                      final url =
                                          'https://wa.me/$phoneNumber?text=$message';

                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      } else {
                                        mySnackBar(
                                          'Something went Wrong',
                                          context,
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: width * 0.275,
                                      height: 40,
                                      alignment: Alignment.center,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.00625,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                          198,
                                          255,
                                          200,
                                          1,
                                        ),
                                        border: Border.all(
                                          color: primaryDark.withOpacity(0.25),
                                          width: 0.25,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Whatsapp',
                                            style: TextStyle(
                                              color: primaryDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Icon(FeatherIcons.messageCircle),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: width * 0.0225),

                              const Divider(),

                              SizedBox(height: width * 0.0125),

                              // NAME
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.0125,
                                  vertical: width * 0.0175,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: width * 0.8,
                                      child: Text(
                                        ownerData!['Name'],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: width * 0.034,
                                      ),
                                      child: Icon(FeatherIcons.user),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: width * 0.033),

                              // ADDRESS
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.0125,
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    String encodedAddress =
                                        Uri.encodeFull(shopData!['Address']);

                                    Uri mapsUrl = Uri.parse(
                                        'https://www.google.com/maps/search/?api=1&query=$encodedAddress');

                                    if (await canLaunchUrl(mapsUrl)) {
                                      await launchUrl(mapsUrl);
                                    } else {
                                      mySnackBar(
                                        'Something went Wrong',
                                        context,
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: width * 0.8,
                                        child: Text(
                                          shopData!['Address'],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          String encodedAddress =
                                              Uri.encodeFull(
                                                  shopData!['Address']);

                                          Uri mapsUrl = Uri.parse(
                                              'https://www.google.com/maps/search/?api=1&query=$encodedAddress');

                                          if (await canLaunchUrl(mapsUrl)) {
                                            await launchUrl(mapsUrl);
                                          } else {
                                            mySnackBar(
                                              'Something went Wrong',
                                              context,
                                            );
                                          }
                                        },
                                        icon: const Icon(FeatherIcons.mapPin),
                                        tooltip: 'Locate on Maps',
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: width * 0.033),

                              // INDUSTRY
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.0125,
                                  vertical: width * 0.0175,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: width * 0.8,
                                      child: Text(
                                        shopData!['Industry'],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: width * 0.034,
                                      ),
                                      child: Icon(Icons.factory_outlined),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: width * 0.033),

                              // DESCRIPTION
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.015),
                                    child: SizedBox(
                                      width: width * 0.85,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: SeeMoreText(
                                          shopData!['Description'],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(right: width * 0.04),
                                    child: Icon(
                                      Icons.info_outline,
                                      size: width * 0.075,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        // BRAND
                        brands.isEmpty
                            ? Container()
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: width * 0.01,
                                  horizontal: width * 0.0125,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Brands',
                                      style: TextStyle(
                                        fontSize: width * 0.0425,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    brands.length <= 3
                                        ? Container()
                                        : MyTextButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: ((context) =>
                                                      AllBrandPage(
                                                        vendorId:
                                                            widget.vendorId,
                                                      )),
                                                ),
                                              );
                                            },
                                            text: 'See All',
                                            textColor: primaryDark,
                                          ),
                                  ],
                                ),
                              ),

                        // BRANDS
                        brands.isEmpty
                            ? Container()
                            : Container(
                                width: width,
                                height: width * 0.2,
                                margin: EdgeInsets.all(width * 0.00125),
                                padding: EdgeInsets.all(width * 0.00125),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  physics: brands.length > 4
                                      ? const AlwaysScrollableScrollPhysics()
                                      : const NeverScrollableScrollPhysics(),
                                  itemCount: brands.length,
                                  itemBuilder: ((context, index) {
                                    print("Brands: $brands");
                                    final id = brands.keys.toList()[index];
                                    final imageUrl =
                                        brands.values.toList()[index];

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) => BrandPage(
                                                  brandId: id,
                                                )),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: width * 0.2,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: width * 0.0125,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          image: DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                        brands.isEmpty ? Container() : const Divider(),

                        // DISCOUNT
                        allDiscounts == null || allDiscounts!.isEmpty
                            ? Container()
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: width * 0.01,
                                  horizontal: width * 0.0125,
                                ),
                                child: Text(
                                  'Offers',
                                  style: TextStyle(
                                    fontSize: width * 0.0425,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                        // DISCOUNTS
                        allDiscounts == null || allDiscounts!.isEmpty
                            ? Container()
                            : DiscountsWidget(
                                noOfDiscounts: allDiscounts!.length,
                                allDiscount: allDiscounts!,
                                vendorType: shopData!['Type'],
                              ),

                        allDiscounts == null || allDiscounts!.isEmpty
                            ? Container()
                            : const Divider(),

                        // CATEGORY
                        categories == null || categories!.isEmpty
                            ? Container()
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.0225,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Categories',
                                      style: TextStyle(
                                        fontSize: width * 0.0425,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    categories!.length <= 8
                                        ? Container()
                                        : MyTextButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: ((context) =>
                                                      AllCategoryPage(
                                                        vendorId:
                                                            widget.vendorId,
                                                      )),
                                                ),
                                              );
                                            },
                                            text: 'See All',
                                            textColor: primaryDark,
                                          ),
                                  ],
                                ),
                              ),

                        // CATEGORIES
                        categories == null || categories!.isEmpty
                            ? Container()
                            : Container(
                                width: width,
                                margin: EdgeInsets.symmetric(
                                  horizontal: width * 0.0125,
                                ),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 0.875,
                                  ),
                                  itemCount: categories!.length > 8
                                      ? 8
                                      : categories!.length,
                                  itemBuilder: ((context, index) {
                                    final name =
                                        categories!.keys.toList()[index];
                                    final imageUrl =
                                        categories!.values.toList()[index];

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) => CategoryPage(
                                                  categoryName: name,
                                                  vendorType: shopData!['Type'],
                                                )),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.network(
                                            imageUrl,
                                            width: width * 0.175,
                                            height: width * 0.175,
                                            fit: BoxFit.cover,
                                          ),
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: width * 0.035,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),

                        categories == null
                            ? Container()
                            : categories!.isEmpty
                                ? Container()
                                : const Divider(),

                        // PRODUCT & FILTER
                        products.isEmpty
                            ? Container()
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: width * 0.01,
                                  horizontal: width * 0.0125,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Products',
                                      style: TextStyle(
                                        fontSize: width * 0.0425,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primary3,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: DropdownButton<String>(
                                        underline: const SizedBox(),
                                        dropdownColor: primary2,
                                        value: productSort,
                                        iconEnabledColor: primaryDark,
                                        items: [
                                          'Recently Added',
                                          'Highest Rated',
                                          'Most Viewed',
                                          'Price - Highest to Lowest',
                                          'Price - Lowest to Highest'
                                        ]
                                            .map(
                                                (e) => DropdownMenuItem<String>(
                                                      value: e,
                                                      child: Text(e),
                                                    ))
                                            .toList(),
                                        onChanged: (value) {
                                          sortProducts(
                                            value == 'Recently Added'
                                                ? EventSorting.recentlyAdded
                                                : value == 'Highest Rated'
                                                    ? EventSorting.highestRated
                                                    : value == 'Most Viewed'
                                                        ? EventSorting
                                                            .mostViewed
                                                        : value ==
                                                                'Price - Highest to Lowest'
                                                            ? EventSorting
                                                                .highestPrice
                                                            : EventSorting
                                                                .lowestPrice,
                                          );
                                          setState(() {
                                            productSort = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                        // PRODUCTS
                        products.isEmpty
                            ? Container()
                            : SizedBox(
                                width: width,
                                height: getScreenHeight(width) -
                                    getScreenHeight(width) * 0.1,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: numProductsLoaded > products.length
                                      ? products.length
                                      : numProductsLoaded,
                                  itemBuilder: ((context, index) {
                                    final name =
                                        products.values.toList()[index][0];
                                    final imageUrl =
                                        products.values.toList()[index][1];
                                    final price =
                                        products.values.toList()[index][2];
                                    final ratings =
                                        products.values.toList()[index][3];
                                    final productData =
                                        products.values.toList()[index][6];
                                    final rating =
                                        calculateAverageRating(ratings);

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) => ProductPage(
                                                  productData: productData,
                                                )),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: width,
                                        // height: 150,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.0125,
                                          vertical: width * 0.0125,
                                        ),
                                        margin: EdgeInsets.all(
                                          width * 0.00625,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: index == 0
                                                ? const BorderSide(
                                                    color: darkGrey,
                                                    width: 0.25,
                                                  )
                                                : BorderSide.none,
                                            bottom: const BorderSide(
                                              color: darkGrey,
                                              width: 0.25,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    imageUrl,
                                                    width: width * 0.3,
                                                    height: width * 0.3,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                rating == 0
                                                    ? Text(
                                                        'No Reviews',
                                                        style: TextStyle(
                                                          fontSize:
                                                              width * 0.03,
                                                        ),
                                                      )
                                                    : Text('$rating ⭐'),
                                              ],
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: width * 0.6,
                                                  child: Text(
                                                    name,
                                                    style: TextStyle(
                                                      fontSize: width * 0.05,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  price == ''
                                                      ? 'Rs. --'
                                                      : 'Rs. $price',
                                                  style: TextStyle(
                                                    fontSize: width * 0.04,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
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
                })),
              ),
            ),
    );
  }
}

// DISCOUNTS WIDGET
class DiscountsWidget extends StatefulWidget {
  const DiscountsWidget({
    super.key,
    required this.noOfDiscounts,
    required this.allDiscount,
    required this.vendorType,
  });

  final int noOfDiscounts;
  final List allDiscount;
  final String vendorType;

  @override
  State<DiscountsWidget> createState() => _DiscountsWidgetState();
}

class _DiscountsWidgetState extends State<DiscountsWidget>
    with SingleTickerProviderStateMixin {
  final store = FirebaseFirestore.instance;

  // GET NAME
  Future<String> getName(
    int index,
    bool wantName, {
    Map<String, dynamic>? wantProductData,
  }) async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.allDiscount[index]['discountId'])
        .get();

    final discountData = discountSnap.data()!;
    final List products = discountData['products'];
    // final List categories = discountData['categories'];
    final List brands = discountData['brands'];

    // PRODUCT
    if (products.isNotEmpty) {
      final productId = products[0];

      final productSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(productId)
          .get();

      final productData = productSnap.data()!;

      final String name = productData['productName'];
      final String imageUrl = productData['images'][0];

      return wantName ? name : imageUrl;
    }

    // CATEGORY
    // if (categories.isNotEmpty) {
    //   final categoryId = categories[0];

    //   final categorySnap = await store
    //       .collection('Business')
    //       .doc('Data')
    //       .collection('Category')
    //       .doc(categoryId)
    //       .get();

    //   final categoryData = categorySnap.data()!;

    //   final name = categoryData['categoryName'];
    //   final imageUrl = categoryData['imageUrl'];

    //   return wantName ? name : imageUrl;
    // }

    // BRAND
    if (brands.isNotEmpty) {
      final brandId = brands[0];

      final brandSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Brands')
          .doc(brandId)
          .get();

      final brandData = brandSnap.data()!;

      final name = brandData['brandName'];
      final imageUrl = brandData['imageUrl'];

      return wantName ? name : imageUrl;
    }
    return '';
  }

  // GET PRODUCT DATA
  Future<Map<String, dynamic>> getProductData(int index) async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.allDiscount[index]['discountId'])
        .get();

    final discountData = discountSnap.data()!;
    final List products = discountData['products'];

    final productId = products[0];

    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .get();

    final productData = productSnap.data()!;

    return productData;
  }

  // GET CATEGORY ID
  Future<String> getCategoryId(int index) async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.allDiscount[index]['discountId'])
        .get();

    final discountData = discountSnap.data()!;
    final List categories = discountData['categories'];

    final categoryId = categories[0];

    return categoryId;
  }

  // GET BRAND ID
  Future<String> getBrandId(int index) async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.allDiscount[index]['discountId'])
        .get();

    final discountData = discountSnap.data()!;
    final List brands = discountData['brands'];

    final brandId = brands[0];

    return brandId;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.00125,
      ),
      child: SizedBox(
        width: width,
        height: width * 0.35,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          physics: widget.allDiscount.length > 3
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: widget.allDiscount.length,
          itemBuilder: ((context, index) {
            final currentDiscount = widget.allDiscount[index];
            // final String? image = currentDiscount['discountImageUrl'];
            final name = currentDiscount['discountName'];
            final amount = currentDiscount['discountAmount'];
            final isPercent = currentDiscount['isPercent'];
            final List products = currentDiscount['products'];
            final List categories = currentDiscount['categories'];
            final List brands = currentDiscount['brands'];
            // final endDate = currentDiscount['discountEndDateTime'];

            return Padding(
              padding: EdgeInsets.all(width * 0.0125),
              child: GestureDetector(
                onTap: () async {
                  if (products.isNotEmpty) {
                    final productData = await getProductData(index);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductPage(
                            productData: productData,
                          ),
                        ),
                      );
                    }
                  } else if (categories.isNotEmpty) {
                    final categoryId = await getCategoryId(index);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: ((context) => CategoryPage(
                                categoryName: categoryId,
                                vendorType: widget.vendorType,
                              )),
                        ),
                      );
                    }
                  } else if (brands.isNotEmpty) {
                    final brandId = await getBrandId(index);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: ((context) => BrandPage(
                                brandId: brandId,
                              )),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: width * 0.25,
                  // padding: EdgeInsets.all(
                  //   width * 0.00325,
                  // ),
                  decoration: BoxDecoration(
                    color: white,
                    border: Border.all(
                      width: 0.125,
                      color: black,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IMAGE
                      FutureBuilder(
                          future: getName(index, false),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: Image.network(
                                      snapshot.data ??
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/ProhibitionSign2.svg/800px-ProhibitionSign2.svg.png',
                                      fit: BoxFit.cover,
                                      width: width * 0.25,
                                      height: width * 0.25,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(
                                      width * 0.00675,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(2),
                                        bottomRight: Radius.circular(4),
                                      ),
                                      boxShadow: [
                                        BoxShadow(),
                                      ],
                                    ),
                                    child: Text(
                                      isPercent
                                          ? '$amount %'
                                          : 'Save Rs. $amount',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 255, 30, 14),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                ],
                              );
                            }

                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }),

                      // NAME
                      FutureBuilder(
                          future: getName(index, true),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.00625,
                                ),
                                child: Text(
                                  snapshot.data ?? name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                  ),
                                ),
                              );
                            }

                            return Container();
                          }),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
