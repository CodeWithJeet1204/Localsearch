import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/speech_to_text.dart';
import 'package:find_easy_user/widgets/text_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
    searchController.text = widget.search;
    getShops();
    getProducts();
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

  Future<void> getShops() async {
    var allShops = {};

    final shopSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .get();

    shopSnap.docs.forEach((shopSnap) {
      final shopData = shopSnap.data();

      final String shopName = shopData['Name'].toString();
      final String imageUrl = shopData['Image'];
      final String address = shopData['Address'];
      final String vendorId = shopSnap.id;

      allShops[shopName] = [address, imageUrl, vendorId];
    });

    searchedShops.clear();

    List<MapEntry<String, int>> relevanceScores = [];
    allShops.forEach((key, value) {
      if (key
          .toString()
          .toLowerCase()
          .startsWith(widget.search.toLowerCase())) {
        int relevance = calculateRelevance(key, widget.search.toLowerCase());
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

    relevanceScores.forEach((entry) {
      searchedShops[entry.key] = allShops[entry.key];
    });

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

    productsSnap.docs.forEach((productSnap) async {
      final productData = productSnap.data();

      final String productName = productData['productName'].toString();
      final String imageUrl = productData['images'][0].toString();
      final String productPrice = productData['productPrice'].toString();
      final String productId = productData['productId'].toString();
      final String vendorId = productData['vendorId'].toString();

      final vendorSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .doc(vendorId)
          .get();

      final vendorData = vendorSnap.data()!;

      final String vendor = vendorData['Name'];

      if (productName.toLowerCase().contains(widget.search.toLowerCase())) {
        int relevanceScore =
            calculateRelevanceScore(productName, widget.search);

        searchedProducts[productName] = [
          imageUrl,
          productPrice,
          vendor,
          productId,
          relevanceScore,
        ];
      }
    });

    setState(() {
      getProductsData = true;
    });
  }

// CALCULATE RELEVANCE (PRODUCTS)
  int calculateRelevanceScore(String productName, String searchKeyword) {
    int score = 0;
    String lowercaseProductName = productName.toLowerCase();
    String lowercaseSearchKeyword = searchKeyword.toLowerCase();

    for (int i = 0; i < lowercaseProductName.length; i++) {
      if (i < lowercaseSearchKeyword.length &&
          lowercaseProductName[i] == lowercaseSearchKeyword[i]) {
        score += (lowercaseProductName.length - i);
      } else {
        break;
      }
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: !getShopsData || !getProductsData
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
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
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    width: width * 0.1,
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
                                    height: width * 0.15,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      border: Border.all(
                                        color: primaryDark.withOpacity(0.75),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                                      ? primary2
                                                          .withOpacity(0.95)
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
                                                  bottomLeft:
                                                      Radius.circular(0),
                                                  bottomRight:
                                                      Radius.circular(12),
                                                  topRight: Radius.circular(12),
                                                ),
                                              ),
                                              child: Container(
                                                width: width * 0.15,
                                                decoration: BoxDecoration(
                                                  color: isSearchPressed
                                                      ? primary2
                                                          .withOpacity(0.95)
                                                      : primary2
                                                          .withOpacity(0.25),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft: Radius.circular(0),
                                                    bottomLeft:
                                                        Radius.circular(0),
                                                    bottomRight:
                                                        Radius.circular(12),
                                                    topRight:
                                                        Radius.circular(12),
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

                            // FILTERS
                            // ListView.builder(
                            //   scrollDirection: Axis.horizontal,
                            //   itemCount: 4,
                            //   itemBuilder: ((context, index) {
                            //   }),
                            // ),

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
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Shops',
                                              style: TextStyle(
                                                color: primaryDark
                                                    .withOpacity(0.8),
                                                fontSize: width * 0.04,
                                              ),
                                            ),
                                            searchedShops.length > 3
                                                ? MyTextButton(
                                                    onPressed: () {},
                                                    text: "See All",
                                                    textColor: primaryDark,
                                                  )
                                                : Container(),
                                          ],
                                        ),
                                      ),
                                      Divider(),
                                    ],
                                  ),

                            // SHOPS LIST
                            searchedShops.isEmpty
                                ? Container()
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: searchedShops.length > 3
                                        ? 3
                                        : searchedShops.length,
                                    itemBuilder: ((context, index) {
                                      final currentShop =
                                          searchedShops.keys.toList()[index];

                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.0125,
                                          vertical: width * 0.00625,
                                        ),
                                        child: ListTile(
                                          onTap: () {},
                                          splashColor: white,
                                          tileColor:
                                              primary2.withOpacity(0.125),
                                          contentPadding: EdgeInsets.symmetric(
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
                                            currentShop,
                                            style: TextStyle(
                                              fontSize: width * 0.06125,
                                            ),
                                          ),
                                          subtitle: Text(
                                            searchedShops[currentShop][0],
                                          ),
                                          trailing: Icon(
                                            FeatherIcons.chevronRight,
                                            color: primaryDark,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),

                            // PRODUCTS
                            searchedProducts.isEmpty
                                ? Container()
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
                                            color: primaryDark.withOpacity(0.8),
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
                                          searchedProducts.length.toString(),
                                          style: TextStyle(
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
                                    physics: ClampingScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: width * 0.6 / width,
                                    ),
                                    itemCount: searchedProducts.length,
                                    itemBuilder: ((context, index) {
                                      final currentProduct = searchedProducts
                                          .keys
                                          .toList()[index]
                                          .toString();
                                      print(
                                        'Current Product Map: ${searchedProducts[currentProduct]}',
                                      );
                                      print("Current Product: $currentProduct");

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: white,
                                          border: Border.all(
                                            width: 0.25,
                                            color:
                                                primaryDark.withOpacity(0.25),
                                          ),
                                        ),
                                        padding: EdgeInsets.all(width * 0.0125),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Image.network(
                                                searchedProducts[currentProduct]
                                                    [0],
                                                fit: BoxFit.cover,
                                                width: width * 0.5,
                                                height: width * 0.58,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: width * 0.0125,
                                                        right: width * 0.0125,
                                                        top: width * 0.0225,
                                                      ),
                                                      child: Text(
                                                        currentProduct,
                                                        style: TextStyle(
                                                          fontSize:
                                                              width * 0.0575,
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal:
                                                            width * 0.0125,
                                                      ),
                                                      child: Text(
                                                        searchedProducts[
                                                                        currentProduct]
                                                                    [1] ==
                                                                ''
                                                            ? 'N/A'
                                                            : 'Rs. ${searchedProducts[currentProduct][1]}',
                                                        style: TextStyle(
                                                          fontSize:
                                                              width * 0.05,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  onPressed: () {},
                                                  icon: Icon(
                                                    FeatherIcons.heart,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
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
