// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'package:localsearch_user/page/main/location_change_page.dart';
import 'package:localsearch_user/providers/location_provider.dart';
import 'package:localsearch_user/widgets/snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch_user/page/main/vendor/product/product_page.dart';
import 'package:localsearch_user/utils/colors.dart';
import 'package:localsearch_user/widgets/skeleton_container.dart';
import 'package:localsearch_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({
    super.key,
    required this.categoryName,
  });

  final String categoryName;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  double distanceRange = 5;
  Map<String, dynamic> allProducts = {};
  Map<String, dynamic> currentProducts = {};
  bool isData = false;
  int noOf = 12;
  int? total;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // DID CHANGE DEPENDENCIES
  @override
  void didChangeDependencies() {
    getTotal();
    scrollController.addListener(scrollListener);
    final locationProvider = Provider.of<LocationProvider>(context);
    getProducts(locationProvider);
    super.didChangeDependencies();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // SCROLL LISTENER
  Future<void> scrollListener() async {
    if (total != null && noOf < total!) {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        setState(() {
          isLoadMore = true;
        });
        noOf = noOf + 6;
        final locationProvider = Provider.of<LocationProvider>(context);
        await getProducts(locationProvider);
        setState(() {
          isLoadMore = false;
        });
      }
    }
  }

  // GET TOTAL
  Future<void> getTotal() async {
    final totalSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('categoryName', isEqualTo: widget.categoryName)
        .get();

    final totalLength = totalSnap.docs.length;

    setState(() {
      total = totalLength;
    });
  }

  // GET PRODUCTS
  Future<void> getProducts(LocationProvider locationProvider) async {
    Map<String, dynamic> myProducts = {};

    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('categoryName', isEqualTo: widget.categoryName)
        .limit(noOf)
        .get();

    double? yourLatitude = locationProvider.cityLatitude;
    double? yourLongitude = locationProvider.cityLongitude;

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
      yourLatitude = locationProvider.cityLatitude;
      yourLongitude = locationProvider.cityLongitude;

      await Future.forEach(
        productsSnap.docs,
        (productData) async {
          double? distance;

          final id = productData.id;
          final name = productData['productName'];
          final price = productData['productPrice'];
          final imageUrl = productData['images'][0];
          final ratings = productData['ratings'];
          final vendorId = productData['vendorId'];
          final myProductData = productData.data();

          final vendorSnap = await store
              .collection('Business')
              .doc('Owners')
              .collection('Shops')
              .doc(vendorId)
              .get();

          final vendorData = vendorSnap.data()!;

          final vendorLatitude = vendorData['Latitude'];
          final vendorLongitude = vendorData['Longitude'];

          if (yourLatitude != null && yourLongitude != null) {
            distance = await getDrivingDistance(
              yourLatitude,
              yourLongitude,
              vendorLatitude,
              vendorLongitude,
            );
          }

          if (distance != null) {
            if (distance * 0.925 < 5) {
              myProducts[id] = [
                name,
                price,
                imageUrl,
                ratings,
                myProductData,
                distance,
              ];
            }
          }
        },
      );
    } else {
      try {
        await Future.forEach(
          productsSnap.docs,
          (productData) async {
            final id = productData.id;
            final productName = productData['productName'];
            final price = productData['productPrice'];
            final imageUrl = productData['images'][0];
            final ratings = productData['ratings'];
            final vendorId = productData['vendorId'];
            final myProductData = productData.data();

            final vendorSnap = await store
                .collection('Business')
                .doc('Owners')
                .collection('Shops')
                .doc(vendorId)
                .get();

            final vendorData = vendorSnap.data()!;

            final vendorLatitude = vendorData['Latitude'];
            final vendorLongitude = vendorData['Longitude'];

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
                  await getDrivingDistance(
                    yourLatitude!,
                    yourLongitude!,
                    vendorLatitude,
                    vendorLongitude,
                  ).then((distance) {
                    myProducts[id] = [
                      productName,
                      price,
                      imageUrl,
                      ratings,
                      myProductData,
                      distance,
                    ];
                  });
                }
              }
            }
          },
        );
      } catch (e) {
        if (mounted) {
          mySnackBar(
            'Failed to fetch your City: ${e.toString()}',
            context,
          );
        }
      }
    }

    setState(() {
      currentProducts = myProducts;
      allProducts = myProducts;
      isData = true;
    });
  }

  // UPDATE PRODUCTS
  void updateProducts(double endDistance) {
    Map<String, dynamic> tempProducts = {};
    allProducts.forEach((key, value) {
      final double distance = value[5];
      if (distance * 0.925 <= endDistance) {
        tempProducts[key] = value;
      }
    });
    setState(() {
      currentProducts = tempProducts;
      isData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.width;
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
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
        bottom: PreferredSize(
          preferredSize: Size(width, height * 0.55),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.0166,
              vertical: MediaQuery.of(context).size.width * 0.0225,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: width,
                  child: TextField(
                    controller: searchController,
                    autocorrect: false,
                    onTapOutside: (event) => FocusScope.of(context).unfocus(),
                    decoration: const InputDecoration(
                      hintText: 'Search ...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          currentProducts = Map<String, dynamic>.from(
                            allProducts,
                          );
                        } else {
                          Map<String, dynamic> filteredProducts =
                              Map<String, dynamic>.from(
                            allProducts,
                          );
                          List<String> keysToRemove = [];

                          filteredProducts.forEach((key, productData) {
                            if (!productData[0]
                                .toString()
                                .toLowerCase()
                                .contains(value.toLowerCase().trim())) {
                              keysToRemove.add(key);
                            }
                          });

                          for (var key in keysToRemove) {
                            filteredProducts.remove(key);
                          }

                          currentProducts = filteredProducts;
                        }
                      });
                    },
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
                            page: CategoryProductsPage(
                              categoryName: widget.categoryName,
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
                locationProvider.cityName != null &&
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
                locationProvider.cityName != null &&
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
                                  isData = false;
                                  distanceRange = newValue;
                                });
                                updateProducts(distanceRange);
                                setState(() {
                                  isData = true;
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
                                  ? distanceRange
                                      .toString()
                                      .replaceFirst('.500000000000004', '.5')
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
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.0125,
            vertical: width * 0.0166,
          ),
          child: !isData
              ? GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 6,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: EdgeInsets.all(width * 0.0225),
                      child: Container(
                        width: width * 0.28,
                        height: width * 0.3,
                        decoration: BoxDecoration(
                          color: lightGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SkeletonContainer(
                              width: width * 0.4,
                              height: width * 0.4,
                            ),
                            SkeletonContainer(
                              width: width * 0.4,
                              height: width * 0.04,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    double width = constraints.maxWidth;
                    double height = constraints.maxHeight;

                    return currentProducts.isEmpty
                        ? const SizedBox(
                            height: 80,
                            child: Center(
                              child: Text('No Products'),
                            ),
                          )
                        : GridView.builder(
                            controller: scrollController,
                            cacheExtent: height * 1.5,
                            addAutomaticKeepAlives: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: currentProducts.length,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: ((context, index) {
                              final name =
                                  currentProducts.values.toList()[isLoadMore
                                      ? index == 0
                                          ? 0
                                          : index - 1
                                      : index][0];
                              final price =
                                  currentProducts.values.toList()[isLoadMore
                                      ? index == 0
                                          ? 0
                                          : index - 1
                                      : index][1];
                              final imageUrl =
                                  currentProducts.values.toList()[isLoadMore
                                      ? index == 0
                                          ? 0
                                          : index - 1
                                      : index][2];
                              final ratings =
                                  currentProducts.values.toList()[isLoadMore
                                      ? index == 0
                                          ? 0
                                          : index - 1
                                      : index][3];
                              final productData =
                                  currentProducts.values.toList()[isLoadMore
                                      ? index == 0
                                          ? 0
                                          : index - 1
                                      : index][4];

                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.01,
                                  vertical: width * 0.01,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: ((context) => ProductPage(
                                              productData: productData,
                                            )),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: white,
                                      border: Border.all(
                                        color: primaryDark,
                                        width: 0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              Center(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.5,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.5,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: const Color.fromRGBO(
                                                    255,
                                                    92,
                                                    78,
                                                    1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.0125,
                                                  vertical: width * 0.00625,
                                                ),
                                                margin: EdgeInsets.all(
                                                  width * 0.00625,
                                                ),
                                                child: Text(
                                                  '${(ratings as Map).isEmpty ? '--' : ((ratings.values.map((e) => e?[0] ?? 0).toList().reduce((a, b) => a + b) / (ratings.values.isEmpty ? 1 : ratings.values.length)) as double).toStringAsFixed(1)} ⭐',
                                                  style: const TextStyle(
                                                    color: white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            price == ''
                                                ? 'Rs. --'
                                                : 'Rs. $price',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
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
                          );
                  },
                ),
        ),
      ),
    );
  }
}
