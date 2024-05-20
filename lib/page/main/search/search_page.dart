import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localy_user/page/main/vendor/product/product_page.dart';
import 'package:localy_user/page/main/search/search_results_page.dart';
import 'package:localy_user/page/main/search/top_searches_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/search_bar.dart';
import 'package:localy_user/widgets/text_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  List? allProducts;
  List? recentSearches;
  Map? topSearchesMap = {};
  Map? recentProducts;
  bool isMicPressed = false;
  bool isSearchPressed = false;

  // INIT STATE
  @override
  void initState() {
    getRecentSearch();
    getTopSearches();
    getRecentProducts();
    getAllProducts();
    super.initState();
  }

  // SEARCH
  Future<void> search({String? search}) async {
    await addRecentSearch();

    if (search != null && search.isNotEmpty) {
      searchController.text = search;
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) => SearchResultsPage(search: search)),
          ),
        );
      }
    } else {
      if (searchController.text.isNotEmpty) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: ((context) =>
                  SearchResultsPage(search: searchController.text)),
            ),
          );
        }
      }
    }
  }

  // GET RECENT SEARCH
  Future<void> getRecentSearch() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final recent = userData['recentSearches'] as List?;

    await getTopSearches();

    setState(() {
      if (recent == null) {
        recentSearches = [];
      } else {
        recentSearches = recent;
      }
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

    await getRecentSearch();
  }

  // REMOVE RECENT SEARCH
  Future<void> removeRecentSearch(int index) async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final recent = userData['recentSearches'] as List;

    recent.removeAt(index);

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'recentSearches': recent,
    });

    await getRecentSearch();
  }

  // GET TOP SEARCHES
  Future<void> getTopSearches() async {
    Map<String, int> trendSearchMap = {
      'swa': 3,
      'as': 500,
      'c': 100,
      'a': 3,
      'ab': 3,
      'ac': 3,
      'ad': 3,
      'ar': 3,
      'ae': 3,
      'ag': 3,
      'af': 3,
      'ah': 3,
      'aj': 3,
      'ak': 3,
      'al': 3,
      'ao': 3,
      'aja': 3,
      'aka': 3,
      'ala': 3,
      'aoa': 3,
      'bswa': 3,
      'bas': 5,
      'bc': 100,
      'ba': 3,
      'bab': 3,
      'bac': 3,
      'bad': 3,
      'bar': 3,
      'bae': 3,
      'bag': 3,
      'baf': 3,
      'bah': 3,
      'baj': 3,
      'bak': 3,
      'bal': 3,
      'bao': 3,
      'baja': 3,
      'baka': 3,
      'bala': 3,
      'baoa': 3,
    };

    final trendSnap = await store.collection('Users').get();

    for (var userData in trendSnap.docs) {
      final recentSearches = userData['recentSearches'] as List;

      for (var search in recentSearches) {
        if (trendSearchMap.containsKey(search)) {
          trendSearchMap[search] = trendSearchMap[search]! + 1;
        } else {
          trendSearchMap[search] = 1;
        }
      }
    }

    var sortedEntries = trendSearchMap.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));

    Map<String, int> sortedMap = Map.fromEntries(sortedEntries);

    setState(() {
      topSearchesMap = sortedMap;
    });
  }

  // GET ALL PRODUCTS
  Future<void> getAllProducts() async {
    List products = [];
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .get();

    for (var productDoc in productsSnap.docs) {
      final productData = productDoc.data();

      final productName = productData['productName'];

      if (!products.contains(productName)) {
        products.add(productName);
      }
    }

    allProducts = products;
  }

  // GET RECENT PRODUCTS
  Future<void> getRecentProducts() async {
    final userDoc =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final List? recentProductIds = userDoc['recentProducts'];

    if (recentProductIds == null || recentProductIds.isEmpty) {
      setState(() {
        recentProducts = {};
      });
      return;
    }

    Map<String, dynamic> product = {};

    for (String productId in recentProductIds) {
      if (productId.contains('//')) {
        continue;
      }
      final productDoc = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(productId)
          .get();

      if (productDoc.exists) {
        final productData = productDoc.data()!;
        final productName = productDoc['productName'];
        final imageUrl = productDoc['images'][0];

        product[productId] = [productName, imageUrl, productData];
      }
    }

    recentProducts = product;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.00625,
            vertical: width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final double width = constraints.maxWidth;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MySearchBar(
                      width: width,
                      autoFocus: true,
                    ),

                    // RECENT SEARCHES
                    recentSearches == null || recentSearches!.isEmpty
                        ? Container()
                        : Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                              vertical: width * 0.00625,
                            ),
                            child: Text(
                              'Recent Searches',
                              style: TextStyle(
                                color: primaryDark.withOpacity(0.8),
                                fontSize: width * 0.04,
                              ),
                            ),
                          ),

                    // RECENT SEARCHES LIST
                    recentSearches == null
                        ? Container()
                        : recentSearches!.isEmpty
                            ? Container()
                            : SizedBox(
                                width: width,
                                height: recentSearches!.length > 5
                                    ? 5 * width * 0.166
                                    : recentSearches!.length * width * 0.166,
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: recentSearches!.length > 5
                                      ? 5
                                      : recentSearches!.length,
                                  itemBuilder: ((context, index) {
                                    final String name = recentSearches![index];

                                    return GestureDetector(
                                      onTap: () async {
                                        await search(search: name);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: primary2.withOpacity(0.125),
                                          border: Border.all(
                                            width: 0.5,
                                            color:
                                                primaryDark.withOpacity(0.25),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.only(
                                          left: width * 0.033,
                                          right: width * 0.015,
                                        ),
                                        margin: EdgeInsets.symmetric(
                                          horizontal: width * 0.0125,
                                          vertical: width * 0.0125,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: width * 0.05,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                await removeRecentSearch(
                                                  index,
                                                );
                                              },
                                              icon: const Icon(FeatherIcons.x),
                                              tooltip: 'Remove',
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                    recentSearches != null && recentSearches!.isEmpty
                        ? Container()
                        : const Divider(),

                    // TOP SEARCHES
                    topSearchesMap == null || topSearchesMap!.isEmpty
                        ? Container()
                        : Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                              vertical: width * 0.00625,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Top Searches 🔥',
                                  style: TextStyle(
                                    color: primaryDark.withOpacity(0.8),
                                    fontSize: width * 0.04,
                                  ),
                                ),
                                MyTextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: ((context) => TopSearchPage(
                                              data: topSearchesMap!,
                                            )),
                                      ),
                                    );
                                  },
                                  text: 'See All',
                                  textColor: primaryDark2,
                                ),
                              ],
                            ),
                          ),

                    // TOP SEARCHES LIST
                    topSearchesMap == null || topSearchesMap!.isEmpty
                        ? Container()
                        : SizedBox(
                            width: width,
                            height: topSearchesMap!.keys.length > 3
                                ? 3 * width * 0.15
                                : topSearchesMap!.keys.length * width * 0.15,
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: topSearchesMap!.keys.length > 3
                                  ? 3
                                  : topSearchesMap!.keys.length,
                              itemBuilder: ((context, index) {
                                final String name =
                                    topSearchesMap!.keys.toList()[index];
                                final String number = topSearchesMap!.values
                                    .toList()[index]
                                    .toString();

                                return GestureDetector(
                                  onTap: () async {
                                    await search(search: name);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: primary2.withOpacity(0.125),
                                      border: Border.all(
                                        width: 0.5,
                                        color: primaryDark.withOpacity(0.25),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.only(
                                      left: width * 0.033,
                                      right: width * 0.015,
                                      top: width * 0.0275,
                                      bottom: width * 0.0275,
                                    ),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: width * 0.0125,
                                      vertical: width * 0.0125,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: width * 0.05,
                                          ),
                                        ),
                                        Text(
                                          number,
                                          style: TextStyle(
                                            fontSize: width * 0.05,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                    recentProducts == null || recentProducts!.isEmpty
                        ? Container()
                        : const Divider(),

                    // RECENT PRODUCTS
                    recentProducts == null || recentProducts!.isEmpty
                        ? Container()
                        : Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                              vertical: width * 0.00625,
                            ),
                            child: Text(
                              'Recent Products',
                              style: TextStyle(
                                color: primaryDark.withOpacity(0.8),
                                fontSize: width * 0.04,
                              ),
                            ),
                          ),

                    // RECENT PRODUCTS LIST
                    recentProducts == null || recentProducts!.isEmpty
                        ? Container()
                        : SizedBox(
                            width: width,
                            height: width * 0.4125,
                            child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recentProducts!.length > 3
                                  ? 3
                                  : recentProducts!.length,
                              itemBuilder: ((context, index) {
                                final String name =
                                    recentProducts!.values.toList()[index][0];
                                final String image =
                                    recentProducts!.values.toList()[index][1];
                                final Map<String, dynamic> data =
                                    recentProducts!.values.toList()[index][2];

                                return GestureDetector(
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
                                    decoration: BoxDecoration(
                                      color: white,
                                      border: Border.all(
                                        width: 0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    padding: EdgeInsets.all(
                                      width * 0.00625,
                                    ),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: width * 0.0125,
                                      vertical: width * 0.0125,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                        Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: width * 0.05,
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
    );
  }
}
