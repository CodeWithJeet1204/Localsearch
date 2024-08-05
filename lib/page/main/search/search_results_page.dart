import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:Localsearch_User/page/main/location_change_page.dart';
import 'package:Localsearch_User/page/main/vendor/product/product_page.dart';
import 'package:Localsearch_User/page/main/vendor/vendor_page.dart';
import 'package:Localsearch_User/providers/location_provider.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/product_quick_view.dart';
import 'package:Localsearch_User/widgets/skeleton_container.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:Localsearch_User/widgets/speech_to_text.dart';
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
  Map searchedShops = {};
  Map searchedProducts = {};
  Map rangeShops = {};
  Map rangeProducts = {};
  bool isShopsData = false;
  bool isProductsData = false;
  String? productSort = 'Recently Added';
  double distanceRange = 5;

  // INIT STATE
  @override
  void initState() {
    setSearch();
    super.initState();
  }

  // DID CHANGE DEPENDENCIES
  @override
  void didChangeDependencies() {
    final locationProvider = Provider.of<LocationProvider>(context);

    getShops(locationProvider);
    getProducts(locationProvider);
    super.didChangeDependencies();
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
    var allShops = {};
    final shopSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .get();

    double? yourLatitude;
    double? yourLongitude;

    // GET LOCATION
    Future<Position?> getLocation() async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          mySnackBar('Turn ON Location Services to Continue', context);
        }
        return null;
      } else {
        LocationPermission permission = await Geolocator.checkPermission();

        // LOCATION PERMISSION GIVEN
        Future<Position> locationPermissionGiven() async {
          return await Geolocator.getCurrentPosition();
        }

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (mounted) {
              mySnackBar('Pls give Location Permission to Continue', context);
            }
          }
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.deniedForever) {
            yourLatitude = 0;
            yourLongitude = 0;
            if (mounted) {
              mySnackBar(
                'Because Location permission is denied, We are continuing without Location',
                context,
              );
            }
          } else {
            return await locationPermissionGiven();
          }
        } else {
          return await locationPermissionGiven();
        }
      }
      return null;
    }

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
      await getLocation().then((value) async {
        if (value != null) {
          setState(() {
            yourLatitude = value.latitude;
            yourLongitude = value.longitude;
          });
        }
      });

      for (var shopSnap in shopSnap.docs) {
        final shopData = shopSnap.data();

        final String name = shopData['Name'];
        final String imageUrl = shopData['Image'];
        final double vendorLatitude = shopData['Latitude'];
        final double vendorLongitude = shopData['Longitude'];
        final String vendorId = shopSnap.id;
        double distance = 0;

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
          allShops[vendorId] = [
            name,
            imageUrl,
            vendorLatitude,
            vendorLongitude,
            distance
          ];
        }
      }
    } else {
      for (var shopSnap in shopSnap.docs) {
        final shopData = shopSnap.data();

        final String name = shopData['Name'];
        final String imageUrl = shopData['Image'];
        final double vendorLatitude = shopData['Latitude'];
        final double vendorLongitude = shopData['Longitude'];
        final String vendorId = shopSnap.id;

        try {
          final url =
              'https://maps.googleapis.com/maps/api/geocode/json?latlng=$vendorLatitude,$vendorLongitude&key=AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';

          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            String? cityName;

            if (data['status'] == 'OK') {
              for (var result in data['results']) {
                for (var component in result['address_components']) {
                  if (component['types'].contains('locality')) {
                    cityName = component['long_name'];
                    break;
                  } else if (component['types'].contains('sublocality')) {
                    cityName = component['long_name'];
                  } else if (component['types'].contains('neighborhood')) {
                    cityName = component['long_name'];
                  } else if (component['types'].contains('route')) {
                    cityName = component['long_name'];
                  } else if (component['types']
                      .contains('administrative_area_level_3')) {
                    cityName = component['long_name'];
                  }
                }
                if (cityName != null) break;
              }

              if (cityName == locationProvider.cityName) {
                allShops[vendorId] = [
                  name,
                  imageUrl,
                  vendorLatitude,
                  vendorLongitude,
                ];
              }
            }
          }
        } catch (e) {
          mySnackBar(
            'Failed to fetch your City: ${e.toString()}',
            context,
          );
        }
      }
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
      rangeShops[entry.key] = allShops[entry.key];
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
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .get();

    double? yourLatitude;
    double? yourLongitude;

    // GET LOCATION
    Future<Position?> getLocation() async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          mySnackBar('Turn ON Location Services to Continue', context);
        }
        return null;
      } else {
        LocationPermission permission = await Geolocator.checkPermission();

        // LOCATION PERMISSION GIVEN
        Future<Position> locationPermissionGiven() async {
          return await Geolocator.getCurrentPosition();
        }

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (mounted) {
              mySnackBar('Pls give Location Permission to Continue', context);
            }
          }
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.deniedForever) {
            yourLatitude = 0;
            yourLongitude = 0;
            if (mounted) {
              mySnackBar(
                'Because Location permission is denied, We are continuing without Location',
                context,
              );
            }
          } else {
            return await locationPermissionGiven();
          }
        } else {
          return await locationPermissionGiven();
        }
      }
      return null;
    }

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
      await getLocation().then((value) async {
        if (value != null) {
          setState(() {
            yourLatitude = value.latitude;
            yourLongitude = value.longitude;
          });
        }
      });

      for (var productSnap in productsSnap.docs) {
        final productData = productSnap.data();

        final String productName = productData['productName'].toString();
        final List tags = productData['Tags'];
        final String imageUrl = productData['images'][0].toString();
        final String productPrice = productData['productPrice'].toString();
        final String productId = productData['productId'].toString();
        final String vendorId = productData['vendorId'].toString();
        final Map<String, dynamic> ratings = productData['ratings'];
        final Timestamp datetime = productData['datetime'];
        final List views = productData['productViewsTimestamp'];
        double distance = 0;

        final vendorSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Shops')
            .doc(vendorId)
            .get();

        final vendorData = vendorSnap.data()!;

        final String vendor = vendorData['Name'];
        final double vendorLatitude = vendorData['Latitude'];
        final double vendorLongitude = vendorData['Longitude'];

        final productNameLower = productName.toLowerCase();
        final searchLower = widget.search.toLowerCase();

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
          if (productNameLower.contains(searchLower) ||
              tags.any((tag) =>
                  tag.toString().toLowerCase().contains(searchLower))) {
            int relevanceScore = calculateRelevanceScore(
              productNameLower,
              searchLower,
              tags,
              searchLower,
            );

            searchedProducts[productName] = [
              imageUrl,
              vendor,
              productPrice,
              productId,
              relevanceScore,
              ratings,
              datetime,
              views,
              distance,
            ];
            rangeProducts[productName] = [
              imageUrl,
              vendor,
              productPrice,
              productId,
              relevanceScore,
              ratings,
              datetime,
              views,
              distance,
            ];
          }
        }
      }
    } else {
      for (var productSnap in productsSnap.docs) {
        final productData = productSnap.data();

        final String productName = productData['productName'].toString();
        final List tags = productData['Tags'];
        final String imageUrl = productData['images'][0].toString();
        final String productPrice = productData['productPrice'].toString();
        final String productId = productData['productId'].toString();
        final String vendorId = productData['vendorId'].toString();
        final Map<String, dynamic> ratings = productData['ratings'];
        final Timestamp datetime = productData['datetime'];
        final int views = productData['productViews'];

        final vendorSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Shops')
            .doc(vendorId)
            .get();

        final vendorData = vendorSnap.data()!;
        final String vendor = vendorData['Name'];
        final vendorLatitude = vendorData['Latitude'];
        final vendorLongitude = vendorData['Longitude'];

        final productNameLower = productName.toLowerCase();
        final searchLower = widget.search.toLowerCase();

        try {
          final url =
              'https://maps.googleapis.com/maps/api/geocode/json?latlng=$vendorLatitude,$vendorLongitude&key=AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';

          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            String? name;

            if (data['status'] == 'OK') {
              for (var result in data['results']) {
                for (var component in result['address_components']) {
                  if (component['types'].contains('locality')) {
                    name = component['long_name'];
                    break;
                  } else if (component['types'].contains('sublocality')) {
                    name = component['long_name'];
                  } else if (component['types'].contains('neighborhood')) {
                    name = component['long_name'];
                  } else if (component['types'].contains('route')) {
                    name = component['long_name'];
                  } else if (component['types']
                      .contains('administrative_area_level_3')) {
                    name = component['long_name'];
                  }
                }
                if (name != null) break;
              }

              if (name == locationProvider.cityName) {
                if (productNameLower.contains(searchLower) ||
                    tags.any((tag) =>
                        tag.toString().toLowerCase().contains(searchLower))) {
                  int relevanceScore = calculateRelevanceScore(
                    productNameLower,
                    searchLower,
                    tags,
                    searchLower,
                  );

                  searchedProducts[productName] = [
                    imageUrl,
                    vendor,
                    productPrice,
                    productId,
                    relevanceScore,
                    ratings,
                    datetime,
                    views,
                  ];
                  rangeProducts[productName] = [
                    imageUrl,
                    vendor,
                    productPrice,
                    productId,
                    relevanceScore,
                    ratings,
                    datetime,
                    views,
                  ];
                }
              }
            }
          }
        } catch (e) {
          mySnackBar(
            'Failed to fetch your City: ${e.toString()}',
            context,
          );
        }
      }
    }

    searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
      ..sort((a, b) => b.value[4].compareTo(a.value[4])));
    rangeProducts = Map.fromEntries(searchedProducts.entries.toList()
      ..sort((a, b) => b.value[4].compareTo(a.value[4])));

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

  // SORT PRODUCTS
  void sortProducts(EventSorting sorting) {
    setState(() {
      switch (sorting) {
        case EventSorting.recentlyAdded:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
            ..sort((a, b) => (b.value[6] as Timestamp).compareTo(a.value[6])));
          break;
        case EventSorting.highestRated:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
            ..sort((a, b) => calculateAverageRating(b.value[5])
                .compareTo(calculateAverageRating(a.value[5]))));
          break;
        case EventSorting.mostViewed:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
            ..sort((a, b) => ((b.value[7] as List).length)
                .compareTo((a.value[7] as List).length)));
          break;
        case EventSorting.lowestPrice:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
            ..sort((a, b) =>
                double.parse(a.value[2]).compareTo(double.parse(b.value[2]))));
          break;
        case EventSorting.highestPrice:
          searchedProducts = Map.fromEntries(searchedProducts.entries.toList()
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
    Map tempShops = {};

    rangeShops.clear();

    searchedShops.forEach((key, value) {
      final double distance = value[4];
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
    Map tempProducts = {};

    rangeProducts.clear();

    searchedProducts.forEach((key, value) {
      final double distance = value[8];
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
    double width = MediaQuery.of(context).size.width;
    final locationProvider = Provider.of<LocationProvider>(context);

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
                                          minLines: 1,
                                          maxLines: 1,
                                          controller: searchController,
                                          keyboardType: TextInputType.text,
                                          onTapOutside: (event) =>
                                              FocusScope.of(context).unfocus(),
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
                                  decoration: BoxDecoration(
                                    color: primaryDark,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(width * 0.035),
                                  child: Text(
                                    distanceRange
                                            .toString()
                                            .endsWith('.500000000000004')
                                        ? distanceRange.toString().replaceFirst(
                                            '.500000000000004', '')
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

                      // SHOP
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SHOPS
                          !isShopsData
                              ? SkeletonContainer(
                                  width: width * 0.2,
                                  height: 20,
                                )
                              : rangeShops.isEmpty
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
                          !isShopsData
                              ? SizedBox(
                                  width: width,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: 2,
                                    physics: ClampingScrollPhysics(),
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
                              : rangeShops.isEmpty
                                  ? rangeProducts.isEmpty
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
                                      itemCount: rangeShops.length > 3
                                          ? 3
                                          : rangeShops.length,
                                      itemBuilder: ((context, index) {
                                        final currentShop =
                                            rangeShops.keys.toList()[index];

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
                                                rangeShops[currentShop][1],
                                              ),
                                              radius: width * 0.0575,
                                            ),
                                            title: Text(
                                              rangeShops[currentShop][0],
                                              style: TextStyle(
                                                fontSize: width * 0.06125,
                                              ),
                                            ),
                                            subtitle: FutureBuilder(
                                                future: getAddress(
                                                  rangeShops[currentShop][2],
                                                  rangeShops[currentShop][3],
                                                ),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasError) {
                                                    return Container();
                                                  }

                                                  if (snapshot.hasData) {
                                                    return Text(
                                                      snapshot.data!,
                                                    );
                                                  }

                                                  return Container();
                                                }),
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
                      Column(
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
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 40),
                                        child: Text(
                                          'No Products Found',
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
                                            'Products',
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
                                        ],
                                      ),
                                    ),

                          // PRODUCTS LIST
                          !isProductsData
                              ? SizedBox(
                                  width: width,
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
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
                              : rangeProducts.isEmpty
                                  ? Container()
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: width * 0.6 / width,
                                      ),
                                      itemCount: rangeProducts.length,
                                      itemBuilder: ((context, index) {
                                        return StreamBuilder<bool>(
                                          stream: getIfWishlist(
                                            rangeProducts.values.toList()[index]
                                                [3],
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              return const Center(
                                                child: Text(
                                                  'Something went wrong',
                                                ),
                                              );
                                            }

                                            final currentProduct = rangeProducts
                                                .keys
                                                .toList()[index]
                                                .toString();

                                            final image =
                                                rangeProducts[currentProduct]
                                                    [0];

                                            final productId = rangeProducts
                                                .values
                                                .toList()[index][3];

                                            final ratings = rangeProducts.values
                                                .toList()[index][5];

                                            final price = rangeProducts[
                                                        currentProduct][2] ==
                                                    ''
                                                ? 'N/A'
                                                : 'Rs. ${rangeProducts[currentProduct][2]}';
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
                                                                  currentProduct,
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
                                                                productId);
                                                          },
                                                          icon: Icon(
                                                            isWishListed
                                                                ? Icons.favorite
                                                                : Icons
                                                                    .favorite_border,
                                                            color: Colors.red,
                                                          ),
                                                          color: Colors.red,
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
