import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/search/search_results_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/image_view.dart';
import 'package:find_easy_user/widgets/info_box.dart';
import 'package:find_easy_user/widgets/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({
    super.key,
    required this.productData,
  });

  final Map<String, dynamic> productData;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  bool isMicPressed = false;
  bool isSearchPressed = false;
  int _currentIndex = 0;
  bool isWishListed = false;
  String? vendorName;
  String? vendorImageUrl;

  // INIT STATE
  @override
  void initState() {
    getIfWishlist(widget.productData['productId']);
    getVendorInfo();
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
      vendorImageUrl = vendorData['Image'];
    });
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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              double width = constraints.maxWidth;
              print(propertyName0);

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

                      // NAME
                      Padding(
                        padding: const EdgeInsets.all(4),
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
                                (e) => GestureDetector(
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
                              )
                              .toList(),
                          options: CarouselOptions(
                            enableInfiniteScroll:
                                images.length > 1 ? true : false,
                            viewportFraction: 1,
                            // aspectRatio: 1,
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
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              price == "" ? 'N/A (price)' : 'Rs. ${price}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primaryDark,
                                fontSize: 22,
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
                      InfoBox(
                        head: "Description",
                        content: description,
                        noOfAnswers: 1,
                        propertyValue: [],
                        width: width,
                      ),

                      // BRAND
                      InfoBox(
                        head: "Brand",
                        content: brand,
                        noOfAnswers: 1,
                        propertyValue: [],
                        width: width,
                      ),

                      // CATEGORY
                      InfoBox(
                        head: "Category",
                        content: categoryName,
                        noOfAnswers: 1,
                        propertyValue: [],
                        width: width,
                      ),

                      // VENDOR
                      vendorName == null
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.0125,
                                vertical: width * 0.0225,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // VENDOR PROFILE
                                  CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(vendorImageUrl!),
                                  ),

                                  // VENDOR NAME
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.033),
                                    child: Text(
                                      vendorName!,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      // PROPERTY 0
                      propertyValue0.isEmpty
                          ? Container()
                          : InfoBox(
                              head: propertyName0,
                              noOfAnswers: propertyNoOfAnswers0,
                              width: width,
                              content: propertyValue0.length == 1
                                  ? propertyValue0[0]
                                  : null,
                              propertyValue: propertyValue0.length > 1
                                  ? propertyValue0
                                      .map(
                                        (e) => Container(
                                          height: 40,
                                          margin: EdgeInsets.only(
                                            right: 4,
                                            top: 4,
                                            bottom: 4,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            e,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: primaryDark2,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList()
                                  : List.empty(),
                            ),

                      // PROPERTY 1
                      propertyValue1.isEmpty
                          ? Container()
                          : InfoBox(
                              head: propertyName1,
                              noOfAnswers: propertyNoOfAnswers1,
                              width: width,
                              content: propertyValue1.length == 1
                                  ? propertyValue1[0]
                                  : null,
                              propertyValue: propertyValue1.length > 1
                                  ? propertyValue1
                                      .map(
                                        (e) => Container(
                                          height: 40,
                                          margin: EdgeInsets.only(
                                            right: 4,
                                            top: 4,
                                            bottom: 4,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            e,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: primaryDark2,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList()
                                  : List.empty(),
                            ),

                      // PROPERTY 2
                      propertyValue2.isEmpty
                          ? Container()
                          : InfoBox(
                              head: propertyName2,
                              noOfAnswers: propertyNoOfAnswers2,
                              width: width,
                              content: propertyValue2.length == 1
                                  ? propertyValue2[0]
                                  : null,
                              propertyValue: propertyValue2.length > 1
                                  ? propertyValue2
                                      .map(
                                        (e) => Container(
                                          height: 40,
                                          margin: EdgeInsets.only(
                                            right: 4,
                                            top: 4,
                                            bottom: 4,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            e,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: primaryDark2,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList()
                                  : List.empty(),
                            ),

                      // PROPERTY 3
                      propertyValue3.isEmpty
                          ? Container()
                          : InfoBox(
                              head: propertyName3,
                              noOfAnswers: propertyNoOfAnswers3,
                              width: width,
                              content: propertyValue3.length == 1
                                  ? propertyValue3[0]
                                  : null,
                              propertyValue: propertyValue3.length > 1
                                  ? propertyValue3
                                      .map(
                                        (e) => Container(
                                          height: 40,
                                          margin: EdgeInsets.only(
                                            right: 4,
                                            top: 4,
                                            bottom: 4,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            e,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: primaryDark2,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList()
                                  : List.empty(),
                            ),

                      // PROPERTY 4
                      propertyValue4.isEmpty
                          ? Container()
                          : InfoBox(
                              head: propertyName4,
                              noOfAnswers: propertyNoOfAnswers4,
                              width: width,
                              content: propertyValue4.length == 1
                                  ? propertyValue4[0]
                                  : null,
                              propertyValue: propertyValue4.length > 1
                                  ? propertyValue4
                                      .map(
                                        (e) => Container(
                                          height: 40,
                                          margin: EdgeInsets.only(
                                            right: 4,
                                            top: 4,
                                            bottom: 4,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            e,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: primaryDark2,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList()
                                  : List.empty(),
                            ),

                      // PROPERTY 5
                      propertyValue5.isEmpty
                          ? Container()
                          : InfoBox(
                              head: propertyName5,
                              noOfAnswers: propertyNoOfAnswers5,
                              width: width,
                              content: propertyValue5.length == 1
                                  ? propertyValue5[0]
                                  : null,
                              propertyValue: propertyValue5.length > 1
                                  ? propertyValue5
                                      .map(
                                        (e) => Container(
                                          height: 40,
                                          margin: EdgeInsets.only(
                                            right: 4,
                                            top: 4,
                                            bottom: 4,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            e,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: primaryDark2,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList()
                                  : List.empty(),
                            ),
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
