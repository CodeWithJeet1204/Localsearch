import 'dart:async';
import 'package:Localsearch_User/models/household_sub_category.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:Localsearch_User/page/main/vendor/category/category_products_page.dart';
import 'package:Localsearch_User/page/main/vendor/product/product_all_reviews_page.dart';
import 'package:Localsearch_User/page/main/vendor/vendor_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/image_view.dart';
import 'package:Localsearch_User/widgets/info_box.dart';
import 'package:Localsearch_User/widgets/ratings_bar.dart';
import 'package:Localsearch_User/widgets/review_container.dart';
import 'package:Localsearch_User/widgets/search_bar.dart';
import 'package:Localsearch_User/widgets/see_more_text.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:Localsearch_User/widgets/text_button.dart';
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
  List? vendorType;
  bool isVendorHold = false;
  bool? isDiscount;
  bool isLiked = false;
  String? brandImageUrl;
  String? categoryImageUrl;
  List? allDiscount;
  double userRating = 0.0;
  bool? hasReviewedBefore;
  double? previousRating;
  String? previousReview;
  String? newReview;
  Map likesTimestamp = {};
  bool reviewAdded = false;
  Map<String, int>? allRatings;
  Map<String, dynamic>? allReviews;
  List<Map<String, dynamic>> similarProductsDatas = [];
  bool similarProductsAdded = false;
  List<Map<String, dynamic>> otherVendorProductsDatas = [];
  bool otherVendorProductsAdded = false;
  double? distance;
  Map<String, dynamic> discountData = {};

  // INIT STATE
  @override
  void initState() {
    getVendorInfo();
    getIfDiscount();
    getDiscountAmount();
    getIfWishlist(widget.productData['productId']);
    getIfLiked();
    getBrandImage();
    getAllDiscounts();
    getAverageRatings();
    checkIfReviewed();
    getAllReviews();
    getSimilarProducts(
      widget.productData['productName'],
      search: widget.search,
    );
    getProductsFromVendor();
    super.initState();
    addProductView();
  }

  // ADD PRODUCT VIEW
  Future<void> addProductView() async {
    Timer(const Duration(seconds: 5), () async {
      final productSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(widget.productData['productId'])
          .get();

      final productData = productSnap.data()!;

      int views = productData['productViews'] ?? 0;
      List viewsTimestamps = productData['productViewsTimestamp'];
      views = views + 1;
      viewsTimestamps.add(DateTime.now());

      await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(widget.productData['productId'])
          .update({
        'productViews': views,
        'productViewsTimestamp': viewsTimestamps,
      });

      final userSnap =
          await store.collection('Users').doc(auth.currentUser!.uid).get();

      final userData = userSnap.data()!;

      List recentProducts = userData['recentProducts'];

      final productId = widget.productData['productId'];

      recentProducts.remove(productId);

      recentProducts.insert(0, productId);

      if (recentProducts.length > 4) {
        recentProducts.removeRange(4, recentProducts.length);
      }

      await store.collection('Users').doc(auth.currentUser!.uid).update({
        'recentProducts': recentProducts,
      });
    });
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
      vendorType = vendorData['Type'];
    });

    await getCategoryImage(vendorData['Type']);
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
              .contains(widget.productData['categoryName'])) {
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

  // GET ALL DISCOUNTS
  Future<void> getAllDiscounts() async {
    final discountSnapshot = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .where('vendorId', isEqualTo: widget.productData['vendorId'])
        .get();

    List<Map<String, dynamic>> allDiscounts = [];

    for (QueryDocumentSnapshot<Map<String, dynamic>> doc
        in discountSnapshot.docs) {
      final data = doc.data();

      if ((data['discountEndDateTime'] as Timestamp)
              .toDate()
              .isAfter(DateTime.now()) &&
          !(data['discountStartDateTime'] as Timestamp)
              .toDate()
              .isAfter(DateTime.now())) {
        allDiscounts.add(data);
      }
    }

    setState(() {
      allDiscount = allDiscounts;
    });
  }

  // GET IF LIKED
  Future<void> getIfLiked() async {
    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.productData['productId'])
        .get();

    final productData = productSnap.data()!;

    Map<String, dynamic> productLikesTimestamp =
        productData['productLikesTimestamp'];

    setState(() {
      likesTimestamp = productLikesTimestamp;
    });

    setState(() {
      if (productLikesTimestamp.keys.contains(auth.currentUser!.uid)) {
        isLiked = true;
      } else {
        isLiked = false;
      }
    });
  }

  // LIKE PRODUCT
  Future<void> likeProduct() async {
    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.productData['productId'])
        .get();

    final productData = productSnap.data()!;

    Map<String, dynamic> productLikesTimestamp =
        productData['productLikesTimestamp'];

    if (productLikesTimestamp.keys.contains(auth.currentUser!.uid)) {
      productLikesTimestamp.remove(auth.currentUser!.uid);
    } else {
      productLikesTimestamp.addAll({
        auth.currentUser!.uid: Timestamp.fromDate(DateTime.now()),
      });
    }

    await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.productData['productId'])
        .update({
      'productLikesTimestamp': productLikesTimestamp,
    });

    await getIfLiked();
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
  Future<void> getCategoryImage(List vendorType) async {
    for (var type in vendorType) {
      if (householdSubCategories[type]!
          .containsKey(widget.productData['categoryName'])) {
        final categorySnap = await store
            .collection('Business')
            .doc('Special Categories')
            .collection(type)
            .doc(widget.productData['categoryName'])
            .get();

        if (categorySnap.exists) {
          final categoryData = categorySnap.data()!;

          final categoryImage = categoryData['specialCategoryImageUrl'];

          setState(() {
            categoryImageUrl = categoryImage;
          });
        }
      }
    }
  }

  // GET PRODUCTS FROM VENDOR
  Future<void> getProductsFromVendor() async {
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('vendorId', isEqualTo: widget.productData['vendorId'])
        .get();

    for (var productSnap in productsSnap.docs) {
      final productData = productSnap.data();

      if (productData['productName'] == widget.productData['productName']) {
        continue;
      }

      otherVendorProductsDatas.add(productData);
    }

    setState(() {
      otherVendorProductsAdded = true;
    });
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

    for (var productData in productDocs) {
      if (productData['productName'] == productName) {
        continue;
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
    }

    filteredProductDocs.shuffle();

    for (var productData in filteredProductDocs) {
      final Map<String, dynamic> productDatas = productData.data();
      similarProductsDatas.add(productDatas);
    }

    setState(() {
      similarProductsAdded = true;
    });
  }

  // GET AVERAGE RATINGS
  Future<void> getAverageRatings() async {
    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.productData['productId'])
        .get();

    final productData = productSnap.data()!;

    final Map<String, dynamic> ratings = productData['ratings'];

    Map<int, int> ratingCountMap = {
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };

    for (var ratingData in ratings.values) {
      int rating = (ratingData[0] is int)
          ? ratingData[0]
          : (ratingData[0] as double).toInt();
      ratingCountMap.update(rating, (countAbc) => countAbc + 1);
    }

    Map<String, int> ratingMap = {
      '5': ratingCountMap[5]!,
      '4': ratingCountMap[4]!,
      '3': ratingCountMap[3]!,
      '2': ratingCountMap[2]!,
      '1': ratingCountMap[1]!,
    };

    setState(() {
      allRatings = ratingMap;
    });
  }

  // GET ALL REVIEWS
  Future<void> getAllReviews() async {
    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(widget.productData['productId'])
        .get();

    final productData = productSnap.data()!;

    final Map<String, dynamic> ratings = productData['ratings'];

    Map<String, dynamic> allUserReviews = {};

    for (String uid in ratings.keys) {
      final userDoc = await store.collection('Users').doc(uid).get();
      final userData = userDoc.data()!;
      final userName = userData['Name'];
      final rating = ratings[uid][0];
      final review = ratings[uid][1];
      allUserReviews[userName] = [rating, review];
    }

    allUserReviews.removeWhere((key, value) => value[1].isEmpty);

    setState(() {
      allReviews = allUserReviews;
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

    if (reviews.containsKey(auth.currentUser?.uid)) {
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
      if (mounted) {
        mySnackBar(e.toString(), context);
      }
    }
  }

  // ADD REVIEW WIDGET
  Widget addAReviewWidget() {
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
                  horizontal: width * 0.0225,
                  vertical: width * 0.0125,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: width * 0.0125,
                  vertical: width * 0.0125,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.025,
                        right: width * 0.025,
                        top: width * 0.0166,
                      ),
                      child: const Text(
                        'Your previous Review',
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
                            updateOnDrag: true,
                            initialRating: previousRating!,
                            glowColor: Colors.yellow,
                            glowRadius: 0.5,
                            ratingWidget: RatingWidget(
                              full: const Icon(
                                Icons.star,
                                color: Colors.yellow,
                              ),
                              half: const Icon(
                                Icons.star_half,
                                color: Colors.yellow,
                              ),
                              empty: const Icon(
                                Icons.star_border,
                                color: darkGrey,
                              ),
                            ),
                            ignoreGestures: true,
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
                    previousReview!.trim().isEmpty
                        ? Center(
                            child: // DELETE
                                IconButton(
                              onPressed: () async {
                                await deleteReview();
                              },
                              icon: const Icon(
                                FeatherIcons.trash,
                                color: Colors.red,
                              ),
                              tooltip: 'DELETE',
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                  top: 10,
                                  bottom: 20,
                                ),
                                child: Text(
                                  previousReview!.trim(),
                                  maxLines: 10,
                                ),
                              ),

                              // DELETE
                              IconButton(
                                onPressed: () async {
                                  await deleteReview();
                                },
                                icon: const Icon(
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
                  horizontal: width * 0.0225,
                  vertical: width * 0.0125,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: width * 0.0125,
                  vertical: width * 0.0125,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.025,
                        right: width * 0.025,
                        top: width * 0.0166,
                      ),
                      child: const Text(
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
                              full: const Icon(
                                Icons.star,
                                color: Colors.yellow,
                              ),
                              half: const Icon(
                                Icons.star_half,
                                color: Colors.yellow,
                              ),
                              empty: const Icon(
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
                            padding: const EdgeInsets.only(
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
                              onTapOutside: (event) =>
                                  FocusScope.of(context).unfocus(),
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

  // GET DISCOUNT AMOUNT
  Future<void> getDiscountAmount() async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .get();

    for (var discount in discountSnap.docs) {
      final currentDiscountData = discount.data();

      final vendorId = currentDiscountData['vendorId'];
      final discountId = currentDiscountData['discountId'];
      final Timestamp endDateTime = currentDiscountData['discountEndDateTime'];

      if (vendorId == widget.productData['vendorId'] &&
          endDateTime.toDate().isAfter(DateTime.now()) &&
          discountId == widget.productData['discountId']) {
        discountData = currentDiscountData;
      }
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

    final int propertyNoOfAnswers0 = properties['propertyNoOfAnswers0'];
    final int propertyNoOfAnswers1 = properties['propertyNoOfAnswers1'];
    final int propertyNoOfAnswers2 = properties['propertyNoOfAnswers2'];
    final int propertyNoOfAnswers3 = properties['propertyNoOfAnswers3'];
    final int propertyNoOfAnswers4 = properties['propertyNoOfAnswers4'];
    final int propertyNoOfAnswers5 = properties['propertyNoOfAnswers5'];

    final String shortsThumbnail = data['shortsThumbnail'];

    final String shortsURL = data['shortsURL'];

    if (shortsThumbnail != '') {
      if (!images.contains(shortsThumbnail)) {
        images.insert(0, shortsThumbnail);
      }
    }

    final bool isAvailable = data['isAvailable'];

    final bool bulkSellAvailable = data['bulkSellAvailable'];
    final bool cardOffersAvailable = data['cardOffersAvailable'];
    final bool codAvailable = data['codAvailable'];
    final bool deliveryAvailable = data['deliveryAvailable'];
    final double? deliveryRange =
        double.tryParse((data['deliveryRange']).toString());
    final bool giftWrapAvailable = data['giftWrapAvailable'];
    final bool gstInvoiceAvailable = data['gstInvoiceAvailable'];
    final bool refundAvailable = data['refundAvailable'];
    final int? refundRange = data['refundRange'];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.00625,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              double width = constraints.maxWidth;

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: width * 0.0225,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEARCH BAR
                      MySearchBar(
                        width: width,
                        autoFocus: false,
                      ),

                      // VENDOR
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.0125,
                          vertical: width * 0.00625,
                        ),
                        child: GestureDetector(
                          onTap: () {},
                          onTapDown: (details) {
                            setState(() {
                              isVendorHold = true;
                            });
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: ((context) => VendorPage(
                                      vendorId: data['vendorId'],
                                    )),
                              ),
                            );
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
                              color: const Color.fromARGB(255, 0, 114, 196),
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
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            CarouselSlider(
                              items: (images)
                                  .map(
                                    (e) => Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            images.remove(
                                              shortsThumbnail,
                                            );
                                            images.insert(
                                              0,
                                              shortsURL,
                                            );
                                            Navigator.of(context)
                                                .push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    ImageView(
                                                      imagesUrl: images,
                                                      shortsThumbnail:
                                                          shortsThumbnail,
                                                      shortsURL: shortsURL,
                                                    )),
                                              ),
                                            )
                                                .then((value) {
                                              images.remove(
                                                shortsURL,
                                              );
                                              images.insert(
                                                0,
                                                shortsThumbnail,
                                              );
                                            });
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: Image.network(e),
                                          ),
                                        ),
                                        e != shortsThumbnail
                                            ? const SizedBox(
                                                width: 1,
                                                height: 1,
                                              )
                                            : GestureDetector(
                                                onTap: () {
                                                  images.remove(
                                                    shortsThumbnail,
                                                  );
                                                  images.insert(
                                                    0,
                                                    shortsURL,
                                                  );

                                                  Navigator.of(context)
                                                      .push(
                                                    MaterialPageRoute(
                                                      builder: ((context) =>
                                                          ImageView(
                                                            imagesUrl: images,
                                                            shortsThumbnail:
                                                                shortsThumbnail,
                                                            shortsURL:
                                                                shortsURL,
                                                          )),
                                                    ),
                                                  )
                                                      .then((value) {
                                                    images.remove(
                                                      shortsURL,
                                                    );
                                                    images.insert(
                                                      0,
                                                      shortsThumbnail,
                                                    );
                                                  });
                                                },
                                                child: Container(
                                                  width: width * 0.2,
                                                  height: width * 0.2,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        white.withOpacity(0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100),
                                                  ),
                                                  child: Icon(
                                                    Icons.play_arrow_rounded,
                                                    color: white,
                                                    size: width * 0.2,
                                                  ),
                                                ),
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

                            // SHARE
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // DISCOUNT OFF
                                discountData.isEmpty
                                    ? Container()
                                    : Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                        ),
                                        padding: EdgeInsets.all(
                                          width * 0.00625,
                                        ),
                                        margin: EdgeInsets.only(
                                          left: width * 0.0125,
                                        ),
                                        child: discountData['isPercent']
                                            ? Text(
                                                '${discountData['discountAmount']}% off',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: width * 0.05,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            : Text(
                                                'Save Rs. ${discountData['discountAmount']}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: width * 0.05,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                      ),

                                IconButton.filledTonal(
                                  onPressed: () async {},
                                  icon: const Icon(
                                    Icons.share_outlined,
                                  ),
                                  tooltip: 'Share',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // DOTS
                      images.length < 2
                          ? const SizedBox(height: 36)
                          : Padding(
                              padding: const EdgeInsets.only(
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
                                    margin: const EdgeInsets.all(4),
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
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0225,
                                      ),
                                      child: price == '' || price == 'N/A'
                                          ? Text(
                                              'N/A',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isAvailable
                                                    ? black
                                                    : darkGrey,
                                              ),
                                            )
                                          : RichText(
                                              overflow: TextOverflow.ellipsis,
                                              text: TextSpan(
                                                text: 'Rs. ',
                                                style: TextStyle(
                                                  color: isAvailable
                                                      ? primaryDark
                                                      : darkGrey,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: discountData[
                                                            'isPercent']
                                                        ? '${double.parse(price) * (100 - (discountData['discountAmount'])) / 100}  '
                                                        : '${double.parse(price) - (discountData['discountAmount'])}  ',
                                                    style: TextStyle(
                                                      color: isAvailable
                                                          ? Colors.green
                                                          : darkGrey,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: price,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: isAvailable
                                                          ? const Color
                                                              .fromRGBO(
                                                              255,
                                                              134,
                                                              125,
                                                              1,
                                                            )
                                                          : darkGrey,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              maxLines: 1,
                                            ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0275,
                                        vertical: width * 0.0055,
                                      ),
                                      child: Text(
                                        (discountData['discountEndDateTime']
                                                        as Timestamp)
                                                    .toDate()
                                                    .difference(DateTime.now())
                                                    .inHours <
                                                24
                                            ? '''${(discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours} Hours Left'''
                                            : '''${(discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inDays} Days Left''',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isAvailable
                                              ? Colors.red
                                              : darkGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Padding(
                                  padding: EdgeInsets.only(
                                    left: width * 0.02775,
                                  ),
                                  child: Text(
                                    widget.productData['productPrice'] == ''
                                        ? 'N/A'
                                        : 'Rs. ${widget.productData['productPrice']}',
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
                            color: Colors.red,
                            tooltip: 'Wishlist',
                          ),
                        ],
                      ),

                      // AVAILABLE
                      isAvailable
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: width * 0.0175,
                                horizontal: width * 0.02,
                              ),
                              child: Text(
                                'OUT OF STOCK',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: width * 0.05,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Container(),

                      // DELIVERY
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          deliveryAvailable
                              ? distance != null
                                  ? deliveryRange != null
                                      ? Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: width * 0.0175,
                                            horizontal: width * 0.02,
                                          ),
                                          child: Text(
                                            distance! < deliveryRange * 0.9
                                                ? 'Delivery Available'
                                                : distance! >
                                                            deliveryRange *
                                                                0.9 &&
                                                        distance! <
                                                            deliveryRange * 1.1
                                                    ? 'Delivery Maybe Available'
                                                    : 'Delivery Not Available',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                      : Container()
                                  : Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: width * 0.0175,
                                    horizontal: width * 0.02,
                                  ),
                                  child: const Text(
                                    'Delivery Not Available',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                          // LIKES
                          isAvailable
                              ? GestureDetector(
                                  onTap: () async {
                                    await likeProduct();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(width * 0.0225),
                                    margin: EdgeInsets.symmetric(
                                      vertical: width * 0.0175,
                                      horizontal: width * 0.02,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLiked
                                          ? const Color.fromRGBO(
                                              228,
                                              228,
                                              228,
                                              1,
                                            )
                                          : white,
                                      border: Border.all(
                                        width: 1,
                                        color: isLiked
                                            ? white
                                            : const Color.fromRGBO(
                                                228, 228, 228, 1),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Text(
                                          likesTimestamp.length.toString(),
                                          style: const TextStyle(),
                                        ),
                                        SizedBox(width: width * 0.0225),
                                        Icon(
                                          isLiked
                                              ? Icons.thumb_up
                                              : Icons.thumb_up_outlined,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
                      ),

                      // DESCRIPTION
                      description.isEmpty
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: width * 0.0175,
                                horizontal: width * 0.02,
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
                                  textStyle: const TextStyle(
                                    color: primaryDark,
                                  ),
                                  seeMoreStyle: TextStyle(
                                    color: Colors.blue,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.0425,
                                  ),
                                ),
                              ),
                            ),

                      // BRAND & CATEGORY
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: width * 0.0175,
                          horizontal: width * 0.02,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(
                            width * 0.0125,
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
                                      const Text(
                                        overflow: TextOverflow.ellipsis,
                                        'Brand',
                                        style: TextStyle(
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
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  if (vendorType == null) {
                                    return mySnackBar(
                                      'Some error occured',
                                      context,
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: ((context) =>
                                            CategoryProductsPage(
                                              categoryName: categoryName,
                                            )),
                                      ),
                                    );
                                  }
                                },
                                child: Row(
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
                                        const Text(
                                          overflow: TextOverflow.ellipsis,
                                          'Category',
                                          style: TextStyle(
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
                              ),
                            ],
                          ),
                        ),
                      ),

                      // PROPERTIES
                      propertyName0 == '' &&
                              propertyName1 == '' &&
                              propertyName2 == '' &&
                              propertyName3 == '' &&
                              propertyName4 == '' &&
                              propertyName5 == ''
                          ? Container()
                          : Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.05,
                                  vertical: width * 0.025,
                                ),
                                margin: EdgeInsets.symmetric(
                                  horizontal: width * 0.0125,
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
                                      columns: const [
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

                      // 2/3 ANSWER PROPERTIES
                      Properties(
                        propertyValue0: propertyValue0,
                        propertyName0: propertyName0,
                        propertyNoOfAnswers0: propertyNoOfAnswers0,
                        width: width,
                        propertyValue1: propertyValue1,
                        propertyName1: propertyName1,
                        propertyNoOfAnswers1: propertyNoOfAnswers1,
                        propertyValue2: propertyValue2,
                        propertyName2: propertyName2,
                        propertyNoOfAnswers2: propertyNoOfAnswers2,
                        propertyValue3: propertyValue3,
                        propertyName3: propertyName3,
                        propertyNoOfAnswers3: propertyNoOfAnswers3,
                        propertyValue4: propertyValue4,
                        propertyName4: propertyName4,
                        propertyNoOfAnswers4: propertyNoOfAnswers4,
                        propertyValue5: propertyValue5,
                        propertyName5: propertyName5,
                        propertyNoOfAnswers5: propertyNoOfAnswers5,
                      ),

                      // SERVICES
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.05,
                            vertical: width * 0.025,
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: width * 0.0125,
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
                                  'Services',
                                  style: TextStyle(
                                    fontSize: width * 0.05,
                                  ),
                                ),
                              ),
                              DataTable(
                                columns: const [
                                  DataColumn(
                                    label: Text('Service'),
                                  ),
                                  DataColumn(
                                    label: Text('Value'),
                                  ),
                                ],
                                rows: [
                                  DataRow(
                                    cells: [
                                      const DataCell(
                                        Text('Delivery Available'),
                                      ),
                                      DataCell(
                                        Text(
                                          deliveryAvailable &&
                                                  deliveryRange != null
                                              ? 'Yes, within ${deliveryRange.toStringAsFixed(1).endsWith('0') ? deliveryRange.toString() : deliveryRange.toStringAsFixed(1)} km'
                                              : 'No',
                                        ),
                                      ),
                                    ],
                                  ),
                                  DataRow(
                                    cells: [
                                      const DataCell(
                                        Text('Refund Available'),
                                      ),
                                      DataCell(
                                        Text(
                                          refundAvailable &&
                                                  refundRange != null &&
                                                  refundRange > 0
                                              ? 'Yes, within ${refundRange.toString()} days'
                                              : refundAvailable &&
                                                      refundRange == null
                                                  ? 'Yes'
                                                  : 'No',
                                        ),
                                      ),
                                    ],
                                  ),
                                  DataRow(
                                    cells: [
                                      const DataCell(
                                        Text('Cash On Delivery'),
                                      ),
                                      DataCell(
                                        Text(
                                          codAvailable ? 'Yes' : 'No',
                                        ),
                                      ),
                                    ],
                                  ),
                                  DataRow(
                                    cells: [
                                      const DataCell(
                                        Text('Card Offers'),
                                      ),
                                      DataCell(
                                        Text(
                                          cardOffersAvailable ? 'Yes' : 'No',
                                        ),
                                      ),
                                    ],
                                  ),
                                  DataRow(
                                    cells: [
                                      const DataCell(
                                        Text('Bulk Sell'),
                                      ),
                                      DataCell(
                                        Text(
                                          bulkSellAvailable ? 'Yes' : 'No',
                                        ),
                                      ),
                                    ],
                                  ),
                                  DataRow(
                                    cells: [
                                      const DataCell(
                                        Text('GST Invoice'),
                                      ),
                                      DataCell(
                                        Text(
                                          gstInvoiceAvailable ? 'Yes' : 'No',
                                        ),
                                      ),
                                    ],
                                  ),
                                  DataRow(
                                    cells: [
                                      const DataCell(
                                        Text('Gift Wrap'),
                                      ),
                                      DataCell(
                                        Text(
                                          giftWrapAvailable ? 'Yes' : 'No',
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

                      // ALL DISCOUNTS
                      allDiscount == null || allDiscount!.isEmpty
                          ? Container()
                          : AllDiscountsWidget(
                              noOfDiscounts: allDiscount!.length,
                              allDiscount: allDiscount!,
                            ),

                      const Divider(
                        color: Color.fromRGBO(219, 219, 219, 1),
                      ),

                      // OTHER VENDOR PRODUCTS
                      otherVendorProductsDatas.isEmpty
                          ? Container()
                          : Container(
                              width: width,
                              height: width * 0.66,
                              decoration: const BoxDecoration(
                                color: white,
                              ),
                              padding: EdgeInsets.only(
                                right: width * 0.02,
                              ),
                              margin: EdgeInsets.symmetric(
                                horizontal: width * 0.00125,
                                vertical: width * 0.0125,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.025,
                                    ),
                                    child: const Text(
                                      'Other Products From This Shop',
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    height: width * 0.5,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount:
                                          otherVendorProductsDatas.length,
                                      itemBuilder: ((context, index) {
                                        final data =
                                            otherVendorProductsDatas[index];
                                        final String name =
                                            otherVendorProductsDatas[index]
                                                ['productName'];
                                        final String price =
                                            otherVendorProductsDatas[index]
                                                ['productPrice'];
                                        final String image =
                                            otherVendorProductsDatas[index]
                                                ['images'][0];

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    ProductPage(
                                                      productData: data,
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
                                            margin: EdgeInsets.only(
                                              left: width * 0.025,
                                              right: width * 0.025,
                                              top: width * 0.01,
                                              bottom: width * 0.015,
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
                                                    image,
                                                    fit: BoxFit.cover,
                                                    width: width * 0.3,
                                                    height: width * 0.3,
                                                  ),
                                                ),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        fontSize: width * 0.05,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Rs. $price',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        fontSize: width * 0.045,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                            ),

                      otherVendorProductsDatas.isEmpty
                          ? Container()
                          : const Divider(),

                      // SIMILAR PRODUCTS
                      similarProductsDatas.isEmpty
                          ? Container()
                          : Container(
                              width: width,
                              height: width * 0.6,
                              decoration: const BoxDecoration(
                                color: white,
                              ),
                              padding: EdgeInsets.only(
                                right: width * 0.02,
                              ),
                              margin: EdgeInsets.symmetric(
                                horizontal: width * 0.00125,
                                vertical: width * 0.0125,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.025,
                                    ),
                                    child: const Text(
                                      'Similar Products',
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    height: width * 0.5,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: similarProductsDatas.length,
                                      itemBuilder: ((context, index) {
                                        final data =
                                            similarProductsDatas[index];
                                        final String name =
                                            similarProductsDatas[index]
                                                ['productName'];
                                        final String price =
                                            similarProductsDatas[index]
                                                ['productPrice'];
                                        final String image =
                                            similarProductsDatas[index]
                                                ['images'][0];

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    ProductPage(
                                                      productData: data,
                                                    )),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: width * 0.3,
                                            height: width * 0.2,
                                            decoration: BoxDecoration(
                                              color: white,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              border: Border.all(
                                                width: 0.25,
                                              ),
                                            ),
                                            padding: EdgeInsets.all(
                                              width * 0.00625,
                                            ),
                                            margin: EdgeInsets.only(
                                              left: width * 0.025,
                                              right: width * 0.025,
                                              top: width * 0.01,
                                              bottom: width * 0.015,
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
                                                    image,
                                                    fit: BoxFit.cover,
                                                    width: width * 0.3,
                                                    height: width * 0.3,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.00625,
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontSize:
                                                              width * 0.05,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Rs. $price',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontSize:
                                                              width * 0.045,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
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
                            ),

                      // RATINGS
                      Container(
                        width: width,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 0.5,
                            color: darkGrey,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.0225,
                          vertical: width * 0.0125,
                        ),
                        margin: EdgeInsets.symmetric(
                          horizontal: width * 0.0125,
                          vertical: width * 0.0125,
                        ),
                        child: ratings.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Text(
                                    'No Ratings yet',
                                    style: TextStyle(
                                      fontSize: width * 0.05,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        ((ratings.values
                                                    .map((e) => e?[0] ?? 0)
                                                    .toList()
                                                    .reduce((a, b) => a + b) /
                                                (ratings.values.isEmpty
                                                    ? 1
                                                    : ratings.values
                                                        .length)) as double)
                                            .toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: width * 0.2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                      // RATINGS BAR
                                      allRatings == null
                                          ? Container()
                                          : RatingsBars(
                                              ratingMap: allRatings!,
                                            ),
                                    ],
                                  ),

                                  // REVIEWS
                                  allReviews == null
                                      ? Container()
                                      : Container(
                                          width: width,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.0125,
                                            vertical: width * 0.0125,
                                          ),
                                          margin: EdgeInsets.symmetric(
                                            vertical: width * 0.0125,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.125),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: allReviews!.length > 3
                                                ? 3
                                                : allReviews!.length,
                                            itemBuilder: ((context, index) {
                                              final name = allReviews!.keys
                                                  .toList()[index];
                                              final rating = allReviews!.values
                                                  .toList()[index][0];
                                              final review = allReviews!.values
                                                  .toList()[index][1];

                                              return ReviewContainer(
                                                name: name,
                                                rating: rating,
                                                review: review,
                                              );
                                            }),
                                          ),
                                        ),

                                  // SEE MORE
                                  allReviews == null
                                      ? Container()
                                      : allReviews!.length <= 3
                                          ? Container()
                                          : Center(
                                              child: MyTextButton(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: ((context) =>
                                                          ProductAllReviewPage(
                                                            reviews:
                                                                allReviews!,
                                                            rating:
                                                                ratings.isEmpty
                                                                    ? Padding(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            vertical:
                                                                                8),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Text(
                                                                            'No Ratings yet',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: width * 0.05,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      )
                                                                    : Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceAround,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            ((ratings.values.map((e) => e?[0] ?? 0).toList().reduce((a, b) => a + b) / (ratings.values.isEmpty ? 1 : ratings.values.length)) as double).toStringAsFixed(1),
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: width * 0.2,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),

                                                                          // RATINGS BAR
                                                                          allRatings == null
                                                                              ? Container()
                                                                              : RatingsBars(
                                                                                  ratingMap: allRatings!,
                                                                                ),
                                                                        ],
                                                                      ),
                                                          )),
                                                    ),
                                                  );
                                                },
                                                text:
                                                    'See All (${allReviews!.length})',
                                                textColor: primaryDark2,
                                              ),
                                            ),
                                ],
                              ),
                      ),

                      // ADD RATING
                      addAReviewWidget(),
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
}

// PROPERTIES
class Properties extends StatelessWidget {
  const Properties({
    super.key,
    required this.propertyValue0,
    required this.propertyName0,
    required this.propertyNoOfAnswers0,
    required this.width,
    required this.propertyValue1,
    required this.propertyName1,
    required this.propertyNoOfAnswers1,
    required this.propertyValue2,
    required this.propertyName2,
    required this.propertyNoOfAnswers2,
    required this.propertyValue3,
    required this.propertyName3,
    required this.propertyNoOfAnswers3,
    required this.propertyValue4,
    required this.propertyName4,
    required this.propertyNoOfAnswers4,
    required this.propertyValue5,
    required this.propertyName5,
    required this.propertyNoOfAnswers5,
  });

  final List propertyValue0;
  final String propertyName0;
  final int propertyNoOfAnswers0;
  final double width;
  final List propertyValue1;
  final String propertyName1;
  final int propertyNoOfAnswers1;
  final List propertyValue2;
  final String propertyName2;
  final int propertyNoOfAnswers2;
  final List propertyValue3;
  final String propertyName3;
  final int propertyNoOfAnswers3;
  final List propertyValue4;
  final String propertyName4;
  final int propertyNoOfAnswers4;
  final List propertyValue5;
  final String propertyName5;
  final int propertyNoOfAnswers5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        propertyValue0.isEmpty ||
                propertyName0 == '' ||
                propertyNoOfAnswers0 != 3
            ? Container()
            : InfoBox(
                head: propertyName0,
                content: propertyValue0[0],
                noOfAnswers: propertyNoOfAnswers0,
                propertyValue: propertyValue0,
                width: width,
              ),

        // PROPERTY 1
        propertyValue1.isEmpty ||
                propertyName1 == '' ||
                propertyNoOfAnswers1 != 3
            ? Container()
            : InfoBox(
                head: propertyName1,
                content: propertyValue1[0],
                noOfAnswers: propertyNoOfAnswers1,
                propertyValue: propertyValue1,
                width: width,
              ),

        // PROPERTY 2
        propertyValue2.isEmpty ||
                propertyName2 == '' ||
                propertyNoOfAnswers2 != 3
            ? Container()
            : InfoBox(
                head: propertyName2,
                content: propertyValue2[0],
                noOfAnswers: propertyNoOfAnswers2,
                propertyValue: propertyValue2,
                width: width,
              ),

        // PROPERTY 3
        propertyValue3.isEmpty ||
                propertyName3 == '' ||
                propertyNoOfAnswers3 != 3
            ? Container()
            : InfoBox(
                head: propertyName3,
                content: propertyValue3[0],
                noOfAnswers: propertyNoOfAnswers3,
                propertyValue: propertyValue3,
                width: width,
              ),

        // PROPERTY 4
        propertyValue4.isEmpty ||
                propertyName4 == '' ||
                propertyNoOfAnswers4 != 3
            ? Container()
            : InfoBox(
                head: propertyName4,
                content: propertyValue4[0],
                noOfAnswers: propertyNoOfAnswers4,
                propertyValue: propertyValue4,
                width: width,
              ),

        // PROPERTY 5
        propertyValue5.isEmpty ||
                propertyName5 == '' ||
                propertyNoOfAnswers5 != 3
            ? Container()
            : InfoBox(
                head: propertyName5,
                content: propertyValue5[0],
                noOfAnswers: propertyNoOfAnswers5,
                propertyValue: propertyValue5,
                width: width,
              ),
      ],
    );
  }
}

// DISCOUNTS
class AllDiscountsWidget extends StatefulWidget {
  const AllDiscountsWidget({
    super.key,
    required this.noOfDiscounts,
    required this.allDiscount,
  });

  final int noOfDiscounts;
  final List allDiscount;

  @override
  State<AllDiscountsWidget> createState() => _AllDiscountsWidgetState();
}

class _AllDiscountsWidgetState extends State<AllDiscountsWidget> {
  final store = FirebaseFirestore.instance;

  // GET NAME
  Future<String> getName(int index, bool wantName) async {
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: width * 0.0175,
        horizontal: width * 0.02,
      ),
      child: Container(
        width: width,
        height: width * 0.66,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: SweepGradient(
            startAngle: 0,
            colors: [
              Colors.pink.shade300,
              Colors.deepOrange.shade200,
              Colors.amber.shade300,
              Colors.indigo.shade200,
              Colors.indigo.shade300,
            ],
          ),
        ),
        child: Container(
          height: width * 0.66,
          padding: EdgeInsets.all(width * 0.0125),
          margin: EdgeInsets.all(width * 0.0125),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.0125),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Other Discounts From This Shop',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.noOfDiscounts.toString(),
                      style: TextStyle(
                        fontSize: width * 0.045,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: width,
                height: width * 0.5,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemCount: widget.allDiscount.length,
                  itemBuilder: ((context, index) {
                    final currentDiscount = widget.allDiscount[index];
                    final String? image = currentDiscount['discountImageUrl'];
                    final name = currentDiscount['discountName'];
                    final amount = currentDiscount['discountAmount'];
                    final isPercent = currentDiscount['isPercent'];
                    // final endData = currentDiscount['discountEndDateTime'];

                    return Container(
                      width: width * 0.3,
                      height: width * 0.45,
                      decoration: BoxDecoration(
                        color: white,
                        border: Border.all(
                          width: 0.25,
                          color: black,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      padding: EdgeInsets.all(
                        width * 0.003125,
                      ),
                      margin: EdgeInsets.only(
                        left: width * 0.025,
                        right: width * 0.025,
                        top: width * 0.01,
                        bottom: width * 0.015,
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
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: Image.network(
                                      image ??
                                          snapshot.data ??
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/ProhibitionSign2.svg/800px-ProhibitionSign2.svg.png',
                                      fit: BoxFit.cover,
                                      width: width * 0.3,
                                      height: width * 0.3,
                                    ),
                                  );
                                }

                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }),

                          // NAME
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder(
                                  future: getName(index, true),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Text(
                                        snapshot.data ?? name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: width * 0.05,
                                        ),
                                      );
                                    }

                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }),
                              Text(
                                isPercent
                                    ? '$amount % off'
                                    : 'Save Rs. $amount',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: width * 0.045,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
