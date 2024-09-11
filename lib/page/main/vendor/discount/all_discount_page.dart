import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:localsearch_user/page/main/vendor/discount/discount_page.dart';
import 'package:localsearch_user/page/main/location_change_page.dart';
import 'package:localsearch_user/providers/location_provider.dart';
import 'package:localsearch_user/utils/colors.dart';
import 'package:localsearch_user/widgets/shimmer_skeleton_container.dart';
import 'package:localsearch_user/widgets/snack_bar.dart';
import 'package:provider/provider.dart';

class AllDiscountPage extends StatefulWidget {
  const AllDiscountPage({super.key});

  @override
  State<AllDiscountPage> createState() => _AllDiscountPageState();
}

class _AllDiscountPageState extends State<AllDiscountPage> {
  final store = FirebaseFirestore.instance;
  Map<String, Map<String, dynamic>> allDiscounts = {};
  Map<String, Map<String, dynamic>> currentDiscounts = {};
  final searchController = TextEditingController();
  double distanceRange = 5;
  bool isGridView = true;
  bool isData = false;
  int noOfListView = 4;
  int? totalListView;
  bool isLoadMoreListView = false;
  final scrollControllerListView = ScrollController();
  int noOfGridView = 4;
  int? totalGridView;
  bool isLoadMoreGridView = false;
  final scrollControllerGridView = ScrollController();

  // DID CHANGE DEPENDENCIES
  @override
  void didChangeDependencies() {
    getTotal();
    scrollControllerListView.addListener(scrollListenerListView);
    scrollControllerGridView.addListener(scrollListenerGridView);
    final locationProvider = Provider.of<LocationProvider>(context);
    getDiscounts(locationProvider);
    super.didChangeDependencies();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollControllerListView.dispose();
    searchController.dispose();
    super.dispose();
  }

