import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/product/product_page.dart';
import 'package:find_easy_user/page/main/vendor/vendor_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/product_quick_view.dart';
import 'package:find_easy_user/widgets/speech_to_text.dart';
import 'package:find_easy_user/widgets/text_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({
    super.key,
    required this.search,
  });

  final String search;

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  bool isMicPressed = false;
  bool isSearchPressed = false;
  Map searchedShops = {};
  Map searchedProducts = {};
  bool getShopsData = false;
  bool getProductsData = false;

  // INIT STATE
  @override
  void initState() {
    setSearch();
    super.initState();
    getProducts();
    getShops();
  }

  // SET SEARCH
  void setSearch() {
    setState(() {
      searchController.text = widget.search;
    });
  }

  // LISTEN
  Future<void> listen() async {
    var result = await showDialog(
      context: context,
      builder: ((context) => const SpeechToText()),
    );

    if (result != null && result is String) {
      searchController.text = result;
    }
  }

  // SEARCH
  Future<void> search() async {
    await addRecentSearch();

    if (searchController.text.isNotEmpty) {
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) =>
                SearchResultsPage(search: searchController.text)),
          ),
        );
      }
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

  // GET SHOPS
  Future<void> getShops() async {
    var allShops = {};

    final shopSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .get();

    for (var shopSnap in shopSnap.docs) {
      final shopData = shopSnap.data();

      final String name = shopData['Name'];
      final String imageUrl = shopData['Image'];
      final String address = shopData['Address'];
      final String vendorId = shopSnap.id;

      allShops[vendorId] = [name, imageUrl, address];
    }

    searchedShops.clear();

    List<MapEntry<String, int>> relevanceScores = [];
    allShops.forEach((key, value) {
      if (value[0]
          .toString()
          .toLowerCase()
          .startsWith(widget.search.toLowerCase())) {
        int relevance =
            calculateRelevance(value[0], widget.search.toLowerCase());
        relevanceScores.add(MapEntry(key, relevance));
      }
    });

    relevanceScores.sort((a, b) {
      int relevanceComparison = b.value.compareTo(a.value);
      if (relevanceComparison != 0) {
        return relevanceComparison;
      }
      return a.key.compareTo(b.key);
    });

    for (var entry in relevanceScores) {
      searchedShops[entry.key] = allShops[entry.key];
    }

    setState(() {
      getShopsData = true;
    });
  }

  // CALCULATE RELEVANCE (SHOPS)
  int calculateRelevance(String shopName, String searchKeyword) {
    int count = 0;
    for (int i = 0; i <= shopName.length - searchKeyword.length; i++) {
      if (shopName.substring(i, i + searchKeyword.length).toLowerCase() ==
          searchKeyword) {
        count++;
      }
    }
    return count;
  }

  // GET PRODUCTS
  Future<void> getProducts() async {
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .get();

    for (var productSnap in productsSnap.docs) {
      final productData = productSnap.data();

      final String productName = productData['productName'].toString();
      final List tags = productData['Tags'];
      final String imageUrl = productData['images'][0].toString();
      final String productPrice = productData['productPrice'].toString();
      final String productId = productData['productId'].toString();
      final String vendorId = productData['vendorId'].toString();
      final Map<String, dynamic> ratings = productData['ratings'];

      final vendorSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .doc(vendorId)
          .get();

      final vendorData = vendorSnap.data()!;

      final String vendor = vendorData['Name'];

      final productNameLower = productName.toLowerCase();
      final searchLower = widget.search.toLowerCase();

      if (productNameLower.contains(searchLower) ||
          tags.any(
              (tag) => tag.toString().toLowerCase().contains(searchLower))) {
        int relevanceScore = calculateRelevanceScore(
          productNameLower,
          searchLower,
          tags,
          searchLower,
        );

        searchedProducts[productName] = [
          imageUrl,
          productPrice,
          vendor,
          productId,
          relevanceScore,
          ratings,
        ];
      }
    }

    searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
      ..sort((a, b) => b.value[4].compareTo(a.value[4])));

    setState(() {
      getProductsData = true;
    });
  }

  // CALCULATE RELEVANCE (PRODUCTS)
  int calculateRelevanceScore(
      String productName, String searchKeyword, List tags, String searchLower) {
    int score = 0;

    for (int i = 0; i < productName.length; i++) {
      if (i < searchKeyword.length && productName[i] == searchKeyword[i]) {
        score += (productName.length - i) * 3;
      } else {
        break;
      }
    }

    for (var tag in tags) {
      if (tag.toString().toLowerCase().contains(searchLower)) {
        score += 1;
      }
    }

    return score;
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

  // GET PRODUCT DATA
  Future<Map<String, dynamic>> getProductData(String productId) async {
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .get();

    final productData = productsSnap.data()!;

    return productData;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final double width = constraints.maxWidth;

              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEARCH BAR
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: width * 0.0125,
                        ),
                        child: Container(
                          color: primary2.withOpacity(0.5),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: width * 0.1,
                                  height: width * 0.1825,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Icon(
                                    FeatherIcons.arrowLeft,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: width * 0.0125,
                                ),
                                child: Container(
                                  width: width * 0.875,
                                  height: width * 0.1825,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    border: Border.all(
                                      color: primaryDark.withOpacity(0.75),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: width * 0.6125,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        alignment: Alignment.center,
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
                                              width: width * 0.125,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isMicPressed
                                                    ? primary2.withOpacity(0.95)
                                                    : primary2
                                                        .withOpacity(0.25),
                                              ),
                                              child: Icon(
                                                FeatherIcons.mic,
                                                size: width * 0.06,
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
                                                const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(0),
                                                bottomLeft: Radius.circular(0),
                                                bottomRight:
                                                    Radius.circular(12),
                                                topRight: Radius.circular(12),
                                              ),
                                            ),
                                            child: Container(
                                              width: width * 0.125,
                                              decoration: BoxDecoration(
                                                color: isSearchPressed
                                                    ? primary2.withOpacity(0.95)
                                                    : primary2
                                                        .withOpacity(0.25),
                                                borderRadius:
                                                    const BorderRadius.only(
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
                                                size: width * 0.06,
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

                      // FILTERS
                      // ListView.builder(
                      //   scrollDirection: Axis.horizontal,
                      //   itemCount: 4,
                      //   itemBuilder: ((context, index) {
                      //   }),
                      // ),

                      // SHOP
                      !getShopsData
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // SHOPS
                                searchedShops.isEmpty
                                    ? Container()
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.0225,
                                              vertical: width * 0.000725,
                                            ),
                                            child: Text(
                                              'Shops',
                                              style: TextStyle(
                                                color: primaryDark
                                                    .withOpacity(0.8),
                                                fontSize: width * 0.04,
                                              ),
                                            ),
                                          ),
                                          const Divider(),
                                        ],
                                      ),

                                // SHOPS LIST
                                searchedShops.isEmpty
                                    ? searchedProducts.isEmpty
                                        ? const Center(
                                            child: Padding(
                                              padding: EdgeInsets.only(top: 40),
                                              child: Text(
                                                'No Shops Found',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        : Container()
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: searchedShops.length > 3
                                            ? 3
                                            : searchedShops.length,
                                        itemBuilder: ((context, index) {
                                          final currentShop = searchedShops.keys
                                              .toList()[index];

                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.0125,
                                              vertical: width * 0.00625,
                                            ),
                                            child: ListTile(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: ((context) =>
                                                        VendorPage(
                                                          vendorId: currentShop,
                                                        )),
                                                  ),
                                                );
                                              },
                                              splashColor: white,
                                              tileColor:
                                                  primary2.withOpacity(0.125),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                vertical: width * 0.0125,
                                                horizontal: width * 0.025,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              leading: CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                  searchedShops[currentShop][1],
                                                ),
                                                radius: width * 0.0575,
                                              ),
                                              title: Text(
                                                searchedShops[currentShop][0],
                                                style: TextStyle(
                                                  fontSize: width * 0.06125,
                                                ),
                                              ),
                                              subtitle: Text(
                                                searchedShops[currentShop][2],
                                              ),
                                              trailing: const Icon(
                                                FeatherIcons.chevronRight,
                                                color: primaryDark,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                              ],
                            ),

                      // PRODUCT
                      !getProductsData
                          ? const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // PRODUCTS
                                searchedProducts.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 40),
                                          child: Text(
                                            'No Products Found',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: width * 0.0225,
                                              right: width * 0.0225,
                                              bottom: width * 0.0225,
                                            ),
                                            child: Text(
                                              'Products',
                                              style: TextStyle(
                                                color: primaryDark
                                                    .withOpacity(0.8),
                                                fontSize: width * 0.04,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: width * 0.0225,
                                              right: width * 0.0225,
                                              bottom: width * 0.0225,
                                            ),
                                            child: Text(
                                              searchedProducts.length
                                                  .toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                // PRODUCTS LIST
                                searchedProducts.isEmpty
                                    ? Container()
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: width * 0.6 / width,
                                        ),
                                        itemCount: searchedProducts.length,
                                        itemBuilder: ((context, index) {
                                          return StreamBuilder<bool>(
                                            stream: getIfWishlist(
                                              searchedProducts.values
                                                  .toList()[index][3],
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasError) {
                                                return const Center(
                                                  child: Text(
                                                    'Something went wrong',
                                                  ),
                                                );
                                              }

                                              final currentProduct =
                                                  searchedProducts.keys
                                                      .toList()[index]
                                                      .toString();

                                              final image = searchedProducts[
                                                  currentProduct][0];

                                              final productId = searchedProducts
                                                  .values
                                                  .toList()[index][3];
                                              final ratings = searchedProducts
                                                  .values
                                                  .toList()[index][5];

                                              final price = searchedProducts[
                                                          currentProduct][1] ==
                                                      ''
                                                  ? 'N/A'
                                                  : 'Rs. ${searchedProducts[currentProduct][1]}';
                                              final isWishListed =
                                                  snapshot.data ?? false;

                                              return Builder(
                                                builder: (context) {
                                                  return GestureDetector(
                                                    onTap: () async {
                                                      final productData =
                                                          await getProductData(
                                                        productId,
                                                      );
                                                      if (context.mounted) {
                                                        Navigator.of(context)
                                                            .push(
                                                          MaterialPageRoute(
                                                            builder:
                                                                ((context) =>
                                                                    ProductPage(
                                                                      productData:
                                                                          productData,
                                                                    )),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    onDoubleTap: () async {
                                                      await showDialog(
                                                        context: context,
                                                        builder: ((context) =>
                                                            ProductQuickView(
                                                              productId:
                                                                  productId,
                                                            )),
                                                      );
                                                    },
                                                    onLongPress: () async {
                                                      await showDialog(
                                                        context: context,
                                                        builder: ((context) =>
                                                            ProductQuickView(
                                                              productId:
                                                                  productId,
                                                            )),
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        border: Border.all(
                                                          width: 0.25,
                                                          color: Colors.grey
                                                              .withOpacity(
                                                            0.25,
                                                          ),
                                                        ),
                                                      ),
                                                      padding: EdgeInsets.all(
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.0125,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Stack(
                                                            alignment: Alignment
                                                                .topRight,
                                                            children: [
                                                              Center(
                                                                child: Image
                                                                    .network(
                                                                  image,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.5,
                                                                  height: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.58,
                                                                ),
                                                              ),
                                                              Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: const Color
                                                                      .fromRGBO(
                                                                    255,
                                                                    92,
                                                                    78,
                                                                    1,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    4,
                                                                  ),
                                                                ),
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                  horizontal:
                                                                      width *
                                                                          0.0125,
                                                                  vertical:
                                                                      width *
                                                                          0.00625,
                                                                ),
                                                                margin:
                                                                    EdgeInsets
                                                                        .all(
                                                                  width *
                                                                      0.00625,
                                                                ),
                                                                child: Text(
                                                                  '${(ratings as Map).isEmpty ? '--' : ((ratings.values.map((e) => e?[0] ?? 0).toList().reduce((a, b) => a + b) / (ratings.values.isEmpty ? 1 : ratings.values.length)) as double).toStringAsFixed(1)} ⭐',
                                                                  style:
                                                                      const TextStyle(
                                                                    color:
                                                                        white,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
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
                                                                  Padding(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .only(
                                                                      left: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.00625,
                                                                      right: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.00625,
                                                                      top: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.0225,
                                                                    ),
                                                                    child:
                                                                        SizedBox(
                                                                      width:
                                                                          width *
                                                                              0.3,
                                                                      child:
                                                                          Text(
                                                                        currentProduct,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              width * 0.0575,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .symmetric(
                                                                      horizontal: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.0125,
                                                                    ),
                                                                    child: Text(
                                                                      price,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            width *
                                                                                0.05,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              IconButton(
                                                                onPressed:
                                                                    () async {
                                                                  await wishlistProduct(
                                                                      productId);
                                                                },
                                                                icon: Icon(
                                                                  isWishListed
                                                                      ? Icons
                                                                          .favorite
                                                                      : Icons
                                                                          .favorite_border,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                                splashColor:
                                                                    Colors.red,
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        }),
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
      ),
    );
  }
}
