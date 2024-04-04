import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/search/search_results_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/image_view.dart';
import 'package:find_easy_user/widgets/see_more_text.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:find_easy_user/widgets/speech_to_text.dart';
import 'package:find_easy_user/widgets/text_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({
    super.key,
    required this.productData,
    this.search,
  });

  final Map<String, dynamic> productData;
  final String? search;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  final reviewController = TextEditingController();
  bool isMicPressed = false;
  bool isSearchPressed = false;
  int _currentIndex = 0;
  bool isWishListed = false;
  String? vendorName;
  bool isVendorHold = false;
  bool? isDiscount;
  String? brandImageUrl;
  String? categoryImageUrl;
  List<Map<String, dynamic>> similarProductsDatas = [];
  bool similarProductsAdded = false;
  double userRating = 0.0;
  bool? hasReviewedBefore;
  double? previousRating;
  String? previousReview;
  String? newReview;
  bool reviewAdded = false;

  // INIT STATE
  @override
  void initState() {
    getVendorInfo();
    getIfDiscount();
    getIfWishlist(widget.productData['productId']);
    getBrandImage();
    getCategoryImage();
    getSimilarProducts(
      widget.productData['productName'],
      search: widget.search,
    );
    checkIfReviewed();
    super.initState();
  }

  // LISTEN
  Future<void> listen() async {
    var result = await showDialog(
      context: context,
      builder: ((context) => SpeechToText()),
    );

    if (result != null && result is String) {
      searchController.text = result;
    }
  }

  // SEARCH
  Future<void> search() async {
    await addRecentSearch();

    var searchController;
    if (searchController.text.isNotEmpty) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: ((context) =>
              SearchResultsPage(search: searchController.text)),
        ),
      );
    }
  }

  // ADD RECENT SEARCH
  Future<void> addRecentSearch() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final recent = userData['recentSearches'] as List;

    if (recent.contains(searchController.text)) {
      recent.remove(searchController.text);
    }

    if (searchController.text.isNotEmpty) {
      recent.insert(0, searchController.text);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'recentSearches': recent,
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
    setState(() {
      isWishListed = !isWishListed;
    });
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

  // GET VENDOR INFO
  Future<void> getVendorInfo() async {
    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.productData['vendorId'])
        .get();

    final vendorData = vendorSnap.data()!;

    setState(() {
      vendorName = vendorData['Name'];
    });
  }

  // IF DISCOUNT
  Future<void> getIfDiscount() async {
    final discountSnapshot = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .where('vendorId', isEqualTo: widget.productData['vendorId'])
        .get();

    for (QueryDocumentSnapshot<Map<String, dynamic>> doc
        in discountSnapshot.docs) {
      final data = doc.data();

      // Product
      if (data['isProducts'] &&
          (data['products'] as List)
              .contains(widget.productData['productId'])) {
        // Check if the discount is active
        if ((data['discountEndDateTime'] as Timestamp)
                .toDate()
                .isAfter(DateTime.now()) &&
            !(data['discountStartDateTime'] as Timestamp)
                .toDate()
                .isAfter(DateTime.now())) {
          setState(() {
            isDiscount = true;
          });
          return;
        }
      }

      // Brand
      if (data['isBrands'] &&
          (data['brands'] as List).contains(widget.productData['brandId'])) {
        // Check if the discount is active
        if ((data['discountEndDateTime'] as Timestamp)
                .toDate()
                .isAfter(DateTime.now()) &&
            !(data['discountStartDateTime'] as Timestamp)
                .toDate()
                .isAfter(DateTime.now())) {
          setState(() {
            isDiscount = true;
          });
          return;
        }
      }

      // Category
      if (data['isCategories'] &&
          (data['categories'] as List)
              .contains(widget.productData['categoryId'])) {
        // Check if the discount is active
        if ((data['discountEndDateTime'] as Timestamp)
                .toDate()
                .isAfter(DateTime.now()) &&
            !(data['discountStartDateTime'] as Timestamp)
                .toDate()
                .isAfter(DateTime.now())) {
          setState(() {
            isDiscount = true;
          });
          return;
        }
      }
    }
  }

  // GET BRAND IMAGE
  Future<void> getBrandImage() async {
    final brandSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Brands')
        .doc(widget.productData['brandId'])
        .get();

    if (brandSnap.exists) {
      final brandData = brandSnap.data()!;

      final brandImage = brandData['imageUrl'];

      setState(() {
        brandImageUrl = brandImage;
      });
    }
  }

  // GET CATEGORY IMAGE
  Future<void> getCategoryImage() async {
    final categorySnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Category')
        .doc(widget.productData['categoryId'])
        .get();

    if (categorySnap.exists) {
      final categoryData = categorySnap.data()!;

      final categoryImage = categoryData['imageUrl'];

      setState(() {
        categoryImageUrl = categoryImage;
      });
    }
  }

  // GIVE PROPERTY DATA
  Map<String, List> givePropertyData(
    String name0,
    String name1,
    String name2,
    String name3,
    String name4,
    String name5,
    List property0,
    List property1,
    List property2,
    List property3,
    List property4,
    List property5,
  ) {
    Map<String, List> properties = {};
    if (name0 != '' && property0.isNotEmpty) {
      properties[name0] = property0;
    }
    if (name1 != '' && property1.isNotEmpty) {
      properties[name1] = property1;
    }
    if (name2 != '' && property2.isNotEmpty) {
      properties[name2] = property2;
    }
    if (name3 != '' && property3.isNotEmpty) {
      properties[name3] = property3;
    }
    if (name4 != '' && property4.isNotEmpty) {
      properties[name4] = property4;
    }
    if (name5 != '' && property5.isNotEmpty) {
      properties[name5] = property5;
    }

    return properties;
  }

  // GET SIMILAR PRODUCTS
  Future<void> getSimilarProducts(String productName, {String? search}) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> searchedProductDocs = [];
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .get();

    final productDocs = productsSnap.docs;

    if (search != null) {
      final searchedProductsSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .where('productName', isGreaterThanOrEqualTo: search)
          .get();

      searchedProductDocs = searchedProductsSnap.docs;
      searchedProductDocs.shuffle();

      productDocs.addAll(searchedProductDocs);
    }

    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        filteredProductDocs = [];

    productDocs.forEach((productData) {
      if (productData['productName'] == productName) {
        return;
      }

      final List<String> productNameWords =
          productName.toLowerCase().split(' ');
      final String similarProductName =
          productData['productName'].toString().toLowerCase();
      final bool productNameMatch = productNameWords.any((word) =>
          similarProductName.contains(' $word ') ||
          similarProductName.contains('$word ') ||
          similarProductName.contains(' $word'));

      if (productNameMatch) {
        filteredProductDocs.add(productData);
      }
    });

    filteredProductDocs.shuffle();

    filteredProductDocs.forEach((productData) {
      final Map<String, dynamic> productDatas = productData.data();
      similarProductsDatas.add(productDatas);
    });

    setState(() {
      similarProductsAdded = true;
    });
  }

  // CHECK IF REVIEWED
  Future<void> checkIfReviewed() async {
    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.productData['productId'])
        .get();

    final productData = productSnap.data()!;

    final Map<String, dynamic> reviews =
        Map<String, dynamic>.from(productData['ratings']);

    if (reviews.containsKey(auth.currentUser!.uid)) {
      setState(() {
        previousRating = reviews[auth.currentUser!.uid][0].toDouble();
        previousReview = reviews[auth.currentUser!.uid][1];
        userRating = reviews[auth.currentUser!.uid][0].toDouble();
        hasReviewedBefore = true;
      });

      reviewController.clear();
    } else {
      setState(() {
        hasReviewedBefore = false;
      });
    }
  }

  // ADD REVIEW
  Future<void> addReview({String? newReview}) async {
    if (userRating == 0) {
      return mySnackBar('Pls select a rating', context);
    }

    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.productData['productId'])
        .get();

    final productData = productSnap.data()!;

    Map<String, dynamic> reviews =
        Map<String, dynamic>.from(productData['ratings']);

    if (newReview != null) {
      reviews[auth.currentUser!.uid] = [userRating, newReview.trim()];
    } else {
      reviews[auth.currentUser!.uid] = [userRating, reviewController.text];
    }

    await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.productData['productId'])
        .update({'ratings': reviews});

    searchController.clear();

    setState(() {
      reviewAdded = true;
    });

    await checkIfReviewed();
  }

  // DELETE REVIEW
  Future<void> deleteReview() async {
    try {
      final productSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(widget.productData['productId'])
          .get();

      final productData = productSnap.data()!;

      final Map<String, dynamic> reviews = productData['ratings'];

      reviews.remove(auth.currentUser!.uid);

      await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(widget.productData['productId'])
          .update({
        'ratings': reviews,
      });

      setState(() {
        previousRating = 0;
        userRating = 0;
      });

      await checkIfReviewed();
    } catch (e) {
      mySnackBar(e.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.productData;
    final String id = data['productId'];
    final String name = data['productName'];
    final String price = data['productPrice'];
    final String description = data['productDescription'];
    final String brand = data['productBrand'];
    final List images = data['images'];
    // final String categoryId = data['categoryId'];
    final String categoryName = data['categoryName'];
    final Map<String, dynamic> ratings = data['ratings'];

    final Map<String, dynamic> properties = data['Properties'];
    final String propertyName0 = properties['propertyName0'];
    final String propertyName1 = properties['propertyName1'];
    final String propertyName2 = properties['propertyName2'];
    final String propertyName3 = properties['propertyName3'];
    final String propertyName4 = properties['propertyName4'];
    final String propertyName5 = properties['propertyName5'];

    final List propertyValue0 = properties['propertyValue0'];
    final List propertyValue1 = properties['propertyValue1'];
    final List propertyValue2 = properties['propertyValue2'];
    final List propertyValue3 = properties['propertyValue3'];
    final List propertyValue4 = properties['propertyValue4'];
    final List propertyValue5 = properties['propertyValue5'];

    // final int propertyNoOfAnswers0 = properties['propertyNoOfAnswers0'];
    // final int propertyNoOfAnswers1 = properties['propertyNoOfAnswers1'];
    // final int propertyNoOfAnswers2 = properties['propertyNoOfAnswers2'];
    // final int propertyNoOfAnswers3 = properties['propertyNoOfAnswers3'];
    // final int propertyNoOfAnswers4 = properties['propertyNoOfAnswers4'];
    // final int propertyNoOfAnswers5 = properties['propertyNoOfAnswers5'];

    final discountPriceFuture = store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .where('vendorId', isEqualTo: widget.productData['vendorId'])
        .get();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              double width = constraints.maxWidth;

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: width * 0.0225,
                    horizontal: width * 0.003125,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEARCH BAR
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: width * 0.0125,
                        ),
                        child: Container(
                          color: primary2,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: width * 0.1,
                                  height: width * 0.2,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Icon(
                                    FeatherIcons.arrowLeft,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: width * 0.025,
                                  bottom: width * 0.0225,
                                  right: width * 0.0125,
                                ),
                                child: Container(
                                  width: width * 0.875,
                                  height: width * 0.1875,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    border: Border.all(
                                      color: primaryDark.withOpacity(0.75),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: width * 0.566,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              // top: width * 0.135,
                                              ),
                                          child: TextFormField(
                                            autofillHints: const [],
                                            autofocus: false,
                                            minLines: 1,
                                            maxLines: 1,
                                            controller: searchController,
                                            keyboardType: TextInputType.text,
                                            textInputAction:
                                                TextInputAction.search,
                                            decoration: const InputDecoration(
                                              hintText: 'Search',
                                              hintStyle: TextStyle(
                                                textBaseline:
                                                    TextBaseline.alphabetic,
                                              ),
                                              border: OutlineInputBorder(
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTapDown: (details) {
                                              setState(() {
                                                isMicPressed = true;
                                              });
                                            },
                                            onTapUp: (details) {
                                              setState(() {
                                                isMicPressed = false;
                                              });
                                            },
                                            onTapCancel: () {
                                              setState(() {
                                                isMicPressed = false;
                                              });
                                            },
                                            onTap: () async {
                                              await listen();
                                            },
                                            customBorder:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Container(
                                              width: width * 0.15,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isMicPressed
                                                    ? primary2.withOpacity(0.95)
                                                    : primary2
                                                        .withOpacity(0.25),
                                              ),
                                              child: Icon(
                                                FeatherIcons.mic,
                                                size: width * 0.066,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTapDown: (details) {
                                              setState(() {
                                                isSearchPressed = true;
                                              });
                                            },
                                            onTapUp: (details) {
                                              setState(() {
                                                isSearchPressed = false;
                                              });
                                            },
                                            onTapCancel: () {
                                              setState(() {
                                                isSearchPressed = false;
                                              });
                                            },
                                            onTap: () async {
                                              await search();
                                            },
                                            customBorder:
                                                RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(0),
                                                bottomLeft: Radius.circular(0),
                                                bottomRight:
                                                    Radius.circular(12),
                                                topRight: Radius.circular(12),
                                              ),
                                            ),
                                            child: Container(
                                              width: width * 0.15,
                                              decoration: BoxDecoration(
                                                color: isSearchPressed
                                                    ? primary2.withOpacity(0.95)
                                                    : primary2
                                                        .withOpacity(0.25),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(0),
                                                  bottomLeft:
                                                      Radius.circular(0),
                                                  bottomRight:
                                                      Radius.circular(12),
                                                  topRight: Radius.circular(12),
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                FeatherIcons.search,
                                                size: width * 0.066,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // VENDOR
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.0125,
                          vertical: width * 0.00625,
                        ),
                        child: GestureDetector(
                          onTap: () {},
                          onLongPress: () {
                            setState(() {
                              isVendorHold = true;
                            });
                          },
                          onLongPressCancel: () {
                            setState(() {
                              isVendorHold = false;
                            });
                          },
                          onTapDown: (details) {
                            setState(() {
                              isVendorHold = true;
                            });
                          },
                          onTapUp: (details) {
                            setState(() {
                              isVendorHold = false;
                            });
                          },
                          onTapCancel: () {
                            setState(() {
                              isVendorHold = false;
                            });
                          },
                          child: Text(
                            'Visit the $vendorName store',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 114, 196),
                              fontSize: width * 0.045,
                              decoration: isVendorHold
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      // NAME
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.0125,
                          vertical: width * 0.00625,
                        ),
                        child: Text(
                          name,
                          style: TextStyle(
                            color: primaryDark,
                            fontSize: width * 0.045,
                          ),
                        ),
                      ),

                      // IMAGES
                      Padding(
                        padding: EdgeInsets.only(top: width * 0.05),
                        child: CarouselSlider(
                          items: (images)
                              .map(
                                (e) => Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) => ImageView(
                                                  imagesUrl: images,
                                                )),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        // width: width * 1.5,
                                        // height: width * 1.5,
                                        // decoration: BoxDecoration(
                                        //   border: Border.all(
                                        //     color: primaryDark2,
                                        //     width: 0.25,
                                        //   ),
                                        //   borderRadius: BorderRadius.circular(12),
                                        // ),
                                        child: Image.network(
                                          e,
                                        ),
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.share_outlined,
                                      ),
                                      tooltip: "Share",
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                          options: CarouselOptions(
                            enableInfiniteScroll:
                                images.length > 1 ? true : false,
                            viewportFraction: 1,
                            aspectRatio: 0.7875,
                            enlargeCenterPage: false,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                          ),
                        ),
                      ),

                      // DOTS
                      images.length == 0
                          ? SizedBox(height: 36)
                          : Padding(
                              padding: EdgeInsets.only(
                                top: 12,
                                bottom: 24,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: (images).map((e) {
                                  int index = images.indexOf(e);

                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentIndex == index
                                          ? primaryDark
                                          : primary2,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                      // PRICE & WISHLIST
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          isDiscount != null && isDiscount!
                              ? FutureBuilder(
                                  future: discountPriceFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return const Center(
                                        child: Text(
                                          'Something went wrong',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }

                                    if (snapshot.hasData) {
                                      final priceSnap = snapshot.data!;
                                      Map<String, dynamic> data = {};
                                      for (QueryDocumentSnapshot<
                                              Map<String, dynamic>> doc
                                          in priceSnap.docs) {
                                        data = doc.data();
                                      }

                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.0225,
                                            ),
                                            child: price == "" || price == 'N/A'
                                                ? const Text(
                                                    'N/A',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  )
                                                : RichText(
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    text: TextSpan(
                                                      text: 'Rs. ',
                                                      style: const TextStyle(
                                                        color: primaryDark,
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: data[
                                                                  'isPercent']
                                                              ? '${double.parse(price) * (100 - (data['discountAmount'])) / 100}  '
                                                              : '${double.parse(price) - (data['discountAmount'])}  ',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: price,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 20,
                                                            color:
                                                                Color.fromRGBO(
                                                              255,
                                                              134,
                                                              125,
                                                              1,
                                                            ),
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                  ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: width * 0.0266,
                                            ),
                                            child: data['isPercent']
                                                ? Text(
                                                    "${data['discountAmount']}% off",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  )
                                                : Text(
                                                    "Save Rs. ${data['discountAmount']}",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.0275,
                                              vertical: width * 0.0055,
                                            ),
                                            child: Text(
                                              (data['discountEndDateTime']
                                                              as Timestamp)
                                                          .toDate()
                                                          .difference(
                                                              DateTime.now())
                                                          .inHours <
                                                      24
                                                  ? '''${(data['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours} Hours Left'''
                                                  : '''${(data['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inDays} Days Left''',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  })
                              : Padding(
                                  padding: EdgeInsets.only(
                                    left: width * 0.02775,
                                  ),
                                  child: Text(
                                    widget.productData['productPrice'] == ""
                                        ? "N/A"
                                        : "Rs. ${widget.productData['productPrice']}",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: width * 0.06125,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                          // WISHLIST
                          IconButton(
                            onPressed: () async {
                              await wishlistProduct(id);
                            },
                            icon: Icon(
                              isWishListed
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                              size: width * 0.1,
                            ),
                            splashColor: Colors.red,
                            tooltip: "Wishlist",
                          ),
                        ],
                      ),

                      // DESCRIPTION
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.0175,
                          horizontal: MediaQuery.of(context).size.width * 0.02,
                        ),
                        child: Container(
                          width: width,
                          padding: EdgeInsets.all(width * 0.0225),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.33,
                              color: black,
                            ),
                          ),
                          child: SeeMoreText(
                            description,
                            textStyle: TextStyle(
                              color: primaryDark,
                            ),
                            seeMoreStyle: TextStyle(
                              color: Colors.blue,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.0425,
                            ),
                          ),
                        ),
                      ),

                      // BRAND & CATEGORY
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.0175,
                          horizontal: MediaQuery.of(context).size.width * 0.02,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.0125,
                          ),
                          decoration: BoxDecoration(
                            color: primary2.withOpacity(0.0125),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  brandImageUrl == null
                                      ? Container()
                                      : CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(brandImageUrl!),
                                          backgroundColor: lightGrey,
                                        ),
                                  SizedBox(width: width * 0.0225),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        overflow: TextOverflow.ellipsis,
                                        'Brand',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: primaryDark2,
                                        ),
                                      ),
                                      Text(
                                        brand,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05833,
                                          fontWeight: FontWeight.w600,
                                          color: primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  categoryImageUrl == null
                                      ? Container()
                                      : CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(categoryImageUrl!),
                                          backgroundColor: lightGrey,
                                        ),
                                  SizedBox(width: width * 0.0225),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        overflow: TextOverflow.ellipsis,
                                        'Category',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: primaryDark2,
                                        ),
                                      ),
                                      Text(
                                        categoryName,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05833,
                                          fontWeight: FontWeight.w600,
                                          color: primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // PROPERTIES
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.05,
                            vertical: width * 0.025,
                          ),
                          margin: EdgeInsets.symmetric(
                            // horizontal: width * 0.025,
                            vertical: width * 0.025,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.25,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.0225,
                                  vertical: width * 0.0125,
                                ),
                                child: Text(
                                  'Properties',
                                  style: TextStyle(
                                    fontSize: width * 0.05,
                                  ),
                                ),
                              ),
                              DataTable(
                                columns: [
                                  DataColumn(
                                    label: Text('Property'),
                                  ),
                                  DataColumn(
                                    label: Text('Value'),
                                  ),
                                ],
                                rows: [
                                  if (propertyName0 != '' &&
                                      propertyValue0.length == 1)
                                    DataRow(
                                      cells: [
                                        DataCell(
                                          Text(propertyName0),
                                        ),
                                        DataCell(
                                          Text(propertyValue0[0]),
                                        ),
                                      ],
                                    ),
                                  if (propertyName1 != '' &&
                                      propertyValue1.length == 1)
                                    DataRow(
                                      cells: [
                                        DataCell(
                                          Text(propertyName1),
                                        ),
                                        DataCell(
                                          Text(propertyValue1[0]),
                                        ),
                                      ],
                                    ),
                                  if (propertyName2 != '' &&
                                      propertyValue2.length == 1)
                                    DataRow(
                                      cells: [
                                        DataCell(
                                          Text(propertyName2),
                                        ),
                                        DataCell(
                                          Text(propertyValue2[0]),
                                        ),
                                      ],
                                    ),
                                  if (propertyName3 != '' &&
                                      propertyValue3.length == 1)
                                    DataRow(
                                      cells: [
                                        DataCell(
                                          Text(propertyName3),
                                        ),
                                        DataCell(
                                          Text(propertyValue3[0]),
                                        ),
                                      ],
                                    ),
                                  if (propertyName4 != '' &&
                                      propertyValue4.length == 1)
                                    DataRow(
                                      cells: [
                                        DataCell(
                                          Text(propertyName4),
                                        ),
                                        DataCell(
                                          Text(propertyValue4[0]),
                                        ),
                                      ],
                                    ),
                                  if (propertyName5 != '' &&
                                      propertyValue5.length == 1)
                                    DataRow(
                                      cells: [
                                        DataCell(
                                          Text(propertyName5),
                                        ),
                                        DataCell(
                                          Text(propertyValue5[0]),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // PROPERTY 0
                      // propertyValue0.isEmpty
                      //     ? Container()
                      //     : InfoBox(
                      //         head: propertyName0,
                      //         noOfAnswers: propertyNoOfAnswers0,
                      //         width: width,
                      //         content: propertyValue0.length == 1
                      //             ? propertyValue0[0]
                      //             : null,
                      //         propertyValue: propertyValue0.length > 1
                      //             ? propertyValue0
                      //                 .map(
                      //                   (e) => Container(
                      //                     height: 40,
                      //                     margin: EdgeInsets.only(
                      //                       right: 4,
                      //                       top: 4,
                      //                       bottom: 4,
                      //                     ),
                      //                     padding: EdgeInsets.symmetric(
                      //                       horizontal: 6,
                      //                       vertical: 4,
                      //                     ),
                      //                     alignment: Alignment.center,
                      //                     decoration: BoxDecoration(
                      //                       color: primaryDark.withOpacity(0.8),
                      //                       borderRadius:
                      //                           BorderRadius.circular(4),
                      //                     ),
                      //                     child: Text(
                      //                       e,
                      //                       style: TextStyle(
                      //                         fontSize: 18,
                      //                         color: primaryDark2,
                      //                         fontWeight: FontWeight.w500,
                      //                       ),
                      //                     ),
                      //                   ),
                      //                 )
                      //                 .toList()
                      //             : List.empty(),
                      //       ),

                      // SIMILAR PRODUCTS
                      Container(
                        width: width,
                        height: width * 0.6,
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
                        margin: EdgeInsets.symmetric(
                          horizontal: width * 0.00125,
                          vertical: width * 0.0125,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: width * 0.025,
                                right: width * 0.025,
                                top: width * 0.0166,
                              ),
                              child: Text(
                                'Similar Products',
                              ),
                            ),
                            SizedBox(
                              width: width,
                              height: width * 0.5,
                              child: ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemCount: similarProductsDatas.length,
                                itemBuilder: ((context, index) {
                                  final data = similarProductsDatas[index];
                                  final String name =
                                      similarProductsDatas[index]
                                          ['productName'];
                                  final String price =
                                      similarProductsDatas[index]
                                          ['productPrice'];
                                  final String image =
                                      similarProductsDatas[index]['images'][0];

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      left: width * 0.025,
                                      right: width * 0.025,
                                      top: width * 0.01,
                                      bottom: width * 0.015,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) => ProductPage(
                                                  productData: data,
                                                )),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: width * 0.3,
                                        height: width * 0.2,
                                        decoration: BoxDecoration(
                                          color: primary2,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.025,
                                            vertical: width * 0.0125,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  image,
                                                  fit: BoxFit.cover,
                                                  width: width * 0.25,
                                                  height: width * 0.3,
                                                ),
                                              ),
                                              Text(
                                                name,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: width * 0.05,
                                                ),
                                              ),
                                              Text(
                                                'Rs. $price',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: width * 0.045,
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
                          ],
                        ),
                      ),

                      // RATINGS
                      Container(
                        width: width,
                        height: ratings.isEmpty ? 50 : 400,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 0.5,
                            color: darkGrey,
                          ),
                        ),
                        padding: EdgeInsets.only(
                          left: width * 0.0225,
                          right: width * 0.0225,
                          top: width * 0.0125,
                          bottom: ratings == '0' ? 0 : width * 0.0125,
                        ),
                        margin: EdgeInsets.symmetric(
                          horizontal: width * 0.0125,
                          vertical: width * 0.0125,
                        ),
                        child: ratings.isEmpty
                            ? Center(
                                child: Text(
                                  'No Ratings yet',
                                  style: TextStyle(
                                    fontSize: width * 0.05,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ((ratings.values
                                                .map((e) => e?[0] ?? 0)
                                                .toList()
                                                .reduce((a, b) => a + b) /
                                            (ratings.values.length == 0
                                                ? 1
                                                : ratings.values.length)))
                                        .toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: width * 0.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      // ADD RATING
                      AddReview(),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget AddReview() {
    final width = MediaQuery.of(context).size.width;

    return hasReviewedBefore == null
        ? Container()
        : hasReviewedBefore!
            ? Container(
                width: width,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 0.5,
                    color: darkGrey,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.0225, vertical: width * 0.0125),
                margin: EdgeInsets.symmetric(
                    horizontal: width * 0.0125, vertical: width * 0.0125),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: width * 0.025,
                          right: width * 0.025,
                          top: width * 0.0166),
                      child: Text(
                        'Your previous Review',
                        textAlign: TextAlign.left,
                      ),
                    ),
                    // RATING STARS
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: userRating == 0 ? 10 : 20, top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          RatingBar(
                            maxRating: 5,
                            updateOnDrag: true,
                            initialRating: previousRating!,
                            glowColor: Colors.yellow,
                            glowRadius: 0.5,
                            ratingWidget: RatingWidget(
                              full: Icon(
                                Icons.star,
                                color: Colors.yellow,
                              ),
                              half: Icon(
                                Icons.star_half,
                                color: Colors.yellow,
                              ),
                              empty: Icon(
                                Icons.star_border,
                                color: darkGrey,
                              ),
                            ),
                            onRatingUpdate: (currentRating) {
                              setState(() {
                                userRating = currentRating;
                              });
                            },
                          ),
                          Text(
                            userRating.toStringAsFixed(0) != '0'
                                ? userRating.toStringAsFixed(0)
                                : '---',
                            style: TextStyle(
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // REVIEW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 10,
                            bottom: 20,
                          ),
                          child: Text(
                            previousReview!,
                            maxLines: 10,
                          ),
                        ),

                        // DELETE
                        IconButton(
                          onPressed: () async {
                            await deleteReview();
                          },
                          icon: Icon(
                            FeatherIcons.trash,
                            color: Colors.red,
                          ),
                          tooltip: 'DELETE',
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Container(
                width: width,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 0.5,
                    color: darkGrey,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: width * 0.0225, vertical: width * 0.0125),
                margin: EdgeInsets.symmetric(
                    horizontal: width * 0.0125, vertical: width * 0.0125),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: width * 0.025,
                          right: width * 0.025,
                          top: width * 0.0166),
                      child: Text(
                        'Add Product Review',
                        textAlign: TextAlign.left,
                      ),
                    ),
                    // RATING STARS
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: userRating == 0 ? 10 : 20,
                        top: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          RatingBar(
                            maxRating: 5,
                            initialRating: previousRating ?? 0,
                            updateOnDrag: true,
                            glowColor: Colors.yellow,
                            glowRadius: 0.5,
                            ratingWidget: RatingWidget(
                              full: Icon(
                                Icons.star,
                                color: Colors.yellow,
                              ),
                              half: Icon(
                                Icons.star_half,
                                color: Colors.yellow,
                              ),
                              empty: Icon(
                                Icons.star_border,
                                color: darkGrey,
                              ),
                            ),
                            onRatingUpdate: (currentRating) {
                              setState(() {
                                userRating = currentRating;
                              });
                            },
                          ),
                          Text(
                            userRating.toStringAsFixed(0) != '0'
                                ? userRating.toStringAsFixed(0)
                                : '---',
                            style: TextStyle(
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // REVIEW
                    userRating == 0
                        ? Container()
                        : Padding(
                            padding: EdgeInsets.only(
                              left: 10,
                              right: 10,
                              top: 10,
                              bottom: 20,
                            ),
                            child: TextField(
                              autofocus: false,
                              controller: reviewController,
                              textInputAction: TextInputAction.newline,
                              maxLength: 500,
                              minLines: 1,
                              maxLines: 10,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.cyan.shade700,
                                  ),
                                ),
                                hintText: 'Review',
                              ),
                            ),
                          ),

                    // DONE
                    MyTextButton(
                      onPressed: userRating == 0
                          ? () {}
                          : () async {
                              await addReview();
                            },
                      text: 'DONE',
                      textColor: primaryDark,
                    ),
                  ],
                ),
              );
  }
}
