// ignore_for_file: avoid_function_literals_in_foreach_calls, unused_local_variable
import 'dart:async';
import 'dart:convert';
import 'package:localsearch/page/main/vendor/post_page_view.dart';
import 'package:localsearch/page/main/vendor/profile/wishlist_page.dart';
import 'package:localsearch/widgets/text_button.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localsearch/page/main/vendor/discount/all_discount_page.dart';
import 'package:localsearch/page/main/location_change_page.dart';
import 'package:localsearch/page/main/main_page.dart';
import 'package:localsearch/page/main/vendor/category/all_shop_types_page.dart';
import 'package:localsearch/page/main/vendor/home/shop_categories_page.dart';
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
  Map<String, dynamic>? shopTypesData;
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
  Map<String, Map<String, dynamic>> featured1 = {};
  Map<String, Map<String, dynamic>> featured2 = {};
  Map<String, Map<String, dynamic>> featured3 = {};
  String? featuredCategory1;
  String? featuredCategory2;
  String? featuredCategory3;
  bool getRecentData = false;
  bool getWishlistData = false;
  bool getFollowedData = false;
  bool isPostData = false;
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

  // // GET TOTAL
  // Future<void> getTotal() async {
  //   final featuredSnap = await store.collection('Featured').doc('Vendor').get();
  //   final featuredData = featuredSnap.data()!;
  //   final category1 = featuredData['category1'];
  //   final category2 = featuredData['category2'];
  //   final category3 = featuredData['category3'];
  //   final totalSnap1 = await store
  //       .collection('Business')
  //       .doc('Data')
  //       .collection('Products')
  //       .where('categoryName', isEqualTo: category1)
  //       .get();
  //   final totalLength1 = totalSnap1.docs.length;
  //   final totalSnap2 = await store
  //       .collection('Business')
  //       .doc('Data')
  //       .collection('Products')
  //       .where('categoryName', isEqualTo: category2)
  //       .get();
  //   final totalLength2 = totalSnap2.docs.length;
  //   final totalSnap3 = await store
  //       .collection('Business')
  //       .doc('Data')
  //       .collection('Products')
  //       .where('categoryName', isEqualTo: category3)
  //       .get();
  //   final totalLength3 = totalSnap3.docs.length;
  //   setState(() {
  //     total1 = totalLength1;
  //     total2 = totalLength2;
  //     total3 = totalLength3;
  //   });
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

  // GET DATA
  Future<void> getData(bool fromRefreshIndicator) async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    // GET NAME
    Future<void> getName() async {
      String myName = userData['Name'];
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

    // GET POSTS
    Future<void> getPosts() async {
      Map<String, Map<String, dynamic>> myPosts = {};

      final postSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Posts')
          .get();

      await Future.forEach(
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
            (additionSum, post) =>
                additionSum + (int.parse(post['postViews'] as String)),
          );

          final bTotalViews = b.value.values.fold<int>(
            0,
            (additionSum, post) =>
                additionSum + (int.parse(post['postViews'] as String)),
          );

          return bTotalViews.compareTo(aTotalViews);
        });

      myPosts = Map<String, Map<String, dynamic>>.fromEntries(
        sortedEntries,
      );

      if (mounted) {
        setState(() {
          posts = myPosts;
          isPostData = true;
        });
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
        if (mounted) {
          setState(() {
            yourLatitude = locationProvider.cityLatitude;
            yourLongitude = locationProvider.cityLongitude;
          });
        }

        try {
          if (yourLatitude == null || yourLongitude == null) {
            await Future.delayed(Duration(seconds: 10));
            yourLatitude = locationProvider.cityLatitude;
            yourLongitude = locationProvider.cityLongitude;
            if (yourLatitude != null) {
              final dist = await getDrivingDistance(
                yourLatitude!,
                yourLongitude!,
                vendorLatitude,
                vendorLongitude,
              );

              if (dist != null) {
                if (dist < 5) {
                  if (mounted) {
                    setState(() {
                      recentShop = myRecentShop;
                    });
                  }
                }
              }
            } else {}
          } else {
            final dist = await getDrivingDistance(
              yourLatitude!,
              yourLongitude!,
              vendorLatitude,
              vendorLongitude,
            );

            if (dist != null) {
              if (dist < 5) {
                if (mounted) {
                  setState(() {
                    recentShop = myRecentShop;
                  });
                }
              }
            }
          }
        } catch (e) {
          if (mounted) {
            mySnackBar('Some error occured: ${e.toString()}', context);
          }
        }
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
        if (mounted) {
          setState(() {
            recentShopProductsNames = temporaryNameList;
            recentShopProductsImages = temporaryImageList;
            recentShopProductsData = temporaryDataList;
            getRecentData = true;
          });
        }
      });

      return recentShopProductsImages.length;
    }

    // GET WISHLIST
    Future<void> getWishlist() async {
      Map<String, List> myWishlist = {};

      final List wishlists = userData['wishlists'];

      double? yourLatitude;
      double? yourLongitude;

      await Future.forEach(
        wishlists,
        (productId) async {
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
                  'Some error occured: ${e.toString()}',
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

          if (mounted) {
            setState(() {
              getWishlistData = true;
            });
          }
        },
      );
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

        await Future.forEach(followedShop, (vendorId) async {
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
                'Some error occured while finding Distance',
                context,
              );
            }
          }
        });
      } else {
        await Future.forEach(followedShop, (vendorId) async {
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
            if (mounted) {
              mySnackBar(
                'Failed to fetch your City: ${e.toString()}',
                context,
              );
            }
          }
        });
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
      await getName().then((value) async {
        await getPosts().then((value) async {
          await getShopTypes().then((value) async {
            await getRecentShop().then((value) async {
              await getNoOfProductsOfRecentShop().then((value) async {
                await getRecentShopProductInfo().then((value) async {
                  await getWishlist().then((value) async {
                    await getFollowedShops().then((value) async {
                      await getFeatured().then((value) async {
                        // final reviewProvider = Provider.of<ReviewProvider>(
                        //   context,
                        //   listen: false,
                        // );
                        // final hasReviewed = reviewProvider.hasAsked;

                        // if (!hasReviewed) {
                        //   if (!fromRefreshIndicator) {
                        //     await getHasReviewed();
                        //   }
                        // }
                      });
                    });
                  });
                });
              });
            });
          });
        });
      });
    }
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
  //
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
  //
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
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
                    text: name,
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

                      // POSTS
                      !isPostData
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
                          : posts.isEmpty
                              ? Container()
                              : AnimatedContainer(
                                  width: width,
                                  height: width * 0.3,
                                  duration: Duration(milliseconds: 250),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        posts.length >= 10 ? 10 : posts.length,
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
                                                  builder: ((context) =>
                                                      ShopCategoriesPage(
                                                        shopType: name,
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
                                                        fit: BoxFit.cover,
                                                        width: width * 0.175,
                                                        height: width * 0.175,
                                                      ),
                                                    ),
                                                    Text(
                                                      name,
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
                                                      builder: ((context) =>
                                                          ShopCategoriesPage(
                                                            shopType: name,
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
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            12,
                                                          ),
                                                          child: Image.network(
                                                            imageUrl,
                                                            height:
                                                                width * 0.175,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        Text(
                                                          name,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
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

                      // posts.length < 2 ? Container() : Divider(),

                      recentShop == null
                          ? Container()
                          : !getRecentData
                              ? Container()
                              : const Divider(),

                      // CONTINUE SHOPPING
                      recentShop == null
                          ? Container()
                          : !getRecentData
                              ? /*Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: SkeletonContainer(
                                    width: width * 0.6,
                                    height: 32,
                                  ),
                                )*/
                              Container()
                              : AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: Duration(milliseconds: 250),
                                  child: Padding(
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
                                ),

                      // CONTINUE SHOPPING PRODUCTS
                      recentShop == null
                          ? Container()
                          : !getRecentData
                              ? /*SizedBox(
                                  width: width,
                                  height: width * 0.425,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
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
                                )*/
                              Container()
                              : AnimatedContainer(
                                  width: width,
                                  height: width * 0.45,
                                  duration: Duration(milliseconds: 250),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
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
                              : AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: Duration(milliseconds: 2500),
                                  child: Padding(
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
                                featuredCategory1!,
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
                                featuredCategory2!,
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
                                featuredCategory3!,
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
