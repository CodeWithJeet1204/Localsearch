import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/search/top_searches_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/text_button.dart';
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
  List? recentSearches;
  Map? topSearchesMap = {};
  List? recentProductId;
  List? recentProductName;
  List? recentProductImage;

  // INIT STATE
  @override
  void initState() {
    getRecentSearch();
    getTopSearches();
    getRecentProducts();
    super.initState();
  }

  // SEARCH
  Future<void> search() async {
    // search function

    await addRecentSearch();
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

    if (!recent.contains(searchController.text) &&
        searchController.text.isNotEmpty) {
      recent.insert(0, searchController.text);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'recentSearches': recent,
    });

    await getRecentSearch();

    searchController.clear();
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

  // GET RECENT PRODUCTS
  Future<void> getRecentProducts() async {
    final userDoc =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final List? recentProductIds = userDoc['recentProducts'];

    if (recentProductIds == null || recentProductIds.isEmpty) {
      setState(() {
        recentProductId = [];
        recentProductName = [];
        recentProductImage = [];
      });

      return;
    }

    List internalProductIdList = [];
    List internalProductImageList = [];
    List internalProductNameList = [];

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
        final productName = productDoc['productName'];
        final productImageUrl = productDoc['images'][0];

        internalProductIdList.add(productId);
        internalProductNameList.add(productName);
        internalProductImageList.add(productImageUrl);
      }
    }

    recentProductId = internalProductIdList;
    recentProductName = internalProductNameList;
    recentProductImage = internalProductImageList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.0225,
            vertical: MediaQuery.of(context).size.width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final double width = constraints.maxWidth;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SEARCH BAR
                    Padding(
                      padding: EdgeInsets.only(
                        top: width * 0.0225,
                        bottom: width * 0.0225,
                        right: width * 0.0125,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.ideographic,
                        children: [
                          // BACK BUTTON
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(FeatherIcons.arrowLeft),
                          ),
                          // SEARCH BAR
                          Container(
                            width: width * 0.85,
                            height: width * 0.133,
                            decoration: BoxDecoration(
                              color: primary,
                              border: Border.all(
                                color: primaryDark.withOpacity(0.75),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: width * 0.6875,
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
                                      top: width * 0.035,
                                    ),
                                    child: TextFormField(
                                      autofillHints: const [],
                                      autofocus: true,
                                      controller: searchController,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.search,
                                      decoration: const InputDecoration(
                                        hintText: 'Search',
                                        hintStyle: TextStyle(
                                          textBaseline: TextBaseline.alphabetic,
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      // validator: (value) {
                                      //   if (value != null) {
                                      //     if (value.isNotEmpty) {
                                      //       return null;
                                      //     } else {
                                      //       return "Search is empty";
                                      //     }
                                      //   }
                                      //   return null;
                                      // },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: width * 0.01,
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      await search();
                                    },
                                    customBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      width: width * 0.1566,
                                      height: width * 0.133,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        FeatherIcons.search,
                                        size: width * 0.066,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

                    // RECENT SEEARCHES LIST
                    recentSearches == null
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : recentSearches!.isEmpty
                            ? Container()
                            : SizedBox(
                                width: width,
                                height: recentSearches!.length > 5
                                    ? 5 * width * 0.15
                                    : recentSearches!.length * width * 0.15,
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: recentSearches!.length > 5
                                      ? 5
                                      : recentSearches!.length,
                                  itemBuilder: ((context, index) {
                                    return Container(
                                      padding: EdgeInsets.only(
                                        left: width * 0.033,
                                        right: width * 0.015,
                                      ),
                                      margin: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                        vertical: width * 0.0125,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            recentSearches![index],
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
                                            tooltip: "Remove",
                                          ),
                                        ],
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
                                return Container(
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
                                  decoration: BoxDecoration(
                                    color: primary2.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        topSearchesMap!.keys.toList()[index],
                                        style: TextStyle(
                                          fontSize: width * 0.05,
                                        ),
                                      ),
                                      Text(
                                        topSearchesMap!.values
                                            .toList()[index]
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: width * 0.05,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),

                    recentProductId == null || recentProductId!.isEmpty
                        ? Container()
                        : const Divider(),

                    // RECENT PRODUCTS
                    recentProductId == null || recentProductId!.isEmpty
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
                    recentProductId == null || recentProductId!.isEmpty
                        ? Container()
                        : SizedBox(
                            width: width,
                            height: width * 0.45,
                            child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recentProductImage!.length > 3
                                  ? 3
                                  : recentProductImage!.length,
                              itemBuilder: ((context, index) {
                                final String id = recentProductId![index];
                                final String name = recentProductName![index];
                                final String image = recentProductImage![index];

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0125,
                                    vertical: width * 0.015,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // navigate to product page
                                    },
                                    child: Container(
                                      width: width * 0.3,
                                      decoration: BoxDecoration(
                                        color: primary2,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.0125,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                image,
                                                fit: BoxFit.cover,
                                                width: width * 0.225,
                                                height: width * 0.25,
                                              ),
                                            ),
                                            Text(
                                              name,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: width * 0.05,
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
              );
            }),
          ),
        ),
      ),
    );
  }
}
