import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/product/product_page.dart';
import 'package:find_easy_user/page/main/vendor/vendor_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/product_quick_view.dart';
import 'package:find_easy_user/widgets/skeleton_container.dart';
import 'package:find_easy_user/widgets/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventsSearchResultsPage extends StatefulWidget {
  const EventsSearchResultsPage({
    super.key,
    required this.search,
  });

  final String search;

  @override
  State<EventsSearchResultsPage> createState() =>
      _EventsSearchResultsPageState();
}

class _EventsSearchResultsPageState extends State<EventsSearchResultsPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  bool isMicPressed = false;
  bool isSearchPressed = false;
  Map searchedShops = {};
  Map searchedEvents = {};
  bool getShopsData = false;
  bool getEventsData = false;
  String? eventSort = 'Recently Added';

  // INIT STATE
  @override
  void initState() {
    setSearch();
    super.initState();
    getEvents();
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
                EventsSearchResultsPage(search: searchController.text)),
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

  // GET EVENTS
  Future<void> getEvents() async {
    final eventsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .get();

    for (var eventSnap in eventsSnap.docs) {
      final eventData = eventSnap.data();

      final String eventName = eventData['productName'].toString();
      final List tags = eventData['Tags'];
      final String imageUrl = eventData['images'][0].toString();
      final String productPrice = eventData['productPrice'].toString();
      final String eventId = eventData['productId'].toString();
      final String vendorId = eventData['vendorId'].toString();
      final Map<String, dynamic> ratings = eventData['ratings'];
      final Timestamp datetime = eventData['datetime'];
      final int views = eventData['productViews'];

      final vendorSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .doc(vendorId)
          .get();

      final vendorData = vendorSnap.data()!;

      final String vendor = vendorData['Name'];

      final eventNameLower = eventName.toLowerCase();
      final searchLower = widget.search.toLowerCase();

      if (eventNameLower.contains(searchLower) ||
          tags.any(
              (tag) => tag.toString().toLowerCase().contains(searchLower))) {
        int relevanceScore = calculateRelevanceScore(
          eventNameLower,
          searchLower,
          tags,
          searchLower,
        );

        searchedEvents[eventName] = [
          imageUrl,
          vendor,
          productPrice,
          eventId,
          relevanceScore,
          ratings,
          datetime,
          views,
        ];
      }
    }

    searchedEvents = Map.fromEntries(searchedEvents.entries.toList()
      ..sort((a, b) => b.value[4].compareTo(a.value[4])));

    setState(() {
      getEventsData = true;
    });
  }

  // CALCULATE RELEVANCE (EVENTS)
  int calculateRelevanceScore(
      String eventName, String searchKeyword, List tags, String searchLower) {
    int score = 0;

    for (int i = 0; i < eventName.length; i++) {
      if (i < searchKeyword.length && eventName[i] == searchKeyword[i]) {
        score += (eventName.length - i) * 3;
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
  Stream<bool> getIfWishlist(String eventId) {
    return store
        .collection('Users')
        .doc(auth.currentUser!.uid)
        .snapshots()
        .map((userSnap) {
      final userData = userSnap.data()!;
      final userWishlist = userData['wishlists'] as List;

      return userWishlist.contains(eventId);
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

  // GET EVENT DATA
  Future<Map<String, dynamic>> getEventData(String eventId) async {
    final eventsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(eventId)
        .get();

    final eventData = eventsSnap.data()!;

    return eventData;
  }

  // SORT EVENTS
  void sortEvents(EventSorting sorting) {
    setState(() {
      switch (sorting) {
        case EventSorting.recentlyAdded:
          searchedEvents = Map.fromEntries(searchedEvents.entries.toList()
            ..sort((a, b) => (b.value[6] as Timestamp).compareTo(a.value[6])));
          break;
        case EventSorting.highestRated:
          searchedEvents = Map.fromEntries(searchedEvents.entries.toList()
            ..sort((a, b) => calculateAverageRating(b.value[5])
                .compareTo(calculateAverageRating(a.value[5]))));
          break;
        case EventSorting.mostViewed:
          searchedEvents = Map.fromEntries(searchedEvents.entries.toList()
            ..sort((a, b) => (b.value[7] as int).compareTo(a.value[7])));
          break;
        case EventSorting.lowestPrice:
          searchedEvents = Map.fromEntries(searchedEvents.entries.toList()
            ..sort((a, b) =>
                double.parse(a.value[2]).compareTo(double.parse(b.value[2]))));
          break;
        case EventSorting.highestPrice:
          searchedEvents = Map.fromEntries(searchedEvents.entries.toList()
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SHOPS
                          !getShopsData
                              ? SkeletonContainer(
                                  width: width * 0.2,
                                  height: 20,
                                )
                              : searchedShops.isEmpty
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
                                              color:
                                                  primaryDark.withOpacity(0.8),
                                              fontSize: width * 0.04,
                                            ),
                                          ),
                                        ),
                                        const Divider(),
                                      ],
                                    ),

                          // SHOPS LIST
                          !getShopsData
                              ? SizedBox(
                                  width: width,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: 2,
                                    itemBuilder: ((context, index) {
                                      return Container(
                                        width: width,
                                        height: width * 0.225,
                                        decoration: BoxDecoration(
                                          color: lightGrey,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.0225,
                                        ),
                                        margin: EdgeInsets.all(
                                          width * 0.0125,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                SkeletonContainer(
                                                  width: width * 0.15,
                                                  height: width * 0.15,
                                                ),
                                                SizedBox(
                                                  width: width * 0.0225,
                                                ),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SkeletonContainer(
                                                      width: width * 0.33,
                                                      height: 20,
                                                    ),
                                                    SkeletonContainer(
                                                      width: width * 0.2,
                                                      height: 12,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SkeletonContainer(
                                              width: width * 0.075,
                                              height: width * 0.075,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              : searchedShops.isEmpty
                                  ? searchedEvents.isEmpty
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
                                        final currentShop =
                                            searchedShops.keys.toList()[index];

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

                      // EVENT
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // EVENTS
                          !getEventsData
                              ? SkeletonContainer(
                                  width: width * 0.2,
                                  height: 20,
                                )
                              : searchedEvents.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 40),
                                        child: Text(
                                          'No Events Found',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: EdgeInsets.all(width * 0.0225),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Events',
                                            style: TextStyle(
                                              color:
                                                  primaryDark.withOpacity(0.8),
                                              fontSize: width * 0.04,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.0125,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primary3,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: DropdownButton<String>(
                                              underline: const SizedBox(),
                                              dropdownColor: primary2,
                                              value: eventSort,
                                              iconEnabledColor: primaryDark,
                                              items: [
                                                'Recently Added',
                                                'Highest Rated',
                                                'Most Viewed',
                                                'Price - Highest to Lowest',
                                                'Price - Lowest to Highest'
                                              ]
                                                  .map((e) =>
                                                      DropdownMenuItem<String>(
                                                        value: e,
                                                        child: Text(e),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                sortEvents(
                                                  value == 'Recently Added'
                                                      ? EventSorting
                                                          .recentlyAdded
                                                      : value == 'Highest Rated'
                                                          ? EventSorting
                                                              .highestRated
                                                          : value ==
                                                                  'Most Viewed'
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
                                                  eventSort = value;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                          // EVENTS LIST
                          !getEventsData
                              ? SizedBox(
                                  width: width,
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.825,
                                    ),
                                    itemCount: 6,
                                    itemBuilder: ((context, index) {
                                      return Padding(
                                        padding: EdgeInsets.all(width * 0.0225),
                                        child: Container(
                                          width: width * 0.28,
                                          height: width * 0.3,
                                          decoration: BoxDecoration(
                                            color: lightGrey,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: SkeletonContainer(
                                                  width: width * 0.4,
                                                  height: width * 0.4,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: width * 0.0225,
                                                ),
                                                child: SkeletonContainer(
                                                  width: width * 0.4,
                                                  height: width * 0.04,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: width * 0.0225,
                                                ),
                                                child: SkeletonContainer(
                                                  width: width * 0.2,
                                                  height: width * 0.03,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              : searchedEvents.isEmpty
                                  ? Container()
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: width * 0.6 / width,
                                      ),
                                      itemCount: searchedEvents.length,
                                      itemBuilder: ((context, index) {
                                        return StreamBuilder<bool>(
                                          stream: getIfWishlist(
                                            searchedEvents.values
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

                                            final currentEvent = searchedEvents
                                                .keys
                                                .toList()[index]
                                                .toString();

                                            final image =
                                                searchedEvents[currentEvent][0];

                                            final eventId = searchedEvents
                                                .values
                                                .toList()[index][3];

                                            final ratings = searchedEvents
                                                .values
                                                .toList()[index][5];

                                            final price = searchedEvents[
                                                        currentEvent][2] ==
                                                    ''
                                                ? 'N/A'
                                                : 'Rs. ${searchedEvents[currentEvent][2]}';
                                            final isWishListed =
                                                snapshot.data ?? false;

                                            return GestureDetector(
                                              onTap: () async {
                                                final productData =
                                                    await getEventData(
                                                  eventId,
                                                );
                                                if (context.mounted) {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: ((context) =>
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
                                                        productId: eventId,
                                                      )),
                                                );
                                              },
                                              onLongPress: () async {
                                                await showDialog(
                                                  context: context,
                                                  builder: ((context) =>
                                                      ProductQuickView(
                                                        productId: eventId,
                                                      )),
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    width: 0.25,
                                                    color:
                                                        Colors.grey.withOpacity(
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
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Stack(
                                                      alignment:
                                                          Alignment.topRight,
                                                      children: [
                                                        Center(
                                                          child: Image.network(
                                                            image,
                                                            fit: BoxFit.cover,
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
                                                                width * 0.0125,
                                                            vertical:
                                                                width * 0.00625,
                                                          ),
                                                          margin:
                                                              EdgeInsets.all(
                                                            width * 0.00625,
                                                          ),
                                                          child: Text(
                                                            '${(ratings as Map).isEmpty ? '--' : ((ratings.values.map((e) => e?[0] ?? 0).toList().reduce((a, b) => a + b) / (ratings.values.isEmpty ? 1 : ratings.values.length)) as double).toStringAsFixed(1)} ⭐',
                                                            style:
                                                                const TextStyle(
                                                              color: white,
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
                                                                left: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.00625,
                                                                right: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.00625,
                                                                top: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.0225,
                                                              ),
                                                              child: SizedBox(
                                                                width:
                                                                    width * 0.3,
                                                                child: Text(
                                                                  currentEvent,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        width *
                                                                            0.0575,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                horizontal: MediaQuery.of(
                                                                            context)
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
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        IconButton(
                                                          onPressed: () async {
                                                            await wishlistProduct(
                                                                eventId);
                                                          },
                                                          icon: Icon(
                                                            isWishListed
                                                                ? Icons.favorite
                                                                : Icons
                                                                    .favorite_border,
                                                            color: Colors.red,
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
