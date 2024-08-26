// ignore_for_file: avoid_function_literals_in_foreach_calls, unused_local_variable
import 'dart:async';
import 'dart:convert';
import 'package:Localsearch_User/models/household_types.dart';
import 'package:Localsearch_User/page/main/vendor/post_page_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:Localsearch_User/page/main/vendor/discount/all_discount_page.dart';
import 'package:Localsearch_User/page/main/location_change_page.dart';
import 'package:Localsearch_User/page/main/main_page.dart';
import 'package:Localsearch_User/page/main/vendor/category/all_shop_types_page.dart';
import 'package:Localsearch_User/page/main/vendor/home/shop_categories_page.dart';
import 'package:Localsearch_User/page/main/vendor/product/product_page.dart';
import 'package:Localsearch_User/page/main/search/search_page.dart';
import 'package:Localsearch_User/page/main/vendor/vendor_page.dart';
import 'package:Localsearch_User/providers/location_provider.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/skeleton_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:provider/provider.dart';

class ProductHomePage extends StatefulWidget {
  const ProductHomePage({
    super.key,
    this.cityName,
  });

  final String? cityName;

  @override
  State<ProductHomePage> createState() => _ProductHomePageState();
}

class _ProductHomePageState extends State<ProductHomePage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  String? recentShop;
  List<String> recentShopProducts = [];
  List<String> recentShopProductsImages = [];
  List<String> recentShopProductsNames = [];
  List<Map<String, dynamic>> recentShopProductsData = [];
  Map<String, dynamic> allWishlist = {};
  Map<String, dynamic> currentWishlist = {};
  Map<String, dynamic> allFollowedShops = {};
  Map<String, dynamic> currentFollowedShops = {};
  Map<String, Map<String, dynamic>> posts = {};
  Map<String, Map<String, Map<String, dynamic>>> featured1 = {};
  Map<String, Map<String, Map<String, dynamic>>> featured2 = {};
  Map<String, Map<String, Map<String, dynamic>>> featured3 = {};
  bool getRecentData = false;
  bool getWishlistData = false;
  bool getFollowedData = false;
  bool isPostData = false;
  double distanceRange = 5;

  // INIT STATE
  @override
  void initState() {
    getName();
    getPosts();
    getRecentShop();
    getFeatured();
    super.initState();
  }

  // DID CHANGE DEPENDENCIES
  @override
  void didChangeDependencies() {
    final locationProvider = Provider.of<LocationProvider>(context);
    getWishlist(locationProvider);
    getFollowedShops(locationProvider);
    getRecentShop();
    super.didChangeDependencies();
  }

  // GET NAME
  Future<String> getName() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final userData = userSnap.data()!;
    String myName = userData['Name'];
    List<String> myNameList = myName.split(' ');
    String newCapitalName = '';
    for (var myName in myNameList) {
      newCapitalName = newCapitalName +
          (myName.substring(0, 1).toUpperCase() + myName.substring(1)) +
          ' ';
    }

    return newCapitalName;
  }

  // GET POSTS
  Future<void> getPosts() async {
    Map<String, Map<String, dynamic>> myPosts = {};

    final postSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Posts')
        .get();

    Future.forEach(
      postSnap.docs,
      (post) async {
        bool isViewed = false;
        final String postId = post.id;

        final postData = post.data();

        final String postText = postData['postText'];
        final String vendorId = postData['postVendorId'];
        final String postImage = postData['postImage'];
        final String postViews =
            (postData['postViews'] as List).length.toString();

        if (postViews.contains(auth.currentUser!.uid)) {
          isViewed = true;
        }

        final vendorSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Shops')
            .doc(vendorId)
            .get();

        final vendorData = vendorSnap.data()!;

        final String vendorName = vendorData['Name'];
        final String vendorImageUrl = vendorData['Image'];

        if (myPosts.containsKey(vendorId)) {
          myPosts[vendorId]!['posts']![postId] = {
            'postText': postText,
            'postImage': postImage,
            'postViews': postViews,
            'isViewed': isViewed,
          };
        } else {
          myPosts[vendorId] = {
            'vendorName': vendorName,
            'vendorImageUrl': vendorImageUrl,
            'posts': {
              postId: {
                'postText': postText,
                'postImage': postImage,
                'postViews': postViews,
                'isViewed': isViewed,
              },
            },
          };
        }
      },
    );

    // myPosts = {
    //   'vendorId1': {
    //     'postId1': {
    //       'postText': 'postText1',
    //       'postImage': 'postImage1',
    //       'postViews': 'postViews1',
    //       'isViewed': 'isViewed1',
    //     },
    //     'postId2': {
    //       'postText': 'postText2',
    //       'postImage': 'postImage2',
    //       'postViews': 'postViews2',
    //       'isViewed': 'isViewed2',
    //     },
    //     'postId3': {
    //       'postText': 'postText3',
    //       'postImage': 'postImage3',
    //       'postViews': 'postViews3',
    //       'isViewed': 'isViewed3',
    //     },
    //   },
    //   'vendorId2': {
    //     'postId1': {
    //       'postText': 'postText1',
    //       'postImage': 'postImage1',
    //       'postViews': 'postViews1',
    //       'isViewed': 'isViewed1',
    //     },
    //   },
    //   'vendorId3': {
    //     'postId1': {
    //       'postText': 'postText1',
    //       'postImage': 'postImage1',
    //       'postViews': 'postViews1',
    //       'isViewed': 'isViewed1',
    //     },
    //     'postId2': {
    //       'postText': 'postText2',
    //       'postImage': 'postImage2',
    //       'postViews': 'postViews2',
    //       'isViewed': 'isViewed2',
    //     },
    //     'postId3': {
    //       'postText': 'postText3',
    //       'postImage': 'postImage3',
    //       'postViews': 'postViews3',
    //       'isViewed': 'isViewed3',
    //     },
    //   },
    // };

    final sortedEntries = myPosts.entries.toList()
      ..sort((a, b) {
        final aTotalViews = a.value.values.fold<int>(
          0,
          (sum, post) => sum + (int.parse(post['postViews'] as String)),
        );

        final bTotalViews = b.value.values.fold<int>(
          0,
          (sum, post) => sum + (int.parse(post['postViews'] as String)),
        );

        return bTotalViews.compareTo(aTotalViews);
      });

    myPosts = Map<String, Map<String, dynamic>>.fromEntries(
      sortedEntries,
    );

    setState(() {
      posts = myPosts;
      isPostData = true;
    });
  }

  // GET NO OF DISCOUNTS
  // Future<bool> getNoOfDiscounts(LocationProvider locationProvider) async {
  //   final Completer<bool> completer = Completer<bool>();
  //   final discountSnap = await store
  //       .collection('Business')
  //       .doc('Data')
  //       .collection('Discounts')
  //       .get();
  //   double? yourLatitude;
  //   double? yourLongitude;
  //   // GET LOCATION
  //   Future<Position?> getLocation() async {
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       if (mounted) {
  //         mySnackBar('Turn ON Location Services to Continue', context);
  //       }
  //       return null;
  //     } else {
  //       LocationPermission permission = await Geolocator.checkPermission();
  //       // LOCATION PERMISSION GIVEN
  //       Future<Position> locationPermissionGiven() async {
  //         return await Geolocator.getCurrentPosition();
  //       }
  //       if (permission == LocationPermission.denied) {
  //         permission = await Geolocator.requestPermission();
  //         if (permission == LocationPermission.denied) {
  //           if (mounted) {
  //             mySnackBar('Pls give Location Permission to Continue', context);
  //           }
  //         }
  //         permission = await Geolocator.requestPermission();
  //         if (permission == LocationPermission.deniedForever) {
  //           setState(() {
  //             yourLatitude = 0;
  //             yourLongitude = 0;
  //           });
  //           if (mounted) {
  //             mySnackBar(
  //               'Because Location permission is denied, We are continuing without Location',
  //               context,
  //             );
  //           }
  //         } else {
  //           return await locationPermissionGiven();
  //         }
  //       } else {
  //         return await locationPermissionGiven();
  //       }
  //     }
  //     return null;
  //   }
  //   // GET DISTANCE
  //   Future<double?> getDrivingDistance(
  //     double startLat,
  //     double startLong,
  //     double endLat,
  //     double endLong,
  //   ) async {
  //     String url =
  //         'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$startLat,$startLong&destinations=$endLat,$endLong&key=AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';
  //     try {
  //       var response = await http.get(Uri.parse(url));
  //       if (response.statusCode == 200) {
  //         final data = jsonDecode(response.body);
  //         if (data['rows'].isNotEmpty &&
  //             data['rows'][0]['elements'].isNotEmpty) {
  //           final distance =
  //               data['rows'][0]['elements'][0]['distance']['value'];
  //           return distance / 1000;
  //         }
  //       }
  //       return null;
  //     } catch (e) {
  //       return null;
  //     }
  //   }
  //   if (locationProvider.cityName == 'Your Location') {
  //     final position = await getLocation();
  //     if (position != null) {
  //       setState(() {
  //         yourLatitude = position.latitude;
  //         yourLongitude = position.longitude;
  //       });
  //       for (var discount in discountSnap.docs) {
  //         final discountData = discount.data();
  //         final Timestamp endDateTime = discountData['discountEndDateTime'];
  //         final vendorId = discountData['vendorId'];
  //         final vendorSnap = await store
  //             .collection('Business')
  //             .doc('Owners')
  //             .collection('Shops')
  //             .doc(vendorId)
  //             .get();
  //         final vendorData = vendorSnap.data()!;
  //         final vendorLatitude = vendorData['Latitude'];
  //         final vendorLongitude = vendorData['Longitude'];
  //         try {
  //           final dist = await getDrivingDistance(
  //             yourLatitude!,
  //             yourLongitude!,
  //             vendorLatitude,
  //             vendorLongitude,
  //           );
  //           if (dist != null) {
  //             if (dist < 5) {
  //               if (endDateTime.toDate().isAfter(DateTime.now())) {
  //                 completer.complete(true);
  //                 return true;
  //               }
  //               completer.complete(false);
  //               return false;
  //             }
  //             completer.complete(false);
  //             return false;
  //           }
  //           completer.complete(false);
  //           return false;
  //         } catch (e) {
  //           mySnackBar(e.toString(), context);
  //           completer.complete(false);
  //           return false;
  //         }
  //       }
  //       completer.complete(false);
  //       return false;
  //     }
  //     completer.complete(false);
  //     return false;
  //   } else {
  //     for (var discount in discountSnap.docs) {
  //       final discountData = discount.data();
  //       final vendorId = discountData['vendorId'];
  //       final vendorSnap = await store
  //           .collection('Business')
  //           .doc('Owners')
  //           .collection('Shops')
  //           .doc(vendorId)
  //           .get();
  //       final vendorData = vendorSnap.data()!;
  //       final vendorLatitude = vendorData['Latitude'];
  //       final vendorLongitude = vendorData['Longitude'];
  //       try {
  //         final url =
  //             'https://maps.googleapis.com/maps/api/geocode/json?latlng=$vendorLatitude,$vendorLongitude&key=AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';
  //         final response = await http.get(Uri.parse(url));
  //         if (response.statusCode == 200) {
  //           final data = json.decode(response.body);
  //           String? name;
  //           if (data['status'] == 'OK') {
  //             for (var result in data['results']) {
  //               for (var component in result['address_components']) {
  //                 if (component['types'].contains('locality')) {
  //                   name = component['long_name'];
  //                   break;
  //                 } else if (component['types'].contains('sublocality')) {
  //                   name = component['long_name'];
  //                 } else if (component['types'].contains('neighborhood')) {
  //                   name = component['long_name'];
  //                 } else if (component['types'].contains('route')) {
  //                   name = component['long_name'];
  //                 } else if (component['types']
  //                     .contains('administrative_area_level_3')) {
  //                   name = component['long_name'];
  //                 }
  //               }
  //               if (name != null) break;
  //             }
  //             final discountData = discount.data();
  //             final Timestamp endDateTime = discountData['discountEndDateTime'];
  //             if (name == locationProvider.cityName!) {
  //               if (endDateTime.toDate().isAfter(DateTime.now())) {
  //                 completer.complete(true);
  //                 return true;
  //               }
  //               completer.complete(false);
  //               return false;
  //             }
  //             completer.complete(false);
  //             return false;
  //           }
  //           completer.complete(false);
  //           return false;
  //         }
  //         completer.complete(false);
  //         return false;
  //       } catch (e) {
  //         mySnackBar(
  //           'Failed to fetch your City: ${e.toString()}',
  //           context,
  //         );
  //         completer.complete(false);
  //         return false;
  //       }
  //     }
  //     completer.complete(false);
  //     return false;
  //   }
  // }

  // GET RECENT SHOP
  Future<void> getRecentShop() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final myRecentShop = userData['recentShop'];

    if (myRecentShop != '') {
      final vendorSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .doc(myRecentShop)
          .get();

      final vendorData = vendorSnap.data()!;

      final vendorLatitude = vendorData['Latitude'];
      final vendorLongitude = vendorData['Longitude'];

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
              setState(() {
                yourLatitude = 0;
                yourLongitude = 0;
              });
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

      await getLocation().then((value) async {
        if (value != null) {
          setState(() {
            yourLatitude = value.latitude;
            yourLongitude = value.longitude;
          });

          try {
            final dist = await getDrivingDistance(
              yourLatitude!,
              yourLongitude!,
              vendorLatitude,
              vendorLongitude,
            );

            if (dist != null) {
              if (dist < 5) {
                setState(() {
                  recentShop = myRecentShop;
                });
              }
            }
          } catch (e) {}
        }
      });

      await getNoOfProductsOfRecentShop();
    }
  }

  // GET NO OF PRODUCTS OF RECENT SHOP
  Future<void> getNoOfProductsOfRecentShop() async {
    if (recentShop != null) {
      final recentProducts = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .where('vendorId', isEqualTo: recentShop)
          .get();

      for (final doc in recentProducts.docs) {
        if (!recentShopProducts.contains(doc['productId'])) {
          recentShopProducts.add(doc['productId']);
        }
      }

      await getRecentShopProductInfo();
    }
  }

  // GET RECENT SHOP PRODUCT INFO
  Future<int> getRecentShopProductInfo() async {
    List<String> temporaryNameList = [];
    List<String> temporaryImageList = [];
    List<Map<String, dynamic>> temporaryDataList = [];

    recentShopProducts.forEach((productId) async {
      final productSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(productId)
          .get();

      final productData = productSnap.data()!;

      temporaryNameList.add(productData['productName']);
      temporaryImageList.add(productData['images'][0]);
      temporaryDataList.add(productData);
      setState(() {
        recentShopProductsNames = temporaryNameList;
        recentShopProductsImages = temporaryImageList;
        recentShopProductsData = temporaryDataList;
        getRecentData = true;
      });
    });

    return recentShopProductsImages.length;
  }

  // GET WISHLIST
  Future<void> getWishlist(LocationProvider locationProvider) async {
    Map<String, List> myWishlist = {};
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final List wishlists = userData['wishlists'];

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
            setState(() {
              yourLatitude = 0;
              yourLongitude = 0;
            });
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

    wishlists.forEach((productId) async {
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

      final vendorSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .doc(vendorId)
          .get();

      final vendorData = vendorSnap.data()!;

      final vendorLatitude = vendorData['Latitude'];
      final vendorLongitude = vendorData['Longitude'];

      if (locationProvider.cityName == 'Your Location') {
        await getLocation().then((value) async {
          if (value != null) {
            setState(() {
              yourLatitude = value.latitude;
              yourLongitude = value.longitude;
            });
            try {
              final dist = await getDrivingDistance(
                yourLatitude!,
                yourLongitude!,
                vendorLatitude,
                vendorLongitude,
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
            } catch (e) {}
          }
        });
      } else {
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
                currentWishlist[productId] = [
                  productName,
                  imageUrl,
                  productData,
                ];
              }
            } else {}
          } else {}
        } catch (e) {
          mySnackBar(
            'Failed to fetch your City: ${e.toString()}',
            context,
          );
        }
      }

      setState(() {
        getWishlistData = true;
      });
    });
  }

  // GET FOLLOWED SHOPS
  Future<void> getFollowedShops(LocationProvider locationProvider) async {
    Map<String, List> myFollowedShops = {};
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final List followedShop = userData['followedShops'];

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
            setState(() {
              yourLatitude = 0;
              yourLongitude = 0;
            });
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
          for (var vendorId in followedShop) {
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
            } catch (e) {}
          }
        }
      });
    } else {
      for (var vendorId in followedShop) {
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
                final String? name = vendorData['Name'];
                final String? imageUrl = vendorData['Image'];
                allFollowedShops[vendorId] = [name, imageUrl];
                currentFollowedShops[vendorId] = [name, imageUrl];
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

    setState(() {
      getFollowedData = true;
    });
  }

  // GET POSTS
  // Future<void> getPosts() async {
  //   Map<String, dynamic> myPosts = {};
  //   final postsSnap = await store
  //       .collection('Business')
  //       .doc('Data')
  //       .collection('Posts')
  //       .get();
  //   for (final postSnap in postsSnap.docs) {
  //     final postData = postSnap.data();
  //     final String productId = postData['postProductId'];
  //     final String name = postData['postProductName'];
  //     final String price = postData['postProductPrice'];
  //     final bool isTextPost = postData['isTextPost'];
  //     final List imageUrl = isTextPost ? [] : postData['postImage'];
  //     final String vendorId = postData['postVendorId'];
  //     final Timestamp datetime = postData['postDateTime'];
  //     myPosts[isTextPost ? '${productId}text' : '${productId}image'] = [
  //       name,
  //       price,
  //       imageUrl,
  //       vendorId,
  //       isTextPost,
  //       datetime,
  //     ];
  //     myPosts = Map.fromEntries(
  //       myPosts.entries.toList()
  //         ..sort(
  //           (a, b) => (b.value[5] as Timestamp).compareTo(
  //             a.value[5] as Timestamp,
  //           ),
  //         ),
  //     );
  //     await getVendorInfo(vendorId);
  //     await getPostProductData(productId, isTextPost);
  //   }
  //   setState(() {
  //     posts = myPosts;
  //     isPostData = true;
  //   });
  // }

  // // GET POST PRODUCT DATA
  // Future<Map<String, dynamic>?> getPostProductData(
  //     String productId, bool isTextPost,
  //     {bool? wantData}) async {
  //   final productSnap = await store
  //       .collection('Business')
  //       .doc('Data')
  //       .collection('Products')
  //       .doc(productId)
  //       .get();
  //   final productData = productSnap.data();
  //   productsData[isTextPost ? '${productId}text' : '${productId}image'] =
  //       productData;
  //   if (wantData != null) {
  //     return productsData[isTextPost ? productId : productId];
  //   } else {
  //     return null;
  //   }
  // }

  // // GET VENDOR INFO
  // Future<void> getVendorInfo(String vendorId) async {
  //   final vendorSnap = await store
  //       .collection('Business')
  //       .doc('Owners')
  //       .collection('Shops')
  //       .doc(vendorId)
  //       .get();
  //   final vendorData = vendorSnap.data();
  //   if (vendorData != null) {
  //     final id = vendorSnap.id;
  //     final name = vendorData['Name'];
  //     final imageUrl = vendorData['Image'];
  //     setState(() {
  //       vendors[id] = [name, imageUrl];
  //     });
  //   }
  // }

  // UPDATE WISHLIST
  void updateWishlist(double endDistance) {
    Map<String, dynamic> tempWishlist = {};

    allWishlist.forEach((key, value) {
      final double distance = value[3];
      if (distance * 0.925 <= endDistance) {
        tempWishlist[key] = value;
      }
    });
    setState(() {
      currentWishlist = tempWishlist;
    });
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
    setState(() {
      currentFollowedShops = tempFollowed;
    });
  }

  // UPDATE DISCOUNTS
  // void updateDiscounts(
  //   double endDistance,
  //   LocationProvider locationProvider,
  // ) async {
  //   final discountSnap = await store
  //       .collection('Business')
  //       .doc('Data')
  //       .collection('Discounts')
  //       .get();
  //   double? yourLatitude;
  //   double? yourLongitude;
  //   // GET LOCATION
  //   Future<Position?> getLocation() async {
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       if (mounted) {
  //         mySnackBar('Turn ON Location Services to Continue', context);
  //       }
  //       return null;
  //     } else {
  //       LocationPermission permission = await Geolocator.checkPermission();
  //       // LOCATION PERMISSION GIVEN
  //       Future<Position> locationPermissionGiven() async {
  //         return await Geolocator.getCurrentPosition();
  //       }
  //       if (permission == LocationPermission.denied) {
  //         permission = await Geolocator.requestPermission();
  //         if (permission == LocationPermission.denied) {
  //           if (mounted) {
  //             mySnackBar('Pls give Location Permission to Continue', context);
  //           }
  //         }
  //         permission = await Geolocator.requestPermission();
  //         if (permission == LocationPermission.deniedForever) {
  //           setState(() {
  //             yourLatitude = 0;
  //             yourLongitude = 0;
  //           });
  //           if (mounted) {
  //             mySnackBar(
  //               'Because Location permission is denied, We are continuing without Location',
  //               context,
  //             );
  //           }
  //         } else {
  //           return await locationPermissionGiven();
  //         }
  //       } else {
  //         return await locationPermissionGiven();
  //       }
  //     }
  //     return null;
  //   }
  //   // GET DISTANCE
  //   Future<double?> getDrivingDistance(
  //     double startLat,
  //     double startLong,
  //     double endLat,
  //     double endLong,
  //   ) async {
  //     String url =
  //         'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$startLat,$startLong&destinations=$endLat,$endLong&key=AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';
  //     try {
  //       var response = await http.get(Uri.parse(url));
  //       if (response.statusCode == 200) {
  //         final data = jsonDecode(response.body);
  //         if (data['rows'].isNotEmpty &&
  //             data['rows'][0]['elements'].isNotEmpty) {
  //           final distance =
  //               data['rows'][0]['elements'][0]['distance']['value'];
  //           return distance / 1000;
  //         }
  //       }
  //       return null;
  //     } catch (e) {
  //       return null;
  //     }
  //   }
  //   if (locationProvider.cityName == null) {
  //     await getLocation().then((value) async {
  //       if (value != null) {
  //         setState(() {
  //           yourLatitude = value.latitude;
  //           yourLongitude = value.longitude;
  //         });
  //         for (var discount in discountSnap.docs) {
  //           final discountData = discount.data();
  //           final Timestamp endDateTime = discountData['discountEndDateTime'];
  //           final vendorId = discountData['vendorId'];
  //           final vendorSnap = await store
  //               .collection('Business')
  //               .doc('Owners')
  //               .collection('Shops')
  //               .doc(vendorId)
  //               .get();
  //           final vendorData = vendorSnap.data()!;
  //           final vendorLatitude = vendorData['Latitude'];
  //           final vendorLongitude = vendorData['Longitude'];
  //           try {
  //             final dist = await getDrivingDistance(
  //               yourLatitude!,
  //               yourLongitude!,
  //               vendorLatitude,
  //               vendorLongitude,
  //             );
  //             if (dist != null) {
  //               if (dist < endDistance) {
  //                 if (endDateTime.toDate().isAfter(DateTime.now())) {
  //                   setState(() {
  //                     isDiscount = true;
  //                   });
  //                   ;
  //                 }
  //               }
  //             }
  //           } catch (e) {}
  //         }
  //       }
  //     });
  //   }
  // }

  // GET FEATURED
  Future<void> getFeatured() async {
    Map<String, Map<String, Map<String, dynamic>>> myFeatured1 = {};
    Map<String, Map<String, Map<String, dynamic>>> myFeatured2 = {};
    Map<String, Map<String, Map<String, dynamic>>> myFeatured3 = {};

    final featuredSnap = await store.collection('Featured').doc('Vendor').get();

    final featuredData = featuredSnap.data()!;

    final category1 = featuredData['category1'];
    final category2 = featuredData['category2'];
    final category3 = featuredData['category3'];

    final productSnap1 = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('categoryName', isEqualTo: category1)
        .get();

    productSnap1.docs.forEach((product1) {
      final productId1 = product1.id;

      final productData1 = product1.data();

      myFeatured1[category1] = {
        productId1: productData1,
      };
    });

    final productSnap2 = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('categoryName', isEqualTo: category2)
        .get();

    productSnap2.docs.forEach((product2) {
      final productId2 = product2.id;

      final productData2 = product2.data();

      myFeatured2[category2] = {
        productId2: productData2,
      };
    });

    final productSnap3 = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('categoryName', isEqualTo: category3)
        .get();

    productSnap3.docs.forEach((product3) {
      final productId3 = product3.id;

      final productData3 = product3.data();

      myFeatured3[category3] = {
        productId3: productData3,
      };
    });

    setState(() {
      featured1 = myFeatured1;
      featured2 = myFeatured2;
      featured3 = myFeatured3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
                future: getName(),
                builder: (context, future) {
                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                            text: 'Hi, ',
                            style: TextStyle(
                              fontSize: width * 0.0575,
                              color: primaryDark,
                              fontWeight: FontWeight.w500,
                            )),
                        TextSpan(
                            text: future.data,
                            style: TextStyle(
                              fontSize: width * 0.06,
                              color: Color.fromRGBO(52, 127, 255, 1),
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  );
                }),
            Column(
              children: [
                SizedBox(height: 4),
                // SELECT LOCATION
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LocationChangePage(
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
              ],
            ),
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
              await getRecentShop();
              await getWishlist(locationProvider);
              await getFollowedShops(locationProvider);
            },
            color: primaryDark,
            backgroundColor: const Color.fromARGB(255, 243, 253, 255),
            semanticsLabel: 'Refresh',
            child: LayoutBuilder(
              builder: ((context, constraints) {
                final double width = constraints.maxWidth;

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
                          splashColor: white.withOpacity(0.125),
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

                      // POSTS
                      !isPostData
                          ? SizedBox(
                              width: width,
                              height: width * 0.3,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
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
                            )
                          : posts.isEmpty
                              ? Container()
                              : SizedBox(
                                  width: width,
                                  height: width * 0.3,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        posts.length > 9 ? 10 : posts.length,
                                    itemBuilder: (context, index) {
                                      final String vendorId =
                                          posts.keys.toList()[index];
                                      final String vendorName = posts.values
                                          .toList()[index]['vendorName'];
                                      final String vendorImageUrl = posts.values
                                          .toList()[index]['vendorImageUrl'];
                                      final bool isViewed =
                                          (posts[vendorId]!['posts'] as Map<
                                                  String, Map<String, dynamic>>)
                                              .values
                                              .every(
                                                (post) =>
                                                    post['isViewed'] == true,
                                              );

                                      /*index != (posts.length - 1)
                                      ?*/
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.025,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PostPageView(
                                                  currentIndex: index,
                                                  posts: posts,
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
                                                  opacity: isViewed ? 0.75 : 1,
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
                                                        vendorImageUrl,
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
                                                    vendorName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight: isViewed
                                                          ? FontWeight.w400
                                                          : FontWeight.w500,
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
                          : Divider(),

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
                                        getWishlistData = false;
                                        getFollowedData = false;
                                        distanceRange = newValue;
                                      });
                                      updateWishlist(newValue);
                                      updateFollowed(newValue);
                                      // updateDiscounts(
                                      //   newValue,
                                      //   locationProvider,
                                      // );
                                      setState(() {
                                        getWishlistData = true;
                                        getFollowedData = true;
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

                      // ONGOING DISCOUNTS
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const AllDiscountPage()),
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
                                Color.fromRGBO(143, 30, 255, 1),
                              ],
                            ),
                            border: Border.all(
                              width: 2,
                              color: primaryDark,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: width * 0.0125,
                            vertical: 4,
                          ),
                          child: Text(
                            "ONGOING OFFERS",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryDark,
                              fontSize: width * 0.066,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // SHOP TYPES
                      Padding(
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
                      Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: width,
                              height: width * 0.3,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: 4,
                                itemBuilder: ((context, index) {
                                  final String name =
                                      householdTypes.keys.toList()[index];
                                  final String imageUrl =
                                      householdTypes.values.toList()[index];

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.025,
                                      vertical: width * 0.015,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) =>
                                                ShopCategoriesPage(
                                                  shopName: name,
                                                )),
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
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  height: width * 0.175,
                                                ),
                                              ),
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: primaryDark,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                      final String name = householdTypes.keys
                                          .toList()[index + 4];
                                      final String imageUrl = householdTypes
                                          .values
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
                                                builder: ((context) =>
                                                    ShopCategoriesPage(
                                                      shopName: name,
                                                    )),
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
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                    child: Image.network(
                                                      imageUrl,
                                                      height: width * 0.175,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Text(
                                                    name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
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
                                            const AllShopTypesPage()),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: width * 0.225,
                                    height: width * 0.25,
                                    decoration: BoxDecoration(
                                      color: primary2.withOpacity(0.125),
                                      border: Border.all(
                                        width: 0.125,
                                        color: primaryDark,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
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

                      // posts.length < 2 ? Container() : Divider(),

                      recentShop == null
                          ? Container()
                          : !getRecentData
                              ? Container()
                              : Divider(),

                      // CONTINUE SHOPPING
                      recentShop == null
                          ? Container()
                          : !getRecentData
                              ? Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: SkeletonContainer(
                                    width: width * 0.6,
                                    height: 32,
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.025,
                                  ),
                                  child: Text(
                                    'Continue Shopping',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: width * 0.07,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                      // CONTINUE SHOPPING PRODUCTS
                      recentShop == null
                          ? Container()
                          : !getRecentData
                              ? SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 4,
                                    itemBuilder: ((context, index) {
                                      return Container(
                                        width: width * 0.28,
                                        height: width * 0.4,
                                        decoration: BoxDecoration(
                                          color: lightGrey,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        margin: EdgeInsets.all(width * 0.0225),
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
                                      );
                                    }),
                                  ),
                                )
                              : SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        recentShopProductsImages.length > 4
                                            ? 4
                                            : recentShopProductsImages.length,
                                    itemBuilder: ((context, index) {
                                      final String name =
                                          recentShopProductsNames[index];
                                      final String imageUrl =
                                          recentShopProductsImages[index];

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) =>
                                                  ProductPage(
                                                    productData:
                                                        recentShopProductsData[
                                                            index],
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
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: width * 0.3,
                                                  height: width * 0.3,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: width * 0.00625,
                                                  left: width * 0.0125,
                                                ),
                                                child: Text(
                                                  name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: width * 0.05,
                                                    fontWeight: FontWeight.w500,
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

                      // WISHLIST
                      currentWishlist.isEmpty
                          ? Container()
                          : !getWishlistData
                              ? Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: SkeletonContainer(
                                    width: width * 0.6,
                                    height: 32,
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.025,
                                  ),
                                  child: Text(
                                    'Your Wishlists ❤️',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: width * 0.07,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                      currentWishlist.isEmpty ? Container() : Divider(),

                      // WISHLIST PRODUCTS
                      currentWishlist.isEmpty
                          ? Container()
                          : !getWishlistData
                              ? SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
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
                                )
                              : SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
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
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: width * 0.3,
                                                  height: width * 0.3,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: width * 0.00625,
                                                  left: width * 0.0125,
                                                ),
                                                child: Text(
                                                  name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: width * 0.05,
                                                    fontWeight: FontWeight.w500,
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

                      currentFollowedShops.isEmpty ? Container() : Divider(),

                      // FOLLOWED
                      currentFollowedShops.isEmpty
                          ? Container()
                          : !getFollowedData
                              ? Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: SkeletonContainer(
                                    width: width * 0.6,
                                    height: 32,
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.025,
                                  ),
                                  child: Text(
                                    'Followed Shops',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: width * 0.07,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                      // FOLLOWED SHOPS
                      currentFollowedShops.isEmpty
                          ? Container()
                          : !getFollowedData
                              ? SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
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
                                )
                              : SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
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
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: width * 0.3,
                                                  height: width * 0.3,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: width * 0.00625,
                                                  left: width * 0.0125,
                                                ),
                                                child: Text(
                                                  name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: width * 0.05,
                                                    fontWeight: FontWeight.w500,
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
                      featured1.isEmpty ? Container() : Divider(),

                      // FEATURED CATEGORY 1
                      featured1.isEmpty
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.all(
                                width * 0.0125,
                              ),
                              child: Text(
                                featured1.keys.toList()[0],
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
                              height: width * 0.425,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: featured1.length,
                                itemBuilder: (context, index) {
                                  final name1 = featured1.values
                                      .toList()[index]
                                      .values
                                      .toList()[index]['productName'];
                                  final imageUrl1 = featured1.values
                                      .toList()[index]
                                      .values
                                      .toList()[index]['images'][0];
                                  final productData1 = featured1.values
                                      .toList()[index]
                                      .values
                                      .toList()[index];

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
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            child: Image.network(
                                              imageUrl1,
                                              fit: BoxFit.cover,
                                              width: width * 0.3,
                                              height: width * 0.3,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: width * 0.00625,
                                              left: width * 0.0125,
                                            ),
                                            child: Text(
                                              name1,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: width * 0.05,
                                                fontWeight: FontWeight.w500,
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
                      featured2.isEmpty ? Container() : Divider(),

                      // FEATURED CATEGORY 2
                      featured2.isEmpty
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.all(
                                width * 0.0125,
                              ),
                              child: Text(
                                featured2.keys.toList()[0],
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
                              height: width * 0.425,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: featured2.length,
                                itemBuilder: (context, index) {
                                  final name2 = featured2.values
                                      .toList()[index]
                                      .values
                                      .toList()[index]['productName'];
                                  final imageUrl2 = featured2.values
                                      .toList()[index]
                                      .values
                                      .toList()[index]['images'][0];
                                  final productData2 = featured2.values
                                      .toList()[index]
                                      .values
                                      .toList()[index];

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
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            child: Image.network(
                                              imageUrl2,
                                              fit: BoxFit.cover,
                                              width: width * 0.3,
                                              height: width * 0.3,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: width * 0.00625,
                                              left: width * 0.0125,
                                            ),
                                            child: Text(
                                              name2,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: width * 0.05,
                                                fontWeight: FontWeight.w500,
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
                      featured3.isEmpty ? Container() : Divider(),

                      // FEATURED CATEGORY 3
                      featured3.isEmpty
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.all(
                                width * 0.0125,
                              ),
                              child: Text(
                                featured3.keys.toList()[0],
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
                              height: width * 0.425,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: featured3.length,
                                itemBuilder: (context, index) {
                                  final name3 = featured3.values
                                      .toList()[index]
                                      .values
                                      .toList()[index]['productName'];
                                  final imageUrl3 = featured3.values
                                      .toList()[index]
                                      .values
                                      .toList()[index]['images'][0];
                                  final productData3 = featured3.values
                                      .toList()[index]
                                      .values
                                      .toList()[index];

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
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            child: Image.network(
                                              imageUrl3,
                                              fit: BoxFit.cover,
                                              width: width * 0.3,
                                              height: width * 0.3,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: width * 0.00625,
                                              left: width * 0.0125,
                                            ),
                                            child: Text(
                                              name3,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: width * 0.05,
                                                fontWeight: FontWeight.w500,
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
