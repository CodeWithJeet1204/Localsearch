import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:localsearch/page/main/vendor/vendor_products_tab_page.dart';
import 'package:localsearch/page/main/vendor/vendor_shorts_tab_page.dart';
import 'package:localsearch/providers/location_provider.dart';
import 'package:localsearch/widgets/loading_indicator.dart';
import 'package:localsearch/widgets/sign_in_dialog.dart';
import 'package:localsearch/widgets/vendor_discounts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:localsearch/page/main/vendor/brand/all_brand_page.dart';
import 'package:localsearch/page/main/vendor/brand/brand_page.dart';
import 'package:localsearch/page/main/vendor/category/all_category_page.dart';
import 'package:localsearch/page/main/vendor/category/category_page.dart';
import 'package:localsearch/page/main/vendor/vendor_catalogue_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/image_show.dart';
import 'package:localsearch/widgets/see_more_text.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:localsearch/widgets/text_button.dart';
import 'package:localsearch/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

enum EventSorting {
  recentlyAdded,
  highestRated,
  mostViewed,
  lowestPrice,
  highestPrice,
}

class VendorPage extends StatefulWidget {
  const VendorPage({
    super.key,
    required this.vendorId,
  });

  final String vendorId;

  @override
  State<VendorPage> createState() => _VendorPageState();
}

class _VendorPageState extends State<VendorPage> with TickerProviderStateMixin {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  Map<String, dynamic>? shopData;
  Map<String, dynamic>? ownerData;
  bool isFollowing = false;
  bool isFollowingLocked = false;
  Map brands = {};
  // Map<String, List> posts = {};
  Map<String, Map<String, dynamic>> shorts = {};
  List? allDiscounts;
  Map<String, dynamic>? categories;
  Map<String, dynamic> products = {};
  String? productSort = 'Recently Added';
  bool isChangingAddress = false;
  String? address;
  double? latitude;
  double? longitude;
  int noOf = 8;
  int? total;
  final scrollController = ScrollController();
  bool isLoadMore = false;

  // INIT STATE
  @override
  void initState() {
    getTotal();
    scrollController.addListener(scrollListener);
    getVendorInfo();
    if (auth.currentUser != null) {
      getIfFollowing();
    }
    getBrands();
    getDiscounts();
    getProducts();
    // getPosts();
    getShorts();
    sortProducts(EventSorting.recentlyAdded);
    super.initState();
    setRecentAndUpdate();
    scrollController.addListener(scrollListener);
  }

  // DID CHANGE DEPENDENCIES
  @override
  void didChangeDependencies() async {
    final locationProvider = Provider.of<LocationProvider>(context);
    final cityLatitude = locationProvider.cityLatitude;
    final cityLongitude = locationProvider.cityLongitude;

    latitude = cityLatitude;
    longitude = cityLongitude;
    await getAddress(latitude!, longitude!, locationProvider);

    super.didChangeDependencies();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // SET RECENT AND UPDATE
  Future<void> setRecentAndUpdate() async {
    if (auth.currentUser != null) {
      await store.collection('Users').doc(auth.currentUser!.uid).update({
        'recentShop': widget.vendorId,
      });
    }

    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    List viewsTimestamp = vendorData['viewsTimestamp'];
    viewsTimestamp.add(DateTime.now());

    await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .update({
      'viewsTimestamp': viewsTimestamp,
    });
  }

  // GET IF FOLLOWING
  Future<void> getIfFollowing() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final userData = userSnap.data()!;
    final following = userData['followedShops'];
    setState(() {
      if ((following as List).contains(widget.vendorId)) {
        isFollowing = true;
      } else {
        isFollowing = false;
      }
    });
  }

  // GET VENDOR INFO
  Future<void> getVendorInfo() async {
    final shopSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final currentShopData = shopSnap.data();

    setState(() {
      shopData = currentShopData;
    });

    final ownerSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Users')
        .doc(widget.vendorId)
        .get();

    final currentOwnerData = ownerSnap.data();

    setState(() {
      ownerData = currentOwnerData;
    });
    await getCategories();
  }

