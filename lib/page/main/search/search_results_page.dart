import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:http/http.dart' as http;
import 'package:localsearch/page/main/location_change_page.dart';
import 'package:localsearch/page/main/vendor/product/product_page.dart';
import 'package:localsearch/page/main/vendor/vendor_page.dart';
import 'package:localsearch/providers/location_provider.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/product_quick_view.dart';
import 'package:localsearch/widgets/skeleton_container.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:localsearch/widgets/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  Map<String, Map<String, dynamic>> searchedShops = {};
  Map<String, Map<String, dynamic>> searchedProducts = {};
  Map<String, Map<String, dynamic>> rangeShops = {};
  Map<String, Map<String, dynamic>> rangeProducts = {};
  bool isShopsData = false;
  bool isProductsData = false;
  String? productSort = 'Recently Added';
  double distanceRange = 5;
  int noOf = 12;
  bool isLoadMore = false;
  final scrollController = ScrollController();
  String selected = 'Products';

  // INIT STATE
  @override
  void initState() {
    scrollController.addListener(scrollListener);
    setSearch();
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // DID CHANGE DEPENDENCIES
  @override
  void didChangeDependencies() {
    final locationProvider = Provider.of<LocationProvider>(context);

    getProducts(locationProvider);
    super.didChangeDependencies();
  }

  // SCROLL LISTENER
  Future<void> scrollListener() async {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      setState(() {
        isLoadMore = true;
      });
      noOf = noOf + 8;
      setState(() {
        isLoadMore = false;
      });
    }
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
  Future<void> getShops(LocationProvider locationProvider) async {
    Map<String, Map<String, dynamic>> allShops = {};

    double? yourLatitude;
    double? yourLongitude;

    // GET DRIVING DISTANCE
    Future<double?> getDrivingDistance(
      double startLat,
      double startLong,
      double endLat,
      double endLong,
    ) async {
      String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$startLat,$startLong&destinations=$endLat,$endLong&key=AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';
      try {
        var response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['rows'].isNotEmpty &&
              data['rows'][0]['elements'].isNotEmpty) {
            final distance =
                data['rows'][0]['elements'][0]['distance']['value'];
            return distance / 1000;
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    if (locationProvider.cityName == 'Your Location') {
      final shopSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .limit(noOf)
          .get();

      yourLatitude = locationProvider.cityLatitude;
      yourLongitude = locationProvider.cityLongitude;

      for (var shopSnap in shopSnap.docs) {
        final shopData = shopSnap.data();

        final String name = shopData['Name'];
        final String imageUrl = shopData['Image'];
        final double latitude = shopData['Latitude'];
        final double longitude = shopData['Longitude'];
        final String vendorId = shopSnap.id;
        double distance = 0;

        final address = await getAddress(latitude, longitude);

        if (yourLatitude != null && yourLongitude != null) {
          distance = await getDrivingDistance(
                yourLatitude,
                yourLongitude,
                latitude,
                longitude,
              ) ??
              0;
        }

        if (distance * 0.925 < 5) {
          allShops[vendorId] = {
            'name': name,
            'imageUrl': imageUrl,
            'Latitude': latitude,
            'Longitude': longitude,
            'address': address,
            'distance': distance,
          };
        }
      }
    } else {
      final shopSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .where('City', isEqualTo: locationProvider.cityName)
          .limit(noOf)
          .get();

      for (var shopSnap in shopSnap.docs) {
        final shopData = shopSnap.data();

        final String name = shopData['Name'];
        final String imageUrl = shopData['Image'];
        final double latitude = shopData['Latitude'];
        final double longitude = shopData['Longitude'];
        final String cityName = shopData['City'];
        final String vendorId = shopSnap.id;

        final address = await getAddress(latitude, longitude);

        if (cityName == locationProvider.cityName) {
          allShops[vendorId] = {
            'name': name,
            'imageUrl': imageUrl,
            'Latitude': latitude,
            'Longitude': longitude,
            'address': address,
          };
        }
      }
    }
    searchedShops.clear();

    List<MapEntry<String, int>> relevanceScores = [];
    allShops.forEach((key, value) {
      if (value['name']
          .toString()
          .toLowerCase()
          .startsWith(widget.search.toLowerCase())) {
        int relevance =
            calculateRelevance(value['name'], widget.search.toLowerCase());
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
      searchedShops[entry.key] = allShops[entry.key]!;
      rangeShops[entry.key] = allShops[entry.key]!;
    }
    setState(() {
      isShopsData = true;
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
  Future<void> getProducts(LocationProvider locationProvider) async {
    double? yourLatitude;
    double? yourLongitude;

    // GET DRIVING DISTANCE
    Future<double?> getDrivingDistance(
      double startLat,
      double startLong,
      double endLat,
      double endLong,
    ) async {
      String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$startLat,$startLong&destinations=$endLat,$endLong&key=AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';
      try {
        var response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['rows'].isNotEmpty &&
              data['rows'][0]['elements'].isNotEmpty) {
            final distance =
                data['rows'][0]['elements'][0]['distance']['value'];
            return distance / 1000;
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    if (locationProvider.cityName == 'Your Location') {
      final productsSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .limit(noOf)
          .get();

      setState(() {
        yourLatitude = locationProvider.cityLatitude;
        yourLongitude = locationProvider.cityLongitude;
      });

      for (var productSnap in productsSnap.docs) {
        final productData = productSnap.data();

        final String productName = productData['productName'];
        final List tags = productData['Tags'];
        final String imageUrl = productData['images'][0];
        final productPrice = productData['productPrice'];
        final String productId = productData['productId'];
        final String categoryName = productData['categoryName'];
        final Map<String, dynamic> ratings = productData['ratings'];
        final Timestamp datetime = productData['datetime'];
        final List views = productData['productViewsTimestamp'];
        final double vendorLatitude = productData['Latitude'];
        final double vendorLongitude = productData['Longitude'];
        double distance = 0;

        final productNameLower = productName.toLowerCase();
        final searchLower = widget.search.toLowerCase();

        if (productNameLower.contains(searchLower) ||
            tags.any(
              (tag) => tag.toString().toLowerCase().contains(
                    searchLower,
                  ),
            ) ||
            categoryName.toString().toLowerCase().contains(searchLower)) {
          if (yourLatitude != null && yourLongitude != null) {
            distance = await getDrivingDistance(
                  yourLatitude!,
                  yourLongitude!,
                  vendorLatitude,
                  vendorLongitude,
                ) ??
                0;
          }

          if (distance * 0.925 < 5) {
            int relevanceScore = calculateRelevanceScore(
              productNameLower,
              searchLower,
              tags,
              searchLower,
            );

            searchedProducts[productName] = {
              'imageUrl': imageUrl,
              'productPrice': productPrice,
              'productId': productId,
              'relevanceScore': relevanceScore,
              'ratings': ratings,
              'datetime': datetime,
              'views': views,
              'distance': distance,
            };
            rangeProducts[productName] = {
              'imageUrl': imageUrl,
              'productPrice': productPrice,
              'productId': productId,
              'relevanceScore': relevanceScore,
              'ratings': ratings,
              'datetime': datetime,
              'views': views,
              'distance': distance,
            };
          }
        }
      }
    } else {
      final productsSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .where('City', isEqualTo: locationProvider.cityName)
          .limit(noOf)
          .get();

      for (var productSnap in productsSnap.docs) {
        final productData = productSnap.data();

        final String productName = productData['productName'].toString();
        final List tags = productData['Tags'];
        final String imageUrl = productData['images'][0].toString();
        final String productPrice = productData['productPrice'].toString();
        final String productId = productData['productId'].toString();
        final Map<String, dynamic> ratings = productData['ratings'];
        final Timestamp datetime = productData['datetime'];
        final int views = (productData['productViewsTimestamp'] as List).length;
        final cityName = productData['City'];

        final productNameLower = productName.toLowerCase();
        final searchLower = widget.search.toLowerCase();

        if (cityName == locationProvider.cityName) {
          if (productNameLower.contains(searchLower) ||
              tags.any((tag) =>
                  tag.toString().toLowerCase().contains(searchLower))) {
            int relevanceScore = calculateRelevanceScore(
              productNameLower,
              searchLower,
              tags,
              searchLower,
            );

            searchedProducts[productName] = {
              'imageUrl': imageUrl,
              'productPrice': productPrice,
              'productId': productId,
              'relevanceScore': relevanceScore,
              'ratings': ratings,
              'datetime': datetime,
              'views': views,
            };
            rangeProducts[productName] = {
              'imageUrl': imageUrl,
              'productPrice': productPrice,
              'productId': productId,
              'relevanceScore': relevanceScore,
              'ratings': ratings,
              'datetime': datetime,
              'views': views,
            };
          }
        }
      }
    }

    searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
      ..sort((a, b) =>
          b.value['relevanceScore'].compareTo(a.value['relevanceScore'])));
    rangeProducts = Map.fromEntries(searchedProducts.entries.toList()
      ..sort((a, b) =>
          b.value['relevanceScore'].compareTo(a.value['relevanceScore'])));

    setState(() {
      isProductsData = true;
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

    Map wishlists = productData['productWishlistTimestamp'];

    if (!alreadyInWishlist) {
      wishlists.addAll({
        auth.currentUser!.uid: DateTime.now(),
      });
    } else {
      wishlists.remove(auth.currentUser!.uid);
    }

    await productDoc.update({
      'productWishlistTimestamp': wishlists,
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

  // SORT PRODUCTS
  void sortProducts(EventSorting sorting) {
    setState(() {
      switch (sorting) {
        case EventSorting.recentlyAdded:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
            ..sort((a, b) => (b.value['datetime'] as Timestamp)
                .compareTo(a.value['datetime'])));
          break;
        case EventSorting.highestRated:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
            ..sort((a, b) => calculateAverageRating(b.value['ratings'])
                .compareTo(calculateAverageRating(a.value['ratings']))));
          break;
        case EventSorting.mostViewed:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
            ..sort((a, b) => ((b.value['views'] as List).length)
                .compareTo((a.value['views'] as List).length)));
          break;
        case EventSorting.lowestPrice:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
            ..sort((a, b) => double.parse(a.value['productPrice'])
                .compareTo(double.parse(b.value['productPrice']))));
          break;
        case EventSorting.highestPrice:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
            ..sort((a, b) => double.parse(b.value['productPrice'])
                .compareTo(double.parse(a.value['productPrice']))));
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

  // GET ADDRESS
  Future<String> getAddress(double shopLatitude, double shopLongitude) async {
    const apiKey = 'AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';
    final apiUrl =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$shopLatitude,$shopLongitude&key=$apiKey';

    String? address;
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          address = data['results'][0]['formatted_address'];
        } else {
          if (mounted) {
            mySnackBar('Failed to get address', context);
          }
        }
      } else {
        if (mounted) {
          mySnackBar('Failed to load data', context);
        }
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(e.toString(), context);
      }
    }

    address = address?.isNotEmpty == true ? address : 'No address found';

    return address!.length > 30 ? '${address.substring(0, 30)}...' : address;
  }

  // UPDATE SHOPS
  void updateShops(double endDistance) {
    Map<String, Map<String, dynamic>> tempShops = {};

    rangeShops.clear();

    searchedShops.forEach((key, value) {
      final double distance = value['distance'];
      if (distance * 0.925 <= endDistance) {
        tempShops[key] = value;
      }
    });

    setState(() {
      rangeShops = tempShops;
    });
  }

  // UPDATE PRODUCTS
  void updateProducts(double endDistance) {
    Map<String, Map<String, dynamic>> tempProducts = {};

    rangeProducts.clear();

    searchedProducts.forEach((key, value) {
      final double distance = value['distance'];
      if (distance * 0.925 <= endDistance) {
        tempProducts[key] = value;
      }
    });

    setState(() {
      rangeProducts = tempProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent) {
                    scrollListener();
                  }
                  return false;
                },
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
                                        child: TextField(
                                          minLines: 1,
                                          maxLines: 1,
                                          controller: searchController,
                                          keyboardType: TextInputType.text,
                                          onTapOutside: (event) =>
                                              FocusScope.of(context).unfocus(),
                                          textInputAction:
                                              TextInputAction.search,
                                          onSubmitted: (value) async {
                                            await search();
                                          },
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

                      // SELECT LOCATION
                      Padding(
                        padding: EdgeInsets.all(width * 0.0225),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => LocationChangePage(
                                  page: SearchResultsPage(
                                    search: widget.search,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            locationProvider.cityName == null ||
                                    locationProvider.cityName == 'Your Location'
                                ? 'Your Location▽'
                                : locationProvider.cityName!.length > 15
                                    ? '${locationProvider.cityName!.substring(0, 15)}...▽'
                                    : '${locationProvider.cityName}▽',
                            style: TextStyle(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),

                      // DISTANCE
                      locationProvider.cityName != 'Your Location'
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.only(left: width * 0.025),
                              child: const Text(
                                'Distance (km)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                      // DISTANCE SLIDER
                      locationProvider.cityName != 'Your Location'
                          ? Container()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Slider(
                                    min: 0,
                                    max: 50,
                                    divisions: 20,
                                    value: distanceRange,
                                    activeColor: primaryDark,
                                    inactiveColor:
                                        const Color.fromRGBO(197, 243, 255, 1),
                                    onChanged: (newValue) {
                                      setState(() {
                                        isShopsData = false;
                                        isProductsData = false;
                                        distanceRange = newValue;
                                      });
                                      updateShops(distanceRange);
                                      updateProducts(distanceRange);
                                      setState(() {
                                        isShopsData = true;
                                        isProductsData = true;
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: width * 0.15,
                                  height: width * 0.15,
                                  decoration: const BoxDecoration(
                                    color: primaryDark,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    distanceRange
                                            .toString()
                                            .endsWith('.500000000000004')
                                        ? distanceRange.toString().replaceFirst(
                                            '.500000000000004', '.5')
                                        : distanceRange.toString().endsWith('0')
                                            ? distanceRange
                                                .toString()
                                                .replaceFirst('.0', '')
                                            : distanceRange.toString(),
                                    style: TextStyle(
                                      color: white,
                                      fontSize: width * 0.055,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.01,
                            ),
                            child: ActionChip(
                              label: Text(
                                'Products',
                                style: TextStyle(
                                  color: selected == 'Products'
                                      ? white
                                      : primaryDark,
                                ),
                              ),
                              tooltip: 'See Products',
                              onPressed: () {
                                setState(() {
                                  selected = 'Products';
                                });
                              },
                              backgroundColor: selected == 'Products'
                                  ? primaryDark
                                  : primary2,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.01,
                            ),
                            child: ActionChip(
                              label: Text(
                                'Shops',
                                style: TextStyle(
                                  color:
                                      selected == 'Shops' ? white : primaryDark,
                                ),
                              ),
                              tooltip: 'See Shops',
                              onPressed: () {
                                setState(() {
                                  selected = 'Shops';
                                });
                                if (rangeShops.isEmpty) {
                                  getShops(locationProvider);
                                }
                              },
                              backgroundColor:
                                  selected == 'Shops' ? primaryDark : primary2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // SHOP
                      selected == 'Shops'
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                !isShopsData
                                    ? SizedBox(
                                        width: width,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: 2,
                                          physics:
                                              const ClampingScrollPhysics(),
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
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
                                                            CrossAxisAlignment
                                                                .start,
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
                                    : rangeShops.isEmpty
                                        ? SizedBox(
                                            height: 80,
                                            child: const Center(
                                              child: Text(
                                                'No Shops Found',
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: rangeShops.length > 3
                                                ? 3
                                                : rangeShops.length,
                                            itemBuilder: ((context, index) {
                                              final currentShop = rangeShops
                                                  .keys
                                                  .toList()[index];
                                              final shopData =
                                                  rangeShops[currentShop]!;

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
                                                              vendorId:
                                                                  currentShop,
                                                            )),
                                                      ),
                                                    );
                                                  },
                                                  splashColor: white,
                                                  tileColor: white,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    vertical: width * 0.0125,
                                                    horizontal: width * 0.025,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                  ),
                                                  leading: CircleAvatar(
                                                    backgroundImage:
                                                        NetworkImage(
                                                      shopData['imageUrl'],
                                                    ),
                                                    radius: width * 0.0575,
                                                  ),
                                                  title: Text(
                                                    shopData['name'],
                                                    style: TextStyle(
                                                      fontSize: width * 0.06125,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    shopData['address'],
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                            )

                          // PRODUCT
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // PRODUCTS
                                !isProductsData
                                    ? SkeletonContainer(
                                        width: width * 0.2,
                                        height: 20,
                                      )
                                    : rangeProducts.isEmpty
                                        ? SizedBox(
                                            height: 80,
                                            child: const Center(
                                              child: Text(
                                                'No Products Found',
                                              ),
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              color: primary3,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                12,
                                              ),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.0125,
                                            ),
                                            child: DropdownButton(
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
                                                  .map((e) =>
                                                      DropdownMenuItem<String>(
                                                        value: e,
                                                        child: Text(e),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                sortProducts(
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
                                                  productSort = value;
                                                });
                                              },
                                            ),
                                          ),

                                // PRODUCTS LIST
                                !isProductsData
                                    ? SizedBox(
                                        width: width,
                                        child: GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const ClampingScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            childAspectRatio: 0.825,
                                          ),
                                          itemCount: 6,
                                          itemBuilder: ((context, index) {
                                            return Padding(
                                              padding: EdgeInsets.all(
                                                  width * 0.0225),
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
                                                      MainAxisAlignment
                                                          .spaceAround,
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
                                    : GridView.builder(
                                        controller: scrollController,
                                        cacheExtent: height * 1.5,
                                        addAutomaticKeepAlives: true,
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: width * 0.6 / width,
                                        ),
                                        itemCount: noOf > rangeProducts.length
                                            ? rangeProducts.length
                                            : noOf,
                                        itemBuilder: ((context, index) {
                                          return StreamBuilder<bool>(
                                            stream: getIfWishlist(
                                              rangeProducts.values
                                                  .toList()[index]['productId'],
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
                                                  rangeProducts.keys
                                                      .toList()[isLoadMore
                                                          ? index - 1
                                                          : index]
                                                      .toString();

                                              final image = rangeProducts[
                                                  currentProduct]!['imageUrl'];

                                              final productId = rangeProducts
                                                  .values
                                                  .toList()[index]['productId'];

                                              final ratings = rangeProducts
                                                  .values
                                                  .toList()[index]['ratings'];

                                              final price = rangeProducts[
                                                              currentProduct]![
                                                          'productPrice'] ==
                                                      ''
                                                  ? 'N/A'
                                                  : 'Rs. ${rangeProducts[currentProduct]!['productPrice']}';
                                              final isWishListed =
                                                  snapshot.data ?? false;

                                              return GestureDetector(
                                                onTap: () async {
                                                  final productData =
                                                      await getProductData(
                                                    productId,
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
                                                          productId: productId,
                                                        )),
                                                  );
                                                },
                                                onLongPress: () async {
                                                  await showDialog(
                                                    context: context,
                                                    builder: ((context) =>
                                                        ProductQuickView(
                                                          productId: productId,
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
                                                        alignment:
                                                            Alignment.topRight,
                                                        children: [
                                                          Center(
                                                            child:
                                                                Image.network(
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
                                                                  width *
                                                                      0.0125,
                                                              vertical: width *
                                                                  0.00625,
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
                                                                  width: width *
                                                                      0.3,
                                                                  child: Text(
                                                                    currentProduct,
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          width *
                                                                              0.04125,
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
                                                                            0.04125,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          IconButton(
                                                            onPressed:
                                                                () async {
                                                              await wishlistProduct(
                                                                productId,
                                                              );
                                                            },
                                                            icon: Icon(
                                                              isWishListed
                                                                  ? Icons
                                                                      .favorite
                                                                  : Icons
                                                                      .favorite_border,
                                                              color: Colors.red,
                                                            ),
                                                            color: Colors.red,
                                                            iconSize:
                                                                width * 0.09,
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
