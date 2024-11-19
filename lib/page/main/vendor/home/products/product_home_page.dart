// ignore_for_file: avoid_function_literals_in_foreach_calls, unused_local_variable, empty_catches
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:localsearch/page/main/exhibition_page.dart';
import 'package:localsearch/page/main/vendor/status_page_view.dart';
import 'package:localsearch/page/main/vendor/profile/wishlist_page.dart';
import 'package:localsearch/widgets/text_button.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localsearch/page/main/vendor/discount/all_discount_page.dart';
import 'package:localsearch/page/main/location_change_page.dart';
import 'package:localsearch/page/main/main_page.dart';
import 'package:localsearch/page/main/vendor/category/all_shop_types_page.dart';
import 'package:localsearch/page/main/vendor/home/products/shop_categories_page.dart';
import 'package:localsearch/page/main/vendor/product/product_page.dart';
import 'package:localsearch/page/main/search/search_page.dart';
import 'package:localsearch/page/main/vendor/vendor_page.dart';
import 'package:localsearch/providers/location_provider.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:localsearch/widgets/video_tutorial.dart';
import 'package:provider/provider.dart';

class ProductHomePage extends StatefulWidget {
  const ProductHomePage({
    super.key,
  });

  @override
  State<ProductHomePage> createState() => _ProductHomePageState();
}