  // FOLLOW SHOP
  Future<void> followShop() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final userData = userSnap.data()!;
    final followedShops = userData['followedShops'] as List;
    if (followedShops.contains(widget.vendorId)) {
      followedShops.remove(widget.vendorId);
    } else {
      followedShops.add(widget.vendorId);
    }
    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'followedShops': followedShops,
    });

    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final vendorData = vendorSnap.data()!;
    Map<String, dynamic> followers = vendorData['followersTimestamp'];

    if (followers.keys.toList().contains(auth.currentUser!.uid)) {
      followers.remove(auth.currentUser!.uid);
    } else {
      followers.addAll({
        auth.currentUser!.uid: DateTime.now(),
      });
    }
    await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .update({
      'followersTimestamp': followers,
    });
    // if (mounted) {
    //   Navigator.of(context).pop();
    //   Navigator.of(context).push(
    //     MaterialPageRoute(
    //       builder: ((context) => VendorPage(
    //             vendorId: widget.vendorId,
    //           )),
    //     ),
    //   );
    // }
  }

  // CALL VENDOR
  Future<void> callVendor() async {
    final Uri url = Uri(
      scheme: 'tel',
      path: ownerData!['Phone Number'],
    );
    print('123');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        mySnackBar('Some error occured', context);
      }
    }
  }

  // GET ADDRESS
  Future<List> getAddress(
    double shopLatitude,
    double shopLongitude,
    LocationProvider locationProvider,
  ) async {
    double? yourLatitude;
    double? yourLongitude;

    yourLatitude = locationProvider.cityLatitude;
    yourLongitude = locationProvider.cityLongitude;

    double? distance = await getDrivingDistance(
      yourLatitude!,
      yourLongitude!,
      shopLatitude,
      shopLongitude,
    );

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

    return [
      address!.length > 30 ? '${address.substring(0, 30)}...' : address,
      distance,
    ];
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

  // GET BRANDS
  Future<void> getBrands() async {
    Map brand = {};
    final brandSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Brands')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    for (var brandData in brandSnap.docs) {
      final id = brandData['brandId'];
      final imageUrl = brandData['imageUrl'];

      brand[id] = imageUrl;
    }

    setState(() {
      brands = brand;
    });
  }

  // GET DISCOUNTS
  Future<void> getDiscounts() async {
    final discountSnapshot = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    List<Map<String, dynamic>> allDiscount = [];

    for (QueryDocumentSnapshot<Map<String, dynamic>> doc
        in discountSnapshot.docs) {
      final data = doc.data();

      if ((data['discountEndDateTime'] as Timestamp)
              .toDate()
              .isAfter(DateTime.now()) &&
          !(data['discountStartDateTime'] as Timestamp)
              .toDate()
              .isAfter(DateTime.now())) {
        allDiscount.add(data);
      }
    }

    setState(() {
      allDiscounts = allDiscount;
    });
  }

  // GET CATEGORIES
  Future<void> getCategories() async {
    Map<String, dynamic> category = {};
    final shopTypes = shopData!['Type'];

    final categoriesSnap = await store
        .collection('Shop Types And Category Data')
        .doc('Category Data')
        .get();

    final categoriesData = categoriesSnap.data()!;

    for (var shopType in shopTypes) {
      final Map<String, dynamic> categoryData =
          categoriesData['householdCategoryData'][shopType];

      category.addAll(categoryData);
    }
    setState(() {
      categories = category;
    });
  }

  // GET PRODUCTS
  Future<void> getProducts() async {
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    Map<String, List<dynamic>> productsData = {};

    for (var productData in productsSnap.docs) {
      final id = productData['productId'];
      final name = productData['productName'];
      final imageUrl = productData['images'][0];
      final price = productData['productPrice'];
      final ratings = productData['ratings'];
      final datetime = productData['datetime'];
      final views = productData['productViewsTimestamp'];
      final data = productData.data();

      productsData[id] = [
        name,
        imageUrl,
        price,
        ratings,
        datetime,
        views,
        data,
      ];
    }

    setState(() {
      products = productsData;
    });
  }

  // GET POSTS
  // Future<void> getPosts() async {
  //   Map<String, List> myPosts = {};
  //   final postsSnap = await store
  //       .collection('Business')
  //       .doc('Data')
  //       .collection('Posts')
  //       .where('postVendorId', isEqualTo: widget.vendorId)
  //       .where('isLinked', isEqualTo: false)
  //       .get();
  //   for (var post in postsSnap.docs) {
  //     final postData = post.data();
  //     final postId = postData['postId'];
  //     final postText = postData['postText'];
  //     final isTextPost = postData['isTextPost'];
  //     final postImage = postData['postImage'];
  //     final postDateTime = postData['postDateTime'];
  //     myPosts[postId] = [
  //       postText,
  //       isTextPost,
  //       postImage,
  //       postDateTime,
  //     ];
  //   }
  //   myPosts = Map.fromEntries(myPosts.entries.toList()
  //     ..sort((a, b) => (b.value[3] as Timestamp).compareTo(a.value[3])));
  //   setState(() {
  //     posts = myPosts;
  //   });
  // }

  // SORT PRODUCTS
  void sortProducts(EventSorting sorting) {
    setState(() {
      switch (sorting) {
        case EventSorting.recentlyAdded:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) => (b.value[4] as Timestamp).compareTo(a.value[4])));
          break;
        case EventSorting.highestRated:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) => calculateAverageRating(b.value[3])
                .compareTo(calculateAverageRating(a.value[3]))));
          break;
        case EventSorting.mostViewed:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) => (b.value[5].length).compareTo(a.value[5].length)));
          break;
        case EventSorting.lowestPrice:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) => double.parse(a.value[2].toString())
                .compareTo(double.parse(b.value[2].toString()))));
          break;
        case EventSorting.highestPrice:
          products = Map.fromEntries(products.entries.toList()
            ..sort((a, b) => double.parse(b.value[2].toString())
                .compareTo(double.parse(a.value[2].toString()))));
          break;
      }
    });
  }

  // CALCULATE AVERAGE RATINGS
  double calculateAverageRating(Map<String, dynamic> ratings) {
    if (ratings.isEmpty) return 0.0;

    final allRatings = ratings.values.map((e) => e[0] as double).toList();

    final sum = allRatings.reduce((value, element) => value + element);

    final averageRating = sum / allRatings.length;

    return averageRating;
  }

  // GET SCREEN HEIGHT
  double getScreenHeight() {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final paddingTop = mediaQuery.padding.top;
    final paddingBottom = mediaQuery.padding.bottom;

    final availableHeight = screenHeight - paddingTop - paddingBottom;
    return availableHeight;
  }

  // TIMEOFDAY TO DATETIME
  DateTime timeOfDayToDateTime(TimeOfDay time, DateTime referenceDate) {
    return DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      time.hour,
      time.minute,
    );
  }

  // GET TIMEOFDAY FROM STRING
  TimeOfDay getTimeOfDay(String timeString) {
    List<String> parts = timeString.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  // IS SHOP OPEN
  Future<bool> isShopOpen() async {
    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    final weekdayStartTime = vendorData['weekdayStartTime'];
    final weekdayEndTime = vendorData['weekdayEndTime'];
    final saturdayStartTime = vendorData['saturdayStartTime'];
    final saturdayEndTime = vendorData['saturdayEndTime'];
    final sundayStartTime = vendorData['sundayStartTime'];
    final sundayEndTime = vendorData['sundayEndTime'];

    final now = DateTime.now();
    final currentTime = timeOfDayToDateTime(TimeOfDay.now(), now);

    switch (now.weekday) {
      case DateTime.monday:
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
      case DateTime.friday:
        if (weekdayStartTime != null && weekdayEndTime != null) {
          final startTime =
              timeOfDayToDateTime(getTimeOfDay(weekdayStartTime), now);
          final endTime =
              timeOfDayToDateTime(getTimeOfDay(weekdayEndTime), now);
          return currentTime.isAfter(startTime) &&
              currentTime.isBefore(endTime);
        }
        break;
      case DateTime.saturday:
        if (saturdayStartTime != null && saturdayEndTime != null) {
          final startTime =
              timeOfDayToDateTime(getTimeOfDay(saturdayStartTime), now);
          final endTime =
              timeOfDayToDateTime(getTimeOfDay(saturdayEndTime), now);
          return currentTime.isAfter(startTime) &&
              currentTime.isBefore(endTime);
        }
        break;
      case DateTime.sunday:
        if (sundayStartTime != null && sundayEndTime != null) {
          final startTime =
              timeOfDayToDateTime(getTimeOfDay(sundayStartTime), now);
          final endTime = timeOfDayToDateTime(getTimeOfDay(sundayEndTime), now);
          return currentTime.isAfter(startTime) &&
              currentTime.isBefore(endTime);
        }
        break;
    }
    return false;
  }

  // FORMAT TIMEOFDAY
  String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dateTime);
  }

  // FIND NEXT OPENING TIME OR CLOSING TIME
  Future<String> findNextOpeningOrClosingTime() async {
    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    final weekdayStartTime = vendorData['weekdayStartTime'];
    final weekdayEndTime = vendorData['weekdayEndTime'];
    final saturdayStartTime = vendorData['saturdayStartTime'];
    final saturdayEndTime = vendorData['saturdayEndTime'];
    final sundayStartTime = vendorData['sundayStartTime'];
    final sundayEndTime = vendorData['sundayEndTime'];

    final now = DateTime.now();
    final currentTime = timeOfDayToDateTime(TimeOfDay.now(), now);

    if (now.weekday >= DateTime.monday && now.weekday <= DateTime.thursday) {
      if (weekdayStartTime != null && weekdayEndTime != null) {
        final startTime =
            timeOfDayToDateTime(getTimeOfDay(weekdayStartTime), now);
        final endTime = timeOfDayToDateTime(getTimeOfDay(weekdayEndTime), now);
        if (currentTime.isAfter(startTime) && currentTime.isBefore(endTime)) {
          return 'Open till ${formatTimeOfDay(getTimeOfDay(weekdayEndTime))} today';
        } else if (currentTime.isBefore(startTime)) {
          return 'Opens at ${formatTimeOfDay(getTimeOfDay(weekdayStartTime))} today';
        } else {
          return 'Opens at ${formatTimeOfDay(getTimeOfDay(weekdayStartTime))} tomorrow';
        }
      }
    }

    if (now.weekday == DateTime.friday) {
      if (weekdayStartTime != null && weekdayEndTime != null) {
        final startTime =
            timeOfDayToDateTime(getTimeOfDay(weekdayStartTime), now);
        final endTime = timeOfDayToDateTime(getTimeOfDay(weekdayEndTime), now);
        if (currentTime.isAfter(startTime) && currentTime.isBefore(endTime)) {
          return 'Open till ${formatTimeOfDay(getTimeOfDay(weekdayEndTime))} today';
        } else if (currentTime.isBefore(startTime)) {
          return 'Opens at ${formatTimeOfDay(getTimeOfDay(weekdayStartTime))} today';
        }
        if (saturdayStartTime != null) {
          return 'Opens at ${formatTimeOfDay(getTimeOfDay(saturdayStartTime))} on Saturday';
        }
        if (sundayStartTime != null) {
          return 'Opens at ${formatTimeOfDay(getTimeOfDay(sundayStartTime))} on Sunday';
        }
      }
    }

    if (now.weekday == DateTime.saturday) {
      if (saturdayStartTime != null && saturdayEndTime != null) {
        final startTime =
            timeOfDayToDateTime(getTimeOfDay(saturdayStartTime), now);
        final endTime = timeOfDayToDateTime(getTimeOfDay(saturdayEndTime), now);
        if (currentTime.isAfter(startTime) && currentTime.isBefore(endTime)) {
          return 'Open till ${formatTimeOfDay(getTimeOfDay(saturdayEndTime))} today';
        } else if (currentTime.isBefore(startTime)) {
          return 'Opens at ${formatTimeOfDay(getTimeOfDay(saturdayStartTime))} on Saturday';
        }
      }
      if (sundayStartTime != null) {
        return 'Opens at ${formatTimeOfDay(getTimeOfDay(sundayStartTime))} on Sunday';
      }
    }

    if (now.weekday == DateTime.sunday) {
      if (sundayStartTime != null && sundayEndTime != null) {
        final startTime =
            timeOfDayToDateTime(getTimeOfDay(sundayStartTime), now);
        final endTime = timeOfDayToDateTime(getTimeOfDay(sundayEndTime), now);
        if (currentTime.isAfter(startTime) && currentTime.isBefore(endTime)) {
          return 'Open till ${formatTimeOfDay(getTimeOfDay(sundayEndTime))} today';
        } else if (currentTime.isBefore(startTime)) {
          return 'Opens at ${formatTimeOfDay(getTimeOfDay(sundayStartTime))} on Sunday';
        }
      }
      if (weekdayStartTime != null) {
        return 'Opens at ${formatTimeOfDay(getTimeOfDay(weekdayStartTime))} on Monday';
      }
    }

    return 'No opening time found within the next week';
  }

  // GET TYPES
  String getTypes(List shopList) {
    String type = '';
    int i = 0;
    int length = shopList.length;
    for (var shopType in shopList) {
      if (i == length - 1) {
        type = type + shopType;
      } else {
        type = '$type$shopType, ';
      }

      i++;
    }

    return type;
  }

  // GET SHORTS
  Future<void> getShorts() async {
    Map<String, Map<String, dynamic>> myShorts = {};
    final shortsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Shorts')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    await Future.wait(shortsSnap.docs.map((short) async {
      final shortsData = short.data();

      final shortsId = short.id;
      final shortsURL = shortsData['shortsURL'];
      final shortsThumbnail = shortsData['shortsThumbnail'];
      final productName = shortsData['productName'];
      final productId = shortsData['productId'];
      final caption = shortsData['caption'];
      final datetime = shortsData['datetime'];
      final vendorId = widget.vendorId;

      myShorts[shortsId] = {
        'shortsId': shortsId,
        'shortsURL': shortsURL,
        'shortsThumbnail': shortsThumbnail,
        'productName': productName,
        'productId': productId,
        'caption': caption,
        'datetime': datetime,
        'vendorId': vendorId,
      };
    }));

    myShorts = Map.fromEntries(
      myShorts.entries.toList()
        ..sort(
          (a, b) => (b.value['datetime'] as Timestamp).compareTo(
            a.value['datetime'],
          ),
        ),
    );

    setState(() {
      shorts = myShorts;
    });
  }

  // SCROLL LISTENER
  Future<void> scrollListener() async {
    if (total != null && noOf < total!) {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        setState(() {
          isLoadMore = true;
        });
        noOf = noOf + 4;
        await getBrands();
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
        .collection('Brands')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    final totalLength = totalSnap.docs.length;

    setState(() {
      total = totalLength;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final TabController tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
      animationDuration: const Duration(milliseconds: 400),
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VendorCataloguePage(
                    vendorId: widget.vendorId,
                    products: shopData!['Products'],
                  ),
                ),
              );
            },
            icon: Icon(FeatherIcons.list),
            tooltip: 'View Catalogue',
          ),
          IconButton(
            onPressed: () async {},
            icon: const Icon(FeatherIcons.share2),
            tooltip: 'Share Shop',
          ),
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
      ),
      body: shopData == null || ownerData == null
          ? const Center(
              child: LoadingIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width * 0.00625,
                ),
                child: LayoutBuilder(builder: ((context, constraints) {
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
                          // SHOP INFO
                          Container(
                            width: width,
                            decoration: BoxDecoration(
                              color: white,
                            ),
                            padding: EdgeInsets.all(width * 0.006125),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // IMAGE
                                    GestureDetector(
                                      onTap: () async {
                                        await showDialog(
                                          context: context,
                                          builder: ((context) => ImageShow(
                                                imageUrl: shopData!['Image'],
                                                width: width,
                                              )),
                                        );
                                      },
                                      child: CircleAvatar(
                                        radius: width * 0.1,
                                        backgroundImage: NetworkImage(
                                          shopData!['Image'].toString().trim(),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: width * 0.725,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // NAME
                                          Text(
                                            shopData!['Name'].toString().trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: primaryDark,
                                              fontSize: width * 0.05,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),

                                          // TYPE
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      VendorCataloguePage(
                                                    vendorId: widget.vendorId,
                                                    products:
                                                        shopData!['Products'],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              getTypes(shopData!['Type'])
                                                  .toString()
                                                  .trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                fontSize: width * 0.04,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: width * 0.0125),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: width * 0.045),

                                // // VIEW CATALOGUE
                                // (shopData!['Products'] as List).isEmpty
                                //     ? Container()
                                //     : MyTextButton(
                                //         onPressed: () {
                                //           Navigator.of(context).push(
                                //             MaterialPageRoute(
                                //               builder: (context) =>
                                //                   VendorCataloguePage(
                                //                 vendorId: widget.vendorId,
                                //                 products: shopData!['Products'],
                                //               ),
                                //             ),
                                //           );
                                //         },
                                //         text: 'View Catalogue',
                                //         textColor: primaryDark,
                                //       ),

                                // OPEN STATUS
                                FutureBuilder(
                                    future: isShopOpen(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Container();
                                      }

                                      if (snapshot.hasData) {
                                        final isOpen = snapshot.data!;

                                        return SizedBox(
                                          width: width,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    12,
                                                  ),
                                                  border: Border.all(
                                                    width: 2,
                                                    color: isOpen &&
                                                            shopData!['Open']
                                                        ? Colors.green
                                                            .withOpacity(0.2)
                                                        : Colors.red
                                                            .withOpacity(0.2),
                                                  ),
                                                ),
                                                padding: EdgeInsets.all(
                                                  width * 0.0225,
                                                ),
                                                child: Text(
                                                  isOpen && shopData!['Open']
                                                      ? 'OPEN'
                                                      : 'CLOSED',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: isOpen &&
                                                            shopData!['Open']
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontSize: width * 0.04,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              FutureBuilder(
                                                future:
                                                    findNextOpeningOrClosingTime(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasError) {
                                                    return Container();
                                                  }

                                                  if (snapshot.hasData) {
                                                    final text = snapshot.data!;

                                                    return SizedBox(
                                                      width: width * 0.66,
                                                      child: Text(
                                                        text.toString().trim(),
                                                        maxLines: 3,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    );
                                                  }

                                                  return Container();
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return Container();
                                    }),
                                SizedBox(height: width * 0.04),

                                // SOCIAL MEDIA
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // WHATSAPP
                                    ownerData!['Phone Number'] == ''
                                        ? Container()
                                        : Expanded(
                                            child: GestureDetector(
                                              onTap: () async {
                                                if (ownerData!['allowChats']) {
                                                  final String phoneNumber =
                                                      ownerData![
                                                          'Phone Number'];
                                                  const String message =
                                                      'Hey, I found you on Localsearch\n';
                                                  final url =
                                                      'https://wa.me/$phoneNumber?text=$message';

                                                  print('url: $url');

                                                  if (await canLaunchUrl(
                                                      Uri.parse(url))) {
                                                    await launchUrl(
                                                        Uri.parse(url));
                                                  } else {
                                                    if (context.mounted) {
                                                      mySnackBar(
                                                        'Something went Wrong',
                                                        context,
                                                      );
                                                    }
                                                  }
                                                } else {
                                                  return mySnackBar(
                                                    'Vendor does not allows to chat with them.',
                                                    context,
                                                  );
                                                }
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.00625,
                                                ),
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: width * 0.0125,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: white,
                                                  border: Border.all(
                                                    color: primaryDark,
                                                    width: 0.25,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      FeatherIcons
                                                          .messageCircle,
                                                      size: width * 0.05,
                                                      color:
                                                          const Color.fromARGB(
                                                        255,
                                                        0,
                                                        208,
                                                        7,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                    // INSTAGRAM
                                    shopData!['Instagram'] == ''
                                        ? Container()
                                        : Expanded(
                                            child: GestureDetector(
                                              onTap: () async {
                                                String url =
                                                    shopData!['Instagram'];

                                                if (!url.startsWith(
                                                        'http://') &&
                                                    !url.startsWith(
                                                        'https://')) {
                                                  url = 'https://$url';
                                                }

                                                if (await canLaunchUrl(
                                                    Uri.parse(url))) {
                                                  await launchUrl(
                                                      Uri.parse(url));
                                                } else {
                                                  if (context.mounted) {
                                                    mySnackBar(
                                                      'Something went Wrong',
                                                      context,
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.00625,
                                                ),
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: width * 0.0125,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: white,
                                                  border: Border.all(
                                                    color: primaryDark,
                                                    width: 0.25,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      FeatherIcons.instagram,
                                                      size: width * 0.05,
                                                      color: Colors.red,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                    // FACEBOOK
                                    shopData!['Facebook'] == ''
                                        ? Container()
                                        : Expanded(
                                            child: GestureDetector(
                                              onTap: () async {
                                                String url =
                                                    shopData!['Facebook'];

                                                if (!url.startsWith(
                                                        'http://') &&
                                                    !url.startsWith(
                                                        'https://')) {
                                                  url = 'https://$url';
                                                }

                                                if (await canLaunchUrl(
                                                    Uri.parse(url))) {
                                                  await launchUrl(
                                                      Uri.parse(url));
                                                } else {
                                                  if (context.mounted) {
                                                    mySnackBar(
                                                      'Something went Wrong',
                                                      context,
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.00625,
                                                ),
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: width * 0.0125,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: white,
                                                  border: Border.all(
                                                    color: primaryDark,
                                                    width: 0.25,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      FeatherIcons.facebook,
                                                      size: width * 0.05,
                                                      color: Color.fromRGBO(
                                                        24,
                                                        119,
                                                        242,
                                                        1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                    // WEBSITE
                                    shopData!['Website'] == ''
                                        ? Container()
                                        : Expanded(
                                            child: GestureDetector(
                                              onTap: () async {
                                                String url =
                                                    shopData!['Website'];

                                                if (!url.startsWith(
                                                        'http://') &&
                                                    !url.startsWith(
                                                        'https://')) {
                                                  url = 'https://$url';
                                                }

                                                if (await canLaunchUrl(
                                                    Uri.parse(url))) {
                                                  await launchUrl(
                                                      Uri.parse(url));
                                                } else {
                                                  if (context.mounted) {
                                                    mySnackBar(
                                                      'Something went Wrong',
                                                      context,
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.00625,
                                                ),
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: width * 0.0125,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: white,
                                                  border: Border.all(
                                                    color: primaryDark,
                                                    width: 0.25,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      FeatherIcons.globe,
                                                      size: width * 0.05,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                                SizedBox(height: width * 0.025),

                                // FOLLOW & CALL
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // FOLLOW
                                    Expanded(
                                      flex: 3,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (auth.currentUser != null) {
                                            await followShop();
                                            await getIfFollowing();
                                          } else {
                                            await showSignInDialog(context);
                                          }
                                        },
                                        child: Container(
                                          width: width * 0.6875,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isFollowing
                                                ? primary2.withOpacity(0.5)
                                                : primary2.withOpacity(0.5),
                                            border: Border.all(
                                              color:
                                                  isFollowing ? black : white,
                                              width: 0.75,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          margin: EdgeInsets.symmetric(
                                            horizontal: width * 0.006125,
                                          ),
                                          child: Text(
                                            isFollowing
                                                ? 'Following'
                                                : 'Follow',
                                            style: TextStyle(
                                              color: primaryDark,
                                              fontWeight: isFollowing
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // CALL
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (ownerData!['allowCalls']) {
                                            await callVendor();
                                          } else {
                                            return mySnackBar(
                                              'Vendor does not allows to call them.',
                                              context,
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: width * 0.25,
                                          height: 40,
                                          alignment: Alignment.center,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.00625,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.5),
                                            border: Border.all(
                                              color: primaryDark,
                                              width: 0.25,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          margin: EdgeInsets.symmetric(
                                            horizontal: width * 0.006125,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Call',
                                                style: TextStyle(
                                                  color: primaryDark,
                                                ),
                                              ),
                                              Icon(FeatherIcons.phone),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                Divider(),

                                // ADDRESS
                                shopData!['Address'] == ''
                                    ? Container()
                                    : Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.025,
                                        ),
                                        child: Text(
                                          shopData!['Address']
                                              .toString()
                                              .trim(),
                                        ),
                                      ),

                                // LOCATION
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                  ),
                                  child: FutureBuilder(
                                      future: getAddress(
                                        shopData!['Latitude']!,
                                        shopData!['Longitude']!,
                                        locationProvider,
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Center(
                                            child: Text(
                                              'Something went wrong while finding Location',
                                            ),
                                          );
                                        }

                                        if (snapshot.hasData) {
                                          return GestureDetector(
                                            onTap: () async {
                                              Uri mapsUrl = Uri.parse(
                                                  'https://www.google.com/maps/search/?api=1&query=${shopData!['Latitude']},${shopData!['Longitude']}');

                                              if (await canLaunchUrl(mapsUrl)) {
                                                await launchUrl(mapsUrl);
                                              } else {
                                                if (context.mounted) {
                                                  mySnackBar(
                                                    'Something went wrong',
                                                    context,
                                                  );
                                                }
                                              }
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  shopData!['Address'] == ''
                                                      ? CrossAxisAlignment
                                                          .center
                                                      : CrossAxisAlignment
                                                          .start,
                                              children: [
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width: width * 0.8,
                                                      child: Text(
                                                        snapshot.data![0]
                                                            .toString()
                                                            .trim(),
                                                      ),
                                                    ),
                                                    Text(
                                                      snapshot.data![1] == null
                                                          ? '-- km'
                                                          : '${snapshot.data![1]} km',
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    Uri mapsUrl = Uri.parse(
                                                      'https://www.google.com/maps/search/?api=1&query=${shopData!['Latitude']},${shopData!['Longitude']}',
                                                    );

                                                    if (await canLaunchUrl(
                                                      mapsUrl,
                                                    )) {
                                                      await launchUrl(
                                                        mapsUrl,
                                                      );
                                                    } else {
                                                      if (context.mounted) {
                                                        mySnackBar(
                                                          'Something went wrong while finding Location',
                                                          context,
                                                        );
                                                      }
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    FeatherIcons.mapPin,
                                                  ),
                                                  tooltip: 'Locate on Maps',
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.0125,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: width * 0.8,
                                                    child: const Text(
                                                      'Getting Location',
                                                    ),
                                                  ),
                                                  const Text('-- km'),
                                                ],
                                              ),
                                              Icon(
                                                FeatherIcons.mapPin,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                ),

                                SizedBox(height: width * 0.033),

                                // MORE INFO
                                ExpansionTile(
                                  title: Text(
                                    'More Info',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: width * 0.045,
                                    ),
                                  ),
                                  initiallyExpanded: false,
                                  tilePadding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  backgroundColor: white,
                                  collapsedBackgroundColor: white,
                                  textColor: primaryDark.withOpacity(0.9),
                                  collapsedTextColor: primaryDark,
                                  iconColor: primaryDark2.withOpacity(0.9),
                                  collapsedIconColor: primaryDark2,
                                  shape: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: white,
                                    ),
                                  ),
                                  collapsedShape: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: white,
                                    ),
                                  ),
                                  children: [
                                    // NAME
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                        vertical: width * 0.0175,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: width * 0.8,
                                            child: Text(
                                              ownerData!['Name']
                                                  .toString()
                                                  .trim(),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              right: width * 0.04,
                                            ),
                                            child:
                                                const Icon(FeatherIcons.user),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: width * 0.033),

                                    // FOLLOWERS
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                        vertical: width * 0.0175,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Followers',
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              right: width * 0.0575,
                                            ),
                                            child: Text(
                                              (shopData!['followersTimestamp']
                                                      as Map)
                                                  .length
                                                  .toString()
                                                  .toString()
                                                  .trim(),
                                              style: TextStyle(
                                                color: primaryDark,
                                                fontSize: width * 0.05,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: width * 0.033),

                                    // PRODUCTS
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                        vertical: width * 0.0175,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Total Products',
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              right: width * 0.0575,
                                            ),
                                            child: Text(
                                              products.length
                                                  .toString()
                                                  .toString()
                                                  .trim(),
                                              style: TextStyle(
                                                color: primaryDark,
                                                fontSize: width * 0.05,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: width * 0.033),

                                    // INDUSTRY
                                    // Padding(
                                    //   padding: EdgeInsets.symmetric(
                                    //     horizontal: width * 0.0125,
                                    //     vertical: width * 0.0175,
                                    //   ),
                                    //   child: Row(
                                    //     mainAxisAlignment:
                                    //         MainAxisAlignment.spaceBetween,
                                    //     crossAxisAlignment:
                                    //         CrossAxisAlignment.center,
                                    //     children: [
                                    //       SizedBox(
                                    //         width: width * 0.8,
                                    //         child: Text(
                                    //           shopData!['Industry'],
                                    //         ),
                                    //       ),
                                    //       Padding(
                                    //         padding: EdgeInsets.only(
                                    //           right: width * 0.034,
                                    //         ),
                                    //         child: const Icon(
                                    //           Icons.factory_outlined,
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                    // SizedBox(height: width * 0.033),

                                    // DESCRIPTION
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: width * 0.015,
                                          ),
                                          child: SizedBox(
                                            width: width * 0.85,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: SeeMoreText(
                                                shopData!['Description']
                                                    .toString()
                                                    .trim(),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                            right: width * 0.04,
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            size: width * 0.075,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const Divider(),
                              ],
                            ),
                          ),

                          // DISCOUNT
                          allDiscounts == null || allDiscounts!.isEmpty
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: width * 0.01,
                                    horizontal: width * 0.0125,
                                  ),
                                  child: Text(
                                    'Offers',
                                    style: TextStyle(
                                      fontSize: width * 0.0425,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                          // DISCOUNTS
                          allDiscounts == null || allDiscounts!.isEmpty
                              ? Container()
                              : VendorDiscounts(
                                  noOfDiscounts: allDiscounts!.length,
                                  allDiscount: allDiscounts!,
                                  vendorType: shopData!['Type'],
                                ),

                          allDiscounts == null || allDiscounts!.isEmpty
                              ? Container()
                              : const Divider(),

                          // BRAND
                          brands.isEmpty
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: width * 0.01,
                                    horizontal: width * 0.0125,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Brands',
                                        style: TextStyle(
                                          fontSize: width * 0.0425,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      brands.length <= 3
                                          ? Container()
                                          : MyTextButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: ((context) =>
                                                        AllBrandPage(
                                                          vendorId:
                                                              widget.vendorId,
                                                        )),
                                                  ),
                                                );
                                              },
                                              text: 'See All',
                                              textColor: primaryDark,
                                            ),
                                    ],
                                  ),
                                ),

                          // BRANDS
                          brands.isEmpty
                              ? Container()
                              : Container(
                                  width: width,
                                  height: width * 0.2,
                                  margin: EdgeInsets.all(width * 0.00125),
                                  padding: EdgeInsets.all(width * 0.00125),
                                  child: ListView.builder(
                                    controller: scrollController,
                                    cacheExtent: height * 1.5,
                                    addAutomaticKeepAlives: true,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    physics: ClampingScrollPhysics(),
                                    itemCount: isLoadMore
                                        ? brands.length + 1
                                        : brands.length,
                                    itemBuilder: ((context, index) {
                                      final id = brands.keys.toList()[isLoadMore
                                          ? index == 0
                                              ? 0
                                              : index - 1
                                          : index];
                                      final imageUrl =
                                          brands.values.toList()[isLoadMore
                                              ? index == 0
                                                  ? 0
                                                  : index - 1
                                              : index];

                                      return index <= brands.length
                                          ? GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: ((context) =>
                                                        BrandPage(
                                                          brandId: id,
                                                        )),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: width * 0.2,
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: width * 0.0125,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    4,
                                                  ),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      imageUrl
                                                          .toString()
                                                          .trim(),
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : isLoadMore
                                              ? SizedBox(
                                                  height: 45,
                                                  child: Center(
                                                    child: LoadingIndicator(),
                                                  ),
                                                )
                                              : Container();
                                    }),
                                  ),
                                ),

                          brands.isEmpty ? Container() : const Divider(),

                          // CATEGORY
                          categories == null || categories!.isEmpty
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Categories',
                                        style: TextStyle(
                                          fontSize: width * 0.0425,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      categories!.length <= 8
                                          ? Container()
                                          : MyTextButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: ((context) =>
                                                        AllCategoryPage(
                                                          categoryData:
                                                              categories!,
                                                        )),
                                                  ),
                                                );
                                              },
                                              text: 'See All',
                                              textColor: primaryDark,
                                            ),
                                    ],
                                  ),
                                ),

                          // CATEGORIES
                          categories == null || categories!.isEmpty
                              ? Container()
                              : Container(
                                  width: width,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: width * 0.0125,
                                  ),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      childAspectRatio: 0.875,
                                    ),
                                    itemCount: categories!.length > 8
                                        ? 8
                                        : categories!.length,
                                    itemBuilder: ((context, index) {
                                      final name =
                                          categories!.keys.toList()[index];
                                      final imageUrl =
                                          categories!.values.toList()[index];

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) =>
                                                  CategoryPage(
                                                    categoryName: name,
                                                  )),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              imageUrl.toString().trim(),
                                              width: width * 0.175,
                                              height: width * 0.175,
                                              fit: BoxFit.cover,
                                            ),
                                            Text(
                                              name.toString().trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: width * 0.035,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                          categories == null
                              ? Container()
                              : categories!.isEmpty
                                  ? Container()
                                  : const Divider(),

                          // TABS
                          TabBar(
                            indicator: BoxDecoration(
                              color: primary2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: primaryDark.withOpacity(0.8),
                              ),
                            ),
                            isScrollable: false,
                            indicatorPadding: EdgeInsets.only(
                              bottom: MediaQuery.sizeOf(context).width * 0.0266,
                              top: MediaQuery.sizeOf(context).width * 0.0225,
                              left: -MediaQuery.sizeOf(context).width * 0.045,
                              right: -MediaQuery.sizeOf(context).width * 0.045,
                            ),
                            automaticIndicatorColorAdjustment: false,
                            indicatorWeight: 2,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: primaryDark,
                            labelStyle: const TextStyle(
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              letterSpacing: 0,
                              fontWeight: FontWeight.w500,
                            ),
                            dividerColor: primary,
                            indicatorColor: primaryDark,
                            controller: tabController,
                            tabs: const [
                              Tab(
                                text: 'PRODUCTS',
                              ),
                              // Tab(
                              //   text: 'POSTS',
                              // ),
                              Tab(
                                text: 'SHORTS',
                              ),
                            ],
                          ),

                          SizedBox(
                            width: width,
                            height: getScreenHeight() * 0.8,
                            child: TabBarView(
                              controller: tabController,
                              children: [
                                VendorProductsTabPage(
                                  width: width,
                                  myProducts: products,
                                  myProductSort: productSort,
                                  height: constraints.maxHeight,
                                ),
                                // VendorPostsTabPage(
                                //   posts: posts,
                                //   width: width,
                                // ),
                                VendorShortsTabPage(
                                  width: width,
                                  shorts: shorts,
                                ),
                              ],
                            ),
                          ),

                          // PRODUCT & FILTER
                        ],
                      ),
                    ),
                  );
                })),
              ),
            ),
    );
  }
}