  // GET DATA
  Future<void> getDiscounts(LocationProvider locationProvider) async {
    Map<String, Map<String, dynamic>> myDiscounts = {};
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .limit(isGridView ? noOfGridView : noOfListView)
        .get();

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
      yourLatitude = locationProvider.cityLatitude;
      yourLongitude = locationProvider.cityLongitude;

      await Future.forEach(
        discountSnap.docs,
        (discount) async {
          final discountData = discount.data();

          final discountId = discount.id;
          final Timestamp endDateTime = discountData['discountEndDateTime'];
          final vendorLatitude = discountData['Latitude'];
          final vendorLongitude = discountData['Longitude'];
          double? distance;

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
              if (endDateTime.toDate().isAfter(DateTime.now())) {
                discountData.addAll({
                  'distance': distance,
                });
                myDiscounts[discountId] = discountData;
              }
            }
          }
        },
      );

      if (mounted) {
        setState(() {
          currentDiscounts = myDiscounts;
          allDiscounts = myDiscounts;
          isData = true;
        });
      }
    } else {
      try {
        await Future.forEach(
          discountSnap.docs,
          (discount) async {
            final discountData = discount.data();

            final discountId = discount.id;
            final Timestamp endDateTime = discountData['discountEndDateTime'];
            final cityName = discountData['City'];

            if (cityName == locationProvider.cityName) {
              if (endDateTime.toDate().isAfter(DateTime.now())) {
                myDiscounts[discountId] = discountData;
              }
            }
          },
        );

        setState(() {
          currentDiscounts = myDiscounts;
          allDiscounts = myDiscounts;
          isData = true;
        });
      } catch (e) {
        if (mounted) {
          mySnackBar(
            'Failed to fetch your City: ${e.toString()}',
            context,
          );
        }
      }
    }
  }

  // UPDATE DISCOUNTS
  void updateDiscounts(double endDistance) {
    Map<String, Map<String, dynamic>> tempDiscounts = {};
    allDiscounts.forEach((key, value) {
      final double distance = value['distance'];
      if (distance * 0.925 <= endDistance) {
        tempDiscounts[key] = value;
      }
    });
    setState(() {
      currentDiscounts = tempDiscounts;
    });
  }

  // SCROLL LISTENER LIST VIEW
  Future<void> scrollListenerListView() async {
    if (totalListView != null && noOfListView < totalListView!) {
      if (scrollControllerListView.position.pixels ==
          scrollControllerListView.position.maxScrollExtent) {
        final locationProvider = Provider.of<LocationProvider>(
          context,
          listen: false,
        );
        setState(() {
          isLoadMoreListView = true;
        });
        noOfListView = noOfListView + 4;
        await getDiscounts(locationProvider);
        setState(() {
          isLoadMoreListView = false;
        });
      }
    }
  }

  // SCROLL LISTENER GRID VIEW
  Future<void> scrollListenerGridView() async {
    if (totalGridView != null && noOfGridView < totalGridView!) {
      if (scrollControllerGridView.position.pixels ==
          scrollControllerGridView.position.maxScrollExtent) {
        final locationProvider = Provider.of<LocationProvider>(
          context,
          listen: false,
        );
        setState(() {
          isLoadMoreGridView = true;
        });
        noOfGridView = noOfGridView + 4;
        await getDiscounts(locationProvider);
        setState(() {
          isLoadMoreGridView = false;
        });
      }
    }
  }

  // GET TOTAL
  Future<void> getTotal() async {
    final totalSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .get();

    final totalLength = totalSnap.docs.length;

    setState(() {
      totalListView = totalLength;
      totalGridView = totalLength;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Discounts',
        ),
        bottom: PreferredSize(
          preferredSize: Size(width, width * 0.2),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.0166,
              vertical: MediaQuery.of(context).size.width * 0.0225,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
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
                          currentDiscounts =
                              Map<String, Map<String, dynamic>>.from(
                            allDiscounts,
                          );
                        } else {
                          Map<String, Map<String, dynamic>> filteredDiscounts =
                              Map<String, Map<String, dynamic>>.from(
                            allDiscounts,
                          );
                          List<String> keysToRemove = [];

                          filteredDiscounts.forEach((key, discountData) {
                            if (!discountData['discountName']
                                .toString()
                                .toLowerCase()
                                .contains(value.toLowerCase().trim())) {
                              keysToRemove.add(key);
                            }
                          });

                          for (var key in keysToRemove) {
                            filteredDiscounts.remove(key);
                          }

                          setState(() {
                            currentDiscounts = filteredDiscounts;
                          });
                        }
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isGridView = !isGridView;
                    });
                  },
                  icon: Icon(
                    isGridView ? FeatherIcons.list : FeatherIcons.grid,
                  ),
                  tooltip: isGridView ? 'List View' : 'Grid View',
                ),
              ],
            ),
          ),
        ),
      ),
      body: !isData
          ? SafeArea(
              child: GridView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                childAspectRatio: 14 / 9,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.all(
                    width * 0.02,
                  ),
                  child: GridViewSkeleton(
                    width: width,
                    isPrice: true,
                    isDelete: false,
                    isDiscount: true,
                  ),
                );
              },
            ))
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(width * 0.006125),
                child: LayoutBuilder(
                  builder: ((context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    return NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                          isGridView
                              ? scrollListenerGridView()
                              : scrollListenerGridView();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SELECT LOCATION
                            Padding(
                              padding: EdgeInsets.all(width * 0.0225),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LocationChangePage(
                                        page: AllDiscountPage(),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  locationProvider.cityName == null ||
                                          locationProvider.cityName ==
                                              'Your Location'
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
                                    padding:
                                        EdgeInsets.only(left: width * 0.025),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Slider(
                                          min: 0,
                                          max: 50,
                                          divisions: 20,
                                          value: distanceRange,
                                          activeColor: primaryDark,
                                          inactiveColor: const Color.fromRGBO(
                                            197,
                                            243,
                                            255,
                                            1,
                                          ),
                                          onChanged: (newValue) {
                                            setState(() {
                                              isData = false;
                                              distanceRange = newValue;
                                            });
                                            updateDiscounts(distanceRange);
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
                                                  .replaceFirst(
                                                      '.500000000000004', '.5')
                                              : distanceRange
                                                      .toString()
                                                      .endsWith('0')
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

                            currentDiscounts.isEmpty
                                ? const SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: Text('No Discounts'),
                                    ),
                                  )
                                : isGridView
                                    ? SizedBox(
                                        width: width,
                                        child: GridView.builder(
                                          controller: scrollControllerGridView,
                                          cacheExtent: height * 1.5,
                                          addAutomaticKeepAlives: true,
                                          shrinkWrap: true,
                                          physics:
                                              const ClampingScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 1,
                                            childAspectRatio: 16 / 11,
                                          ),
                                          itemCount: currentDiscounts.length,
                                          itemBuilder: ((context, index) {
                                            final discountData =
                                                currentDiscounts[
                                                    currentDiscounts.keys
                                                            .toList()[
                                                        isLoadMoreGridView
                                                            ? index - 1
                                                            : index]]!;

                                            // DISCOUNT CONTAINER
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: ((context) =>
                                                        DiscountPage(
                                                          discountId:
                                                              discountData[
                                                                  'discountId'],
                                                        )),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: white,
                                                  border: Border.all(
                                                    width: 0.25,
                                                    color: primaryDark,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                                margin: EdgeInsets.all(
                                                  width * 0.00625,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // IMAGE
                                                    discountData[
                                                                'discountImageUrl'] !=
                                                            null
                                                        ? Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                              width * 0.00625,
                                                            ),
                                                            child: Center(
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            2),
                                                                child: Image
                                                                    .network(
                                                                  discountData[
                                                                      'discountImageUrl'],
                                                                  width: width,
                                                                  height: width *
                                                                      0.4125,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              ),
                                                            ),
                                                          )

                                                        // NO IMAGE
                                                        : Column(
                                                            children: [
                                                              SizedBox(
                                                                width: width,
                                                                height: width *
                                                                    0.375,
                                                                child:
                                                                    const Center(
                                                                  child: Text(
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    'No Image',
                                                                    style:
                                                                        TextStyle(
                                                                      color:
                                                                          primaryDark2,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const Divider(),
                                                            ],
                                                          ),

                                                    // INFO & OPTIONS
                                                    Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // NAME
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                            left: width * 0.01,
                                                            top: width * 0.01,
                                                          ),
                                                          child: Text(
                                                            discountData[
                                                                'discountName'],
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color:
                                                                  primaryDark,
                                                              fontSize:
                                                                  width * 0.06,
                                                            ),
                                                          ),
                                                        ),

                                                        // DISCOUNT & TIME
                                                        Row(
                                                          children: [
                                                            // DISCOUNT
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .only(
                                                                left: width *
                                                                    0.01,
                                                                top: width *
                                                                    0.01,
                                                              ),
                                                              child: Text(
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                discountData[
                                                                        'isPercent']
                                                                    ? '${discountData['discountAmount']}% off'
                                                                    : 'Rs. ${discountData['discountAmount']} off',
                                                                style:
                                                                    TextStyle(
                                                                  color: const Color
                                                                      .fromRGBO(
                                                                    0,
                                                                    72,
                                                                    2,
                                                                    1,
                                                                  ),
                                                                  fontSize:
                                                                      width *
                                                                          0.045,
                                                                ),
                                                              ),
                                                            ),

                                                            // TEXT DIVIDER
                                                            const Text(
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              '  ●  ',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w100,
                                                              ),
                                                            ),

                                                            // TIME
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .only(
                                                                left: width *
                                                                    0.01,
                                                                top: width *
                                                                    0.01,
                                                              ),
                                                              child: Text(
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                (discountData['discountStartDateTime']
                                                                            as Timestamp)
                                                                        .toDate()
                                                                        .isAfter(DateTime
                                                                            .now())
                                                                    ? (discountData['discountStartDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours <
                                                                            24
                                                                        ? 'After ${(discountData['discountStartDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours} Hours'
                                                                        : 'After ${(discountData['discountStartDateTime'] as Timestamp).toDate().difference(DateTime.now()).inDays} Days'
                                                                    : (discountData['discountEndDateTime']
                                                                                as Timestamp)
                                                                            .toDate()
                                                                            .isAfter(DateTime
                                                                                .now())
                                                                        ? (discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours <
                                                                                24
                                                                            ? '${(discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours} Hours left'
                                                                            : '${(discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inDays} Days left'
                                                                        : DateTime.now().difference((discountData['discountEndDateTime'] as Timestamp).toDate()).inHours <
                                                                                24
                                                                            ? 'Expired ${DateTime.now().difference((discountData['discountEndDateTime'] as Timestamp).toDate()).inHours} Hours Ago'
                                                                            : 'Expired ${DateTime.now().difference((discountData['discountEndDateTime'] as Timestamp).toDate()).inDays} Days Ago',
                                                                style:
                                                                    TextStyle(
                                                                  color: const Color
                                                                      .fromRGBO(
                                                                    211,
                                                                    80,
                                                                    71,
                                                                    1,
                                                                  ),
                                                                  fontSize:
                                                                      width *
                                                                          0.045,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
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
                                        child: ListView.builder(
                                          controller: scrollControllerListView,
                                          cacheExtent: height * 1.5,
                                          addAutomaticKeepAlives: true,
                                          shrinkWrap: true,
                                          physics:
                                              const ClampingScrollPhysics(),
                                          itemCount: isLoadMoreListView
                                              ? currentDiscounts.length + 1
                                              : currentDiscounts.length,
                                          itemBuilder: ((context, index) {
                                            final discountData =
                                                currentDiscounts[
                                                    currentDiscounts.keys
                                                            .toList()[
                                                        isLoadMoreListView
                                                            ? index - 1
                                                            : index]]!;

                                            return index <=
                                                    currentDiscounts.length
                                                ? GestureDetector(
                                                    onTap: () {
                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                          builder: ((context) =>
                                                              DiscountPage(
                                                                discountId:
                                                                    discountData[
                                                                        'discountId'],
                                                              )),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: white,
                                                        border: Border.all(
                                                          width: 0.5,
                                                          color: primaryDark,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(2),
                                                      ),
                                                      margin: EdgeInsets.all(
                                                        width * 0.0125,
                                                      ),
                                                      child: ListTile(
                                                        visualDensity:
                                                            VisualDensity
                                                                .comfortable,
                                                        leading: discountData[
                                                                    'discountImageUrl'] !=
                                                                null
                                                            ? ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  2,
                                                                ),
                                                                child: Image
                                                                    .network(
                                                                  discountData[
                                                                      'discountImageUrl'],
                                                                  width: width *
                                                                      0.15,
                                                                  height:
                                                                      width *
                                                                          0.15,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              )
                                                            : SizedBox(
                                                                width: width *
                                                                    0.15,
                                                                height: width *
                                                                    0.15,
                                                                child:
                                                                    const Center(
                                                                  child: Text(
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    'No Image',
                                                                    style:
                                                                        TextStyle(
                                                                      color:
                                                                          primaryDark2,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),

                                                        // NAME
                                                        title: Text(
                                                          discountData[
                                                              'discountName'],
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize:
                                                                width * 0.05,
                                                          ),
                                                        ),

                                                        // DISCOUNT &  TIME
                                                        subtitle: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            // DISCOUNT
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .only(
                                                                left: width *
                                                                    0.01,
                                                                top: width *
                                                                    0.01,
                                                              ),
                                                              child: Text(
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                discountData[
                                                                        'isPercent']
                                                                    ? '${discountData['discountAmount']}% off'
                                                                    : 'Rs. ${discountData['discountAmount']} off',
                                                                style:
                                                                    TextStyle(
                                                                  color: const Color
                                                                      .fromRGBO(
                                                                    0,
                                                                    72,
                                                                    2,
                                                                    1,
                                                                  ),
                                                                  fontSize:
                                                                      width *
                                                                          0.035,
                                                                ),
                                                              ),
                                                            ),

                                                            // TEXT DIVIDER
                                                            const Text(
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              '  ●  ',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w100,
                                                              ),
                                                            ),

                                                            // TIME
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .only(
                                                                left: width *
                                                                    0.01,
                                                                top: width *
                                                                    0.01,
                                                              ),
                                                              child: Text(
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                (discountData['discountStartDateTime']
                                                                            as Timestamp)
                                                                        .toDate()
                                                                        .isAfter(DateTime
                                                                            .now())
                                                                    ? (discountData['discountStartDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours <
                                                                            24
                                                                        ? 'After ${(discountData['discountStartDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours} Hours'
                                                                        : 'After ${(discountData['discountStartDateTime'] as Timestamp).toDate().difference(DateTime.now()).inDays} Days'
                                                                    : (discountData['discountEndDateTime']
                                                                                as Timestamp)
                                                                            .toDate()
                                                                            .isAfter(DateTime
                                                                                .now())
                                                                        ? (discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours <
                                                                                24
                                                                            ? '${(discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours} Hours left'
                                                                            : '${(discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inDays} Days left'
                                                                        : DateTime.now().difference((discountData['discountEndDateTime'] as Timestamp).toDate()).inHours <
                                                                                24
                                                                            ? 'Expired ${DateTime.now().difference((discountData['discountEndDateTime'] as Timestamp).toDate()).inHours} Hours Ago'
                                                                            : 'Expired ${DateTime.now().difference((discountData['discountEndDateTime'] as Timestamp).toDate()).inDays} Days Ago',
                                                                style:
                                                                    TextStyle(
                                                                  color: const Color
                                                                      .fromRGBO(
                                                                    211,
                                                                    80,
                                                                    71,
                                                                    1,
                                                                  ),
                                                                  fontSize:
                                                                      width *
                                                                          0.035,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : isLoadMoreListView
                                                    ? SizedBox(
                                                        height: 45,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      )
                                                    : Container();
                                          }),
                                        ),
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