class _ProductHomePageState extends State<ProductHomePage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  String? name;
  String? recentShop;
  int exhibitionIndex = 0;
  Map<String, dynamic>? shopTypesData;
  Map<String, Map<String, dynamic>> recentShopProducts = {};
  Map<String, dynamic> allWishlist = {};
  Map<String, dynamic> currentWishlist = {};
  Map<String, dynamic> allFollowedShops = {};
  Map<String, dynamic> currentFollowedShops = {};
  Map<String, Map<String, dynamic>> exhibitions = {};
  Map<String, Map<String, dynamic>> status = {};
  Map<String, Map<String, dynamic>> featured1 = {};
  Map<String, Map<String, dynamic>> featured2 = {};
  Map<String, Map<String, dynamic>> featured3 = {};
  String? featuredCategory1;
  String? featuredCategory2;
  String? featuredCategory3;
  bool getWishlistData = false;
  bool getFollowedData = false;
  bool isStatusData = false;
  double distanceRange = 5;
  // int noOf1 = 4;
  // int noOf2 = 4;
  // int noOf3 = 4;
  // int? total1;
  // int? total2;
  // int? total3;
  // bool isLoadMore1 = false;
  // bool isLoadMore2 = false;
  // bool isLoadMore3 = false;
  // final scrollController1 = ScrollController();
  // final scrollController2 = ScrollController();
  // final scrollController3 = ScrollController();

  // INIT STATE
  @override
  void initState() {
    // getTotal();
    // scrollController1.addListener(scrollListener1);
    // scrollController2.addListener(scrollListener2);
    // scrollController3.addListener(scrollListener3);
    getData(false);
    super.initState();
  }

  // GET DATA
  Future<void> getData(bool fromRefreshIndicator) async {
    Map<String, dynamic> userData = {};

    if (auth.currentUser != null) {
      final userSnap =
          await store.collection('Users').doc(auth.currentUser!.uid).get();

      userData = userSnap.data()!;
    }

    final locationProvider = Provider.of<LocationProvider>(
      // ignore: use_build_context_synchronously
      context,
      listen: false,
    );

    // GET NAME
    Future<void> getName() async {
      String myName = userData['Name'].toString().trim();
      List<String> myNameList = myName.split(' ');
      String newCapitalName = '';
      for (var myName in myNameList) {
        newCapitalName =
            '$newCapitalName${myName.substring(0, 1).toUpperCase()}${myName.substring(1)} ';
      }

      if (mounted) {
        setState(() {
          name = newCapitalName;
        });
      }
    }

    // GET EXHIBITIONS
    Future<void> getExhibitions() async {
      final exhibitionSnap = auth.currentUser == null
          ? await store.collection('Exhibitions').get()
          : await store
              .collection('Exhibitions')
              .where('City', isEqualTo: userData['City'])
              .get();

      for (var exhibition in exhibitionSnap.docs) {
        final exhibitionData = exhibition.data();

        final String exhibitionId = exhibition.id;
        final Timestamp startDate = exhibitionData['startDate'];
        final Timestamp endDate = exhibitionData['endDate'];

        if (endDate.toDate().isAfter(DateTime.now())) {
          exhibitions[exhibitionId] = exhibitionData;
        }
      }
    }

    // GET STATUS
    Future<void> getStatus() async {
      Map<String, Map<String, dynamic>> myStatus = {};
      List<String> followedShops = [];

      try {
        if (auth.currentUser != null) {
          final userSnap =
              await store.collection('Users').doc(auth.currentUser!.uid).get();
          followedShops =
              List<String>.from(userSnap.data()?['followedShops'] ?? []);
        }

        final statusSnap = await store
            .collection('Business')
            .doc('Data')
            .collection('Status')
            .get();

        for (var status in statusSnap.docs) {
          final statusData = status.data();
          final String statusId = status.id;
          final String vendorId = statusData['statusVendorId'];
          final String statusText = statusData['statusText']?.toString() ?? '';
          final List statusImage = statusData['statusImage'] ?? [];

          if (myStatus.containsKey(vendorId)) {
            myStatus[vendorId]!['status']![statusId] = {
              'statusText': statusText,
              'statusImage': statusImage,
            };
          } else {
            final vendorSnap = await store
                .collection('Business')
                .doc('Owners')
                .collection('Shops')
                .doc(vendorId)
                .get();

            final vendorData = vendorSnap.data();
            if (vendorData != null) {
              myStatus[vendorId] = {
                'vendorName': vendorData['Name'] ?? '',
                'vendorImageUrl': vendorData['Image'] ?? '',
                'isFollowed': followedShops.contains(vendorId),
                'status': {
                  statusId: {
                    'statusText': statusText,
                    'statusImage': statusImage,
                  },
                },
              };
            }
          }
        }

        final sortedEntries = myStatus.entries.toList()
          ..sort((a, b) {
            final bool aIsFollowed = a.value['isFollowed'] as bool;
            final bool bIsFollowed = b.value['isFollowed'] as bool;

            return (bIsFollowed ? 1 : 0).compareTo(aIsFollowed ? 1 : 0);
          });

        myStatus = Map<String, Map<String, dynamic>>.fromEntries(sortedEntries);

        if (mounted) {
          setState(() {
            status = myStatus;
            isStatusData = true;
          });
        }
      } catch (e) {
        log('Error fetching statuses: $e');
      }
    }

    // GET SHOP TYPES
    Future<void> getShopTypes() async {
      final shopTypesSnap = await store
          .collection('Shop Types And Category Data')
          .doc('Shop Types Data')
          .get();

      final shopTypeData = shopTypesSnap.data()!;

      final Map<String, dynamic> myShopTypesData =
          shopTypeData['shopTypesData'];

      final sortedEntries = myShopTypesData.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final sortedShopTypesData =
          Map<String, dynamic>.fromEntries(sortedEntries);

      if (mounted) {
        setState(() {
          shopTypesData = sortedShopTypesData;
        });
      }
    }

    // GET RECENT SHOP
    Future<void> getRecentShop() async {
      final myRecentShop = userData['recentShop'];
      Map<String, Map<String, dynamic>> myRecentShopProducts = {};

      if (myRecentShop != '') {
        try {
          final productSnap = await store
              .collection('Business')
              .doc('Data')
              .collection('Products')
              .where('vendorId', isEqualTo: myRecentShop)
              .get();

          for (var product in productSnap.docs) {
            final productData = product.data();
            final productId = product.id;

            myRecentShopProducts[productId] = productData;
          }

          var sortedEntries = myRecentShopProducts.entries.toList();

          sortedEntries.sort((a, b) {
            List<dynamic> aViews = a.value['productViewsTimestamp'];
            List<dynamic> bViews = b.value['productViewsTimestamp'];
            return bViews.length.compareTo(aViews.length);
          });

          myRecentShopProducts =
              Map<String, Map<String, dynamic>>.fromEntries(sortedEntries);
          if (mounted) {
            setState(() {
              recentShop = myRecentShop;
              recentShopProducts = myRecentShopProducts;
            });
          }
        } catch (e) {
          if (mounted) {
            mySnackBar('Some error occured: ${e.toString()}', context);
          }
        }
      }
    }

    // GET WISHLIST
    Future<void> getWishlist() async {
      Map<String, List> myWishlist = {};

      final List wishlists = userData['wishlists'];

      double? yourLatitude;
      double? yourLongitude;

      await Future.wait(
        wishlists.map((productId) async {
          final productSnap = await store
              .collection('Business')
              .doc('Data')
              .collection('Products')
              .doc(productId)
              .get();

          final productData = productSnap.data()!;
          final String productName = productData['productName'];
          final String imageUrl = productData['images'][0];
          final String vendorId = productData['vendorId'];
          final String productCity = productData['City'];
          final double productLatitude = productData['Latitude'];
          final double productLongitude = productData['Longitude'];

          if (locationProvider.cityName == 'Your Location') {
            if (mounted) {
              setState(() {
                yourLatitude = locationProvider.cityLatitude;
                yourLongitude = locationProvider.cityLongitude;
              });
            }
            try {
              final dist = await getDrivingDistance(
                yourLatitude!,
                yourLongitude!,
                productLatitude,
                productLongitude,
              );

              if (dist != null) {
                allWishlist[productId] = [
                  productName,
                  imageUrl,
                  productData,
                  dist,
                ];
                if (dist < 5) {
                  currentWishlist[productId] = [
                    productName,
                    imageUrl,
                    productData,
                    dist,
                  ];
                }
              }
            } catch (e) {
              if (mounted) {
                mySnackBar(
                  'Some error occurred: ${e.toString()}',
                  context,
                );
              }
            }
          } else {
            if (productCity == locationProvider.cityName) {
              currentWishlist[productId] = [
                productName,
                imageUrl,
                productData,
              ];
            }
          }
        }),
      );

      if (mounted) {
        setState(() {
          getWishlistData = true;
        });
      }
    }

    // GET FOLLOWED SHOPS
    Future<void> getFollowedShops() async {
      Map<String, List> myFollowedShops = {};

      final List followedShop = userData['followedShops'];

      double? yourLatitude;
      double? yourLongitude;

      if (locationProvider.cityName == 'Your Location') {
        if (mounted) {
          setState(() {
            yourLatitude = locationProvider.cityLatitude;
            yourLongitude = locationProvider.cityLongitude;
          });
        }

        await Future.wait(
          followedShop.map((vendorId) async {
            final vendorSnap = await store
                .collection('Business')
                .doc('Owners')
                .collection('Shops')
                .doc(vendorId)
                .get();

            final vendorData = vendorSnap.data()!;
            final vendorLatitude = vendorData['Latitude'];
            final vendorLongitude = vendorData['Longitude'];

            try {
              final dist = await getDrivingDistance(
                yourLatitude!,
                yourLongitude!,
                vendorLatitude,
                vendorLongitude,
              );

              if (dist != null) {
                final String? name = vendorData['Name'];
                final String? imageUrl = vendorData['Image'];
                allFollowedShops[vendorId] = [name, imageUrl, dist];
                if (dist < 5) {
                  currentFollowedShops[vendorId] = [name, imageUrl, dist];
                }
              }
            } catch (e) {
              if (mounted) {
                mySnackBar(
                  'Some error occurred while finding distance',
                  context,
                );
              }
            }
          }),
        );
      } else {
        await Future.wait(
          followedShop.map((vendorId) async {
            final vendorSnap = await store
                .collection('Business')
                .doc('Owners')
                .collection('Shops')
                .doc(vendorId)
                .get();

            final vendorData = vendorSnap.data()!;
            final vendorLatitude = vendorData['Latitude'];
            final vendorLongitude = vendorData['Longitude'];

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
                      } else if (component['types'].contains('sublocality') ||
                          component['types'].contains('neighborhood') ||
                          component['types'].contains('route') ||
                          component['types']
                              .contains('administrative_area_level_3')) {
                        cityName = component['long_name'];
                      }
                    }
                    if (cityName != null) break;
                  }

                  if (cityName == locationProvider.cityName) {
                    final String? name = vendorData['Name'];
                    final String? imageUrl = vendorData['Image'];
                    allFollowedShops[vendorId] = [name, imageUrl];
                    currentFollowedShops[vendorId] = [name, imageUrl];
                  }
                }
              } else {
                if (mounted) {
                  mySnackBar(
                      'Error fetching location data: ${response.reasonPhrase}',
                      context);
                }
              }
            } catch (e) {
              if (mounted) {
                mySnackBar(
                    'Failed to fetch your City: ${e.toString()}', context);
              }
            }
          }),
        );
      }

      if (mounted) {
        setState(() {
          getFollowedData = true;
        });
      }
    }

    // GET FEATURED
    Future<void> getFeatured() async {
      Map<String, Map<String, dynamic>> myFeatured1 = {};
      Map<String, Map<String, dynamic>> myFeatured2 = {};
      Map<String, Map<String, dynamic>> myFeatured3 = {};

      final featuredSnap =
          await store.collection('Featured').doc('Vendor').get();

      final featuredData = featuredSnap.data()!;

      final category1 = featuredData['category1'];
      final category2 = featuredData['category2'];
      final category3 = featuredData['category3'];

      final productSnap1 = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .where('categoryName', isEqualTo: category1)
          // .limit(noOf1)
          .get();

      productSnap1.docs.forEach((product1) {
        final productId1 = product1.id;

        final productData1 = product1.data();

        myFeatured1.addAll({
          productId1: productData1,
        });
      });

      final productSnap2 = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .where('categoryName', isEqualTo: category2)
          // .limit(noOf2)
          .get();

      productSnap2.docs.forEach((product2) {
        final productId2 = product2.id;

        final productData2 = product2.data();

        myFeatured2.addAll({
          productId2: productData2,
        });
      });

      final productSnap3 = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .where('categoryName', isEqualTo: category3)
          // .limit(noOf3)
          .get();

      productSnap3.docs.forEach((product3) {
        final productId3 = product3.id;

        final productData3 = product3.data();

        myFeatured3.addAll({
          productId3: productData3,
        });
      });

      if (mounted) {
        setState(() {
          featured1 = myFeatured1;
          featured2 = myFeatured2;
          featured3 = myFeatured3;
          featuredCategory1 = category1;
          featuredCategory2 = category2;
          featuredCategory3 = category3;
        });
      }
    }

    if (mounted) {
      if (auth.currentUser != null) {
        try {
          await getName();
        } catch (e) {}
      }
      try {
        await getExhibitions();
      } catch (e) {}
      try {
        await getStatus();
      } catch (e) {}
      try {
        await getShopTypes();
      } catch (e) {}
      if (auth.currentUser != null) {
        try {
          await getRecentShop();
        } catch (e) {}
        try {
          await getWishlist();
        } catch (e) {}
        try {
          await getFollowedShops();
        } catch (e) {}
      }
      try {
        await getFeatured();
      } catch (e) {}
    }
  }

  // // SCROLL LISTENER 1
  // Future<void> scrollListener1() async {
  //   Future<void> getFeatured1() async {
  //     Map<String, Map<String, dynamic>> myFeatured1 = {};
  //     final featuredSnap1 =
  //         await store.collection('Featured').doc('Vendor').get();
  //     final featuredData1 = featuredSnap1.data()!;
  //     final category1 = featuredData1['category1'];
  //     final productSnap1 = await store
  //         .collection('Business')
  //         .doc('Data')
  //         .collection('Products')
  //         .where('categoryName', isEqualTo: category1)
  //         .limit(noOf1)
  //         .get();
  //     productSnap1.docs.forEach((product1) {
  //       final productId1 = product1.id;
  //       final productData1 = product1.data();
  //       myFeatured1.addAll({
  //         productId1: productData1,
  //       });
  //     });
  //     setState(() {
  //       featured1 = myFeatured1;
  //     });
  //   }
  //   if (total1 != null && noOf1 < total1!) {
  //     if (scrollController1.position.pixels ==
  //         scrollController1.position.maxScrollExtent) {
  //       setState(() {
  //         isLoadMore1 = true;
  //       });
  //       noOf1 = noOf1 + 4;
  //       await getFeatured1();
  //       setState(() {
  //         isLoadMore1 = false;
  //       });
  //     }
  //   }
  // }

  // // SCROLL LISTENER 2
  // Future<void> scrollListener2() async {
  //   Future<void> getFeatured2() async {
  //     Map<String, Map<String, dynamic>> myFeatured2 = {};
  //     final featuredSnap2 =
  //         await store.collection('Featured').doc('Vendor').get();
  //     final featuredData2 = featuredSnap2.data()!;
  //     final category2 = featuredData2['category2'];
  //     final productSnap2 = await store
  //         .collection('Business')
  //         .doc('Data')
  //         .collection('Products')
  //         .where('categoryName', isEqualTo: category2)
  //         .limit(noOf2)
  //         .get();
  //     productSnap2.docs.forEach((product2) {
  //       final productId2 = product2.id;
  //       final productData2 = product2.data();
  //       myFeatured2.addAll({
  //         productId2: productData2,
  //       });
  //     });
  //     setState(() {
  //       featured2 = myFeatured2;
  //     });
  //   }
  //   if (total2 != null && noOf2 < total2!) {
  //     if (scrollController2.position.pixels ==
  //         scrollController2.position.maxScrollExtent) {
  //       setState(() {
  //         isLoadMore2 = true;
  //       });
  //       noOf2 = noOf2 + 4;
  //       await getFeatured2();
  //       setState(() {
  //         isLoadMore2 = false;
  //       });
  //     }
  //   }
  // }

  // // SCROLL LISTENER 3
  // Future<void> scrollListener3() async {
  //   Future<void> getFeatured3() async {
  //     Map<String, Map<String, dynamic>> myFeatured3 = {};
  //     final featuredSnap3 =
  //         await store.collection('Featured').doc('Vendor').get();
  //     final featuredData3 = featuredSnap3.data()!;
  //     final category3 = featuredData3['category3'];
  //     final productSnap3 = await store
  //         .collection('Business')
  //         .doc('Data')
  //         .collection('Products')
  //         .where('categoryName', isEqualTo: category3)
  //         .limit(noOf3)
  //         .get();
  //     productSnap3.docs.forEach((product3) {
  //       final productId3 = product3.id;
  //       final productData3 = product3.data();
  //       myFeatured3.addAll({
  //         productId3: productData3,
  //       });
  //     });
  //     setState(() {
  //       featured3 = myFeatured3;
  //     });
  //   }
  //   if (total3 != null && noOf3 < total3!) {
  //     if (scrollController3.position.pixels ==
  //         scrollController3.position.maxScrollExtent) {
  //       setState(() {
  //         isLoadMore3 = true;
  //       });
  //       noOf3 = noOf3 + 1;
  //       await getFeatured3();
  //       setState(() {
  //         isLoadMore3 = false;
  //       });
  //     }
  //   }
  // }

  // GET DISTANCE
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
        if (data['rows'].isNotEmpty && data['rows'][0]['elements'].isNotEmpty) {
          final distance = data['rows'][0]['elements'][0]['distance']['value'];
          return distance / 1000;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // UPDATE WISHLIST
  void updateWishlist(double endDistance) {
    Map<String, dynamic> tempWishlist = {};

    allWishlist.forEach((key, value) {
      final double distance = value[3];
      if (distance * 0.925 <= endDistance) {
        tempWishlist[key] = value;
      }
    });
    if (mounted) {
      setState(() {
        currentWishlist = tempWishlist;
      });
    }
  }

  // UPDATE FOLLOWED
  void updateFollowed(double endDistance) {
    Map<String, dynamic> tempFollowed = {};
    allFollowedShops.forEach((key, value) {
      final double distance = value[2];
      if (distance * 0.925 <= endDistance) {
        tempFollowed[key] = value;
      }
    });
    if (mounted) {
      setState(() {
        currentFollowedShops = tempFollowed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            auth.currentUser == null
                ? Text(
                    'Hi',
                    style: TextStyle(
                      fontSize: width * 0.0575,
                      color: primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hi, ',
                          style: TextStyle(
                            fontSize: width * 0.0575,
                            color: primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: name == null ? '' : name!.toString().trim(),
                          style: TextStyle(
                            fontSize: width * 0.06,
                            color: const Color.fromRGBO(52, 127, 255, 1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

            // SELECT LOCATION
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LocationChangePage(
                      page: MainPage(),
                    ),
                  ),
                );
              },
              child: Text(
                locationProvider.cityName == null
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
            const SizedBox(height: 4),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await showYouTubePlayerDialog(
                context,
                getYoutubeVideoId(
                  '',
                ),
              );
            },
            icon: const Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: 'Help',
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.0125,
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              await getData(true);
            },
            color: primaryDark,
            backgroundColor: const Color.fromARGB(255, 243, 253, 255),
            semanticsLabel: 'Refresh',
            child: LayoutBuilder(
              builder: ((context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEARCH
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.0125,
                          vertical: width * 0.0125,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: ((context) => const SearchPage()),
                              ),
                            );
                          },
                          splashColor: white,
                          customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            width: width,
                            height: width * 0.15,
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.05,
                            ),
                            decoration: BoxDecoration(
                              color: primary2.withOpacity(0.1),
                              border: Border.all(
                                color: primaryDark.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Search...',
                                  style: TextStyle(
                                    color: primaryDark2.withOpacity(0.8),
                                    fontSize: width * 0.045,
                                  ),
                                ),
                                Icon(
                                  FeatherIcons.search,
                                  color: primaryDark2.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // EXHIBITION
                      exhibitions.isEmpty
                          ? Container()
                          : Builder(
                              builder: (context) {
                                final exhibitionId =
                                    exhibitions.keys.toList()[0];
                                final exhibitionData =
                                    exhibitions.values.toList()[0];
                                final exhibitionName = exhibitionData['Name'];
                                final exhibitionVenue = exhibitionData['Venue'];
                                final List exhibitionImages =
                                    exhibitionData['Images'].length >= 4
                                        ? exhibitionData['Images'].sublist(0, 4)
                                        : exhibitionData['Images'];

                                return AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Container(
                                    margin: EdgeInsets.all(width * 0.006125),
                                    child: CarouselSlider(
                                      items: (exhibitionImages)
                                          .map(
                                            (image) => GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ExhibitionPage(
                                                      exhibitionId:
                                                          exhibitionId,
                                                      exhibitionName:
                                                          exhibitionName,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Image.network(
                                                image,
                                                width: width,
                                                height: width,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  } else {
                                                    return SizedBox(
                                                      width: width,
                                                      height: width,
                                                      child: Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      options: CarouselOptions(
                                        enableInfiniteScroll:
                                            exhibitionImages.length > 1
                                                ? true
                                                : false,
                                        viewportFraction: 1,
                                        aspectRatio: 0.7875,
                                        enlargeCenterPage: false,
                                        onPageChanged: (index, reason) {
                                          setState(() {
                                            exhibitionIndex = index;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                      exhibitions.isEmpty ? Container() : Divider(),

                      // STATUS
                      !isStatusData
                          ? /*SizedBox(
                              width: width,
                              height: width * 0.3,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: 6,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.025,
                                    ),
                                    child: SkeletonContainer(
                                      width: width * 0.2,
                                      height: width * 0.3,
                                    ),
                                  );
                                },
                              ),
                            )*/
                          Container()
                          : status.isEmpty
                              ? Container()
                              : Container(
                                  width: width,
                                  height: width * 0.3,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: status.length >= 10
                                        ? 10
                                        : status.length,
                                    itemBuilder: (context, index) {
                                      final String vendorId =
                                          status.keys.toList()[index];
                                      final String vendorName = status.values
                                          .toList()[index]['vendorName'];
                                      final String vendorImageUrl =
                                          status.values.toList()[index]
                                              ['vendorImageUrl'];
                                      // final bool isViewed =
                                      //     (status[vendorId]!['status'] as Map<
                                      //             String, Map<String, dynamic>>)
                                      //         .values
                                      //         .every(
                                      //           (status) =>
                                      //               status['isViewed'] == true,
                                      //         );

                                      /*index != (status.length - 1)
                                      ?*/
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.025,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            log(status.toString());
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    StatusPageView(
                                                  vendorId: vendorId,
                                                  status: status,
                                                ),
                                              ),
                                            );
                                          },
                                          child: SizedBox(
                                            width: width * 0.2,
                                            height: width * 0.3,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Opacity(
                                                  // opacity: isViewed ? 0.75 : 1,
                                                  opacity: 1,
                                                  child: Container(
                                                    width: width * 0.2,
                                                    height: width * 0.2,
                                                    decoration: BoxDecoration(
                                                      color: primary2,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        width: 2,
                                                        color: primaryDark2,
                                                      ),
                                                    ),
                                                    padding: EdgeInsets.all(
                                                      width * 0.00306125,
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        100,
                                                      ),
                                                      child: Image.network(
                                                        vendorImageUrl
                                                            .toString()
                                                            .trim(),
                                                        width: width * 0.2,
                                                        height: width * 0.2,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: width * 0.2,
                                                  child: AutoSizeText(
                                                    vendorName
                                                        .toString()
                                                        .trim(),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      // fontWeight: isViewed
                                                      //     ? FontWeight.w400
                                                      //     : FontWeight.w500,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                      locationProvider.cityName != 'Your Location'
                          ? Container()
                          : const Divider(),

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
                                      if (mounted) {
                                        setState(() {
                                          getWishlistData = false;
                                          getFollowedData = false;
                                          distanceRange = newValue;
                                        });
                                      }
                                      updateWishlist(newValue);
                                      updateFollowed(newValue);
                                      // updateDiscounts(
                                      //   newValue,
                                      //   locationProvider,
                                      // );
                                      if (mounted) {
                                        setState(() {
                                          getWishlistData = true;
                                          getFollowedData = true;
                                        });
                                      }
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

                      // ONGOING DISCOUNTS
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AllDiscountPage(),
                            ),
                          );
                        },
                        child: Container(
                          width: width,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade300,
                                Colors.orange.shade300,
                                Colors.yellow.shade300,
                                Colors.green.shade300,
                                Colors.blue.shade300,
                                Colors.indigo.shade300,
                                const Color.fromRGBO(143, 30, 255, 1),
                              ],
                            ),
                            border: Border.all(
                              width: 1,
                              color: primaryDark,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          margin: EdgeInsets.symmetric(
                            horizontal: width * 0.0125,
                            vertical: 4,
                          ),
                          child: Text(
                            'ONGOING OFFERS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryDark,
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),

                      // SHOP TYPES
                      shopTypesData == null
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.025,
                                vertical: width * 0.025,
                              ),
                              child: Text(
                                'Shop Types',
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.0675,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                      // SHOP TYPES BOX
                      shopTypesData == null
                          ? Container()
                          : Container(
                              width: width,
                              height: width * 0.65,
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
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: width,
                                    height: width * 0.3,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 4,
                                      itemBuilder: ((context, index) {
                                        final String name =
                                            shopTypesData!.keys.toList()[index];
                                        final String imageUrl = shopTypesData!
                                            .values
                                            .toList()[index];

                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.025,
                                            vertical: width * 0.015,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ShopCategoriesPage(
                                                    shopType: name,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: width * 0.2,
                                              height: width * 0.25,
                                              decoration: BoxDecoration(
                                                color: white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.0125,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageUrl: imageUrl
                                                          .toString()
                                                          .trim(),
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            12,
                                                          ),
                                                          child: Image.network(
                                                            imageUrl
                                                                .toString()
                                                                .trim(),
                                                            width:
                                                                width * 0.175,
                                                            height:
                                                                width * 0.175,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    Text(
                                                      name.toString().trim(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: primaryDark,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: width * 0.725,
                                        height: width * 0.3,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          scrollDirection: Axis.horizontal,
                                          itemCount: 3,
                                          itemBuilder: ((context, index) {
                                            final String name = shopTypesData!
                                                .keys
                                                .toList()[index + 4];
                                            final String imageUrl =
                                                shopTypesData!.values
                                                    .toList()[index + 4];

                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.025,
                                                vertical: width * 0.015,
                                              ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ShopCategoriesPage(
                                                        shopType: name,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  width: width * 0.2,
                                                  height: width * 0.25,
                                                  decoration: BoxDecoration(
                                                    color: white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          width * 0.0125,
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        CachedNetworkImage(
                                                          imageUrl: imageUrl
                                                              .toString()
                                                              .trim(),
                                                          imageBuilder: (context,
                                                              imageProvider) {
                                                            return ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                12,
                                                              ),
                                                              child:
                                                                  Image.network(
                                                                imageUrl
                                                                    .toString()
                                                                    .trim(),
                                                                width: width *
                                                                    0.175,
                                                                height: width *
                                                                    0.175,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        Text(
                                                          name
                                                              .toString()
                                                              .trim(),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            color: primaryDark,
                                                            fontWeight:
                                                                FontWeight.w500,
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

                                      // SEE ALL
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) =>
                                                  AllShopTypesPage(
                                                    shopTypesData:
                                                        shopTypesData!,
                                                  )),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: width * 0.225,
                                          height: width * 0.25,
                                          decoration: BoxDecoration(
                                            color: white,
                                            border: Border.all(
                                              width: 0.125,
                                              color: primaryDark,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                FeatherIcons.grid,
                                                color: primaryDark,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'See All',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                      // status.length < 2 ? Container() : Divider(),

                      recentShopProducts.isEmpty ? Container() : Divider(),

                      // CONTINUE SHOPPING
                      recentShopProducts.isEmpty
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.025,
                                vertical: width * 0.025,
                              ),
                              child: Text(
                                'Continue Shopping',
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.06,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                      // CONTINUE SHOPPING PRODUCTS
                      recentShopProducts.isEmpty
                          ? Container()
                          : Container(
                              width: width,
                              height: width * 0.45,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: recentShopProducts.length > 4
                                    ? 4
                                    : recentShopProducts.length,
                                itemBuilder: ((context, index) {
                                  final String name = recentShopProducts.values
                                      .toList()[index]['productName'];
                                  final String imageUrl =
                                      recentShopProducts.values.toList()[index]
                                          ['images'][0];

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProductPage(
                                            productData: recentShopProducts
                                                .values
                                                .toList()[index],
                                          ),
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
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      padding: EdgeInsets.all(
                                        width * 0.00625,
                                      ),
                                      margin: EdgeInsets.all(
                                        width * 0.0125,
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
                                              imageUrl.toString().trim(),
                                              width: width * 0.3,
                                              height: width * 0.3,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: width * 0.00625,
                                              left: width * 0.0125,
                                            ),
                                            child: Text(
                                              name.toString().trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: width * 0.04125,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                      currentWishlist.isEmpty ? Container() : Divider(),

                      // WISHLIST
                      currentWishlist.isEmpty
                          ? Container()
                          : !getWishlistData
                              ? /*Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: SkeletonContainer(
                                    width: width * 0.6,
                                    height: 32,
                                  ),
                                )*/
                              Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.025,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Your Wishlists ❤️',
                                        style: TextStyle(
                                          color: primaryDark,
                                          fontSize: width * 0.06,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      MyTextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  WishlistPage(),
                                            ),
                                          );
                                        },
                                        text: 'See All',
                                        textColor: primaryDark,
                                      ),
                                    ],
                                  ),
                                ),

                      // WISHLIST PRODUCTS
                      currentWishlist.isEmpty
                          ? Container()
                          : !getWishlistData
                              ? /*SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 4,
                                    itemBuilder: ((context, index) {
                                      return Padding(
                                        padding: EdgeInsets.all(width * 0.0225),
                                        child: Container(
                                          width: width * 0.28,
                                          height: width * 0.4,
                                          decoration: BoxDecoration(
                                            color: lightGrey,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SkeletonContainer(
                                                width: width * 0.25,
                                                height: width * 0.275,
                                              ),
                                              SkeletonContainer(
                                                width: width * 0.225,
                                                height: width * 0.033,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                )*/
                              Container()
                              : SizedBox(
                                  width: width,
                                  height: width * 0.45,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: currentWishlist.length > 4
                                        ? 4
                                        : currentWishlist.length,
                                    itemBuilder: ((context, index) {
                                      final String name = currentWishlist.values
                                          .toList()[index][0];
                                      final String imageUrl =
                                          currentWishlist.values.toList()[index]
                                              [1];
                                      final Map<String, dynamic> productData =
                                          currentWishlist.values.toList()[index]
                                              [2];

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) =>
                                                  ProductPage(
                                                    productData: productData,
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
                                          margin: EdgeInsets.all(
                                            width * 0.0125,
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
                                                  imageUrl.toString().trim(),
                                                  width: width * 0.3,
                                                  height: width * 0.3,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: width * 0.00625,
                                                  left: width * 0.0125,
                                                ),
                                                child: Text(
                                                  name.toString().trim(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: width * 0.04125,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                      currentFollowedShops.isEmpty
                          ? Container()
                          : const Divider(),

                      // FOLLOWED
                      currentFollowedShops.isEmpty
                          ? Container()
                          : !getFollowedData
                              ? /*Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: SkeletonContainer(
                                    width: width * 0.6,
                                    height: 32,
                                  ),
                                )*/
                              Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.025,
                                  ),
                                  child: Text(
                                    'Followed Shops',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: width * 0.06,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                      // FOLLOWED SHOPS
                      currentFollowedShops.isEmpty
                          ? Container()
                          : !getFollowedData
                              ? /*SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 4,
                                    itemBuilder: ((context, index) {
                                      return Padding(
                                        padding: EdgeInsets.all(width * 0.0225),
                                        child: Container(
                                          width: width * 0.28,
                                          height: width * 0.4,
                                          decoration: BoxDecoration(
                                            color: lightGrey,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SkeletonContainer(
                                                width: width * 0.25,
                                                height: width * 0.275,
                                              ),
                                              SkeletonContainer(
                                                width: width * 0.225,
                                                height: width * 0.033,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                )*/
                              Container()
                              : SizedBox(
                                  width: width,
                                  height: width * 0.45,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: currentFollowedShops.length > 4
                                        ? 4
                                        : currentFollowedShops.length,
                                    itemBuilder: ((context, index) {
                                      final String vendorId =
                                          currentFollowedShops.keys
                                              .toList()[index];
                                      final String name = currentFollowedShops
                                          .values
                                          .toList()[index][0];
                                      final String imageUrl =
                                          currentFollowedShops.values
                                              .toList()[index][1];

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) => VendorPage(
                                                    vendorId: vendorId,
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
                                          margin: EdgeInsets.all(
                                            width * 0.0125,
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
                                                  imageUrl.toString().trim(),
                                                  width: width * 0.3,
                                                  height: width * 0.3,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: width * 0.00625,
                                                  left: width * 0.0125,
                                                ),
                                                child: Text(
                                                  name.toString().trim(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: width * 0.04125,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                      // FEATURED 1
                      featured1.isEmpty || featured1.isEmpty
                          ? Container()
                          : const Divider(),

                      // FEATURED CATEGORY 1
                      featuredCategory1 == null || featured1.isEmpty
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.all(
                                width * 0.0125,
                              ),
                              child: Text(
                                featuredCategory1!.toString().trim(),
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.06,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                      // FEATURED PRODUCTS 1
                      featured1.isEmpty
                          ? Container()
                          : SizedBox(
                              width: width,
                              height: width * 0.45,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    featured1.length > 5 ? 5 : featured1.length,
                                itemBuilder: (context, index) {
                                  final name1 = featured1.values.toList()[index]
                                      ['productName'];
                                  final imageUrl1 = featured1.values
                                      .toList()[index]['images'][0];
                                  final productData1 =
                                      featured1.values.toList()[index];

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: ((context) => ProductPage(
                                                productData: productData1,
                                              )),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: width * 0.3,
                                      height: width * 0.3975,
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
                                      margin: EdgeInsets.all(
                                        width * 0.0125,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                            child: Image.network(
                                              imageUrl1.toString().trim(),
                                              width: width * 0.3,
                                              height: width * 0.3,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: width * 0.00625,
                                              left: width * 0.0125,
                                            ),
                                            child: Text(
                                              name1.toString().trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: width * 0.04125,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                      // FEATURED 2
                      featured2.isEmpty || featured2.isEmpty
                          ? Container()
                          : const Divider(),

                      // FEATURED CATEGORY 2
                      featuredCategory2 == null || featured2.isEmpty
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.all(
                                width * 0.0125,
                              ),
                              child: Text(
                                featuredCategory2!.toString().trim(),
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.06,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                      // FEATURED PRODUCTS 2
                      featured2.isEmpty
                          ? Container()
                          : SizedBox(
                              width: width,
                              height: width * 0.45,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    featured2.length > 5 ? 5 : featured2.length,
                                itemBuilder: (context, index) {
                                  final name2 = featured2.values.toList()[index]
                                      ['productName'];
                                  final imageUrl2 = featured2.values
                                      .toList()[index]['images'][0];
                                  final productData2 =
                                      featured2.values.toList()[index];

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: ((context) => ProductPage(
                                                productData: productData2,
                                              )),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: width * 0.3,
                                      height: width * 0.3975,
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
                                      margin: EdgeInsets.all(
                                        width * 0.0125,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                            child: Image.network(
                                              imageUrl2.toString().trim(),
                                              width: width * 0.3,
                                              height: width * 0.3,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: width * 0.00625,
                                              left: width * 0.0125,
                                            ),
                                            child: Text(
                                              name2.toString().trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: width * 0.04125,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                      // FEATURED 3
                      featured3.isEmpty || featured3.isEmpty
                          ? Container()
                          : const Divider(),

                      // FEATURED CATEGORY 3
                      featuredCategory3 == null || featured3.isEmpty
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.all(
                                width * 0.0125,
                              ),
                              child: Text(
                                featuredCategory3!.toString().trim(),
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.06,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                      // FEATURED PRODUCTS 3
                      featured3.isEmpty
                          ? Container()
                          : SizedBox(
                              width: width,
                              height: width * 0.45,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    featured3.length > 5 ? 5 : featured3.length,
                                itemBuilder: (context, index) {
                                  final name3 = featured3.values.toList()[index]
                                      ['productName'];
                                  final imageUrl3 = featured3.values
                                      .toList()[index]['images'][0];
                                  final productData3 =
                                      featured3.values.toList()[index];

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: ((context) => ProductPage(
                                                productData: productData3,
                                              )),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: width * 0.3,
                                      height: width * 0.3975,
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
                                      margin: EdgeInsets.all(
                                        width * 0.0125,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                            child: Image.network(
                                              imageUrl3.toString().trim(),
                                              width: width * 0.3,
                                              height: width * 0.3,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: width * 0.00625,
                                              left: width * 0.0125,
                                            ),
                                            child: Text(
                                              name3.toString().trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: width * 0.04125,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
