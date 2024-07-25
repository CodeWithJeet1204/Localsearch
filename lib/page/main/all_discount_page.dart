import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localy_user/page/main/discount_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/shimmer_skeleton_container.dart';
import 'package:localy_user/widgets/snack_bar.dart';

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
  RangeValues distanceRange = RangeValues(0, 5);
  bool isGridView = true;
  bool isData = false;

  // INIT STATE
  @override
  void initState() {
    getData();
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // GET DATA
  Future<void> getData() async {
    Map<String, Map<String, dynamic>> myDiscounts = {};
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .get();

    double? yourLatitude = null;
    double? yourLongitude = null;

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
          'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$startLat,$startLong&destinations=$endLat,$endLong&key=AIzaSyCTzhOTUtdVUx0qpAbcXdn1TQKSmqtJbZM';
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
      }
    });

    for (var discount in discountSnap.docs) {
      final discountData = discount.data();

      final discountId = discount.id;
      final Timestamp endDateTime = discountData['discountEndDateTime'];
      final String vendorId = discountData['vendorId'];
      double? distance = null;

      final vendorSnap = await store
          .collection('Business')
          .doc('Owners')
          .collection('Shops')
          .doc(vendorId)
          .get();

      final vendorData = vendorSnap.data()!;

      final vendorName = vendorData['Name'];
      final latitude = vendorData['Latitude'];
      final longitude = vendorData['Longitude'];

      if (yourLatitude != null && yourLongitude != null) {
        distance = await getDrivingDistance(
          yourLatitude!,
          yourLongitude!,
          latitude,
          longitude,
        );
      }

      if (distance != null) {
        if (distance * 0.925 < 5) {
          if (endDateTime.toDate().isAfter(DateTime.now())) {
            discountData.addAll({
              'vendorName': vendorName,
              'distance': distance,
            });
            myDiscounts[discountId] = discountData;
          }
        }
      }
    }

    setState(() {
      currentDiscounts = myDiscounts;
      allDiscounts = myDiscounts;
      print("all discount: $allDiscounts");
      isData = true;
    });
  }

  // UPDATE DISCOUNTS
  void updateDiscounts(double endDistance) {
    Map<String, Map<String, dynamic>> tempDiscounts = {};
    print("all discounts1: $allDiscounts");
    print("all discounts2: $allDiscounts");
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    RangeLabels distanceLables = RangeLabels(
      '0',
      distanceRange.end.toString(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          overflow: TextOverflow.ellipsis,
          'ALL DISCOUNTS',
        ),
        bottom: PreferredSize(
          preferredSize: Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.width * 0.2,
          ),
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

                          currentDiscounts = filteredDiscounts;
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
                    isDelete: true,
                  ),
                );
              },
            ))
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(width * 0.006125),
                child: LayoutBuilder(
                  builder: ((context, constraints) {
                    double width = constraints.maxWidth;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DISTANCE
                          Padding(
                            padding: EdgeInsets.only(left: width * 0.025),
                            child: Text(
                              'Distance',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          // RANGE SLIDER
                          Center(
                            child: RangeSlider(
                              min: 0,
                              max: 50,
                              labels: distanceLables,
                              divisions: 20,
                              values: RangeValues(0, distanceRange.end),
                              activeColor: primaryDark,
                              inactiveColor: Color.fromRGBO(197, 243, 255, 1),
                              onChanged: (newValue) {
                                print('all discounts: $allDiscounts');
                                setState(() {
                                  isData = false;
                                  distanceRange = RangeValues(0, newValue.end);
                                });
                                updateDiscounts(distanceRange.end);
                                setState(() {
                                  isData = true;
                                });
                              },
                            ),
                          ),
                          currentDiscounts.isEmpty
                              ? const Center(
                                  child: Text('No Discounts'),
                                )
                              : isGridView
                                  ? SizedBox(
                                      width: width,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: ClampingScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 1,
                                          childAspectRatio: 16 / 10,
                                        ),
                                        itemCount: currentDiscounts.length,
                                        itemBuilder: ((context, index) {
                                          final discountData = currentDiscounts[
                                              currentDiscounts.keys
                                                  .toList()[index]]!;

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
                                                color:
                                                    primary2.withOpacity(0.125),
                                                border: Border.all(
                                                  width: 0.25,
                                                  color: primaryDark,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                              margin: EdgeInsets.all(
                                                  width * 0.00625),
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
                                                              child:
                                                                  Image.network(
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
                                                              height:
                                                                  width * 0.375,
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
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color: primaryDark,
                                                            fontSize:
                                                                width * 0.06,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),

                                                      // DISCOUNT & TIME
                                                      Row(
                                                        children: [
                                                          // DISCOUNT
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                              left:
                                                                  width * 0.01,
                                                              top: width * 0.01,
                                                            ),
                                                            child: Text(
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              discountData[
                                                                      'isPercent']
                                                                  ? '${discountData['discountAmount']}% off'
                                                                  : 'Rs. ${discountData['discountAmount']} off',
                                                              style: TextStyle(
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
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
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
                                                                EdgeInsets.only(
                                                              left:
                                                                  width * 0.01,
                                                              top: width * 0.01,
                                                            ),
                                                            child: Text(
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              (discountData['discountStartDateTime']
                                                                          as Timestamp)
                                                                      .toDate()
                                                                      .isAfter(
                                                                          DateTime
                                                                              .now())
                                                                  ? (discountData['discountStartDateTime'] as Timestamp)
                                                                              .toDate()
                                                                              .difference(DateTime
                                                                                  .now())
                                                                              .inHours <
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
                                                              style: TextStyle(
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
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
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
                                        shrinkWrap: true,
                                        physics: ClampingScrollPhysics(),
                                        itemCount: currentDiscounts.length,
                                        itemBuilder: ((context, index) {
                                          final discountData = currentDiscounts[
                                              currentDiscounts.keys
                                                  .toList()[index]]!;

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
                                                  width: 0.5,
                                                  color: primaryDark,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                              margin: EdgeInsets.all(
                                                width * 0.0125,
                                              ),
                                              child: ListTile(
                                                visualDensity:
                                                    VisualDensity.comfortable,
                                                leading: discountData[
                                                            'discountImageUrl'] !=
                                                        null
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          2,
                                                        ),
                                                        child: Image.network(
                                                          discountData[
                                                              'discountImageUrl'],
                                                          width: width * 0.15,
                                                          height: width * 0.15,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                    : SizedBox(
                                                        width: width * 0.15,
                                                        height: width * 0.15,
                                                        child: const Center(
                                                          child: Text(
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            'No Image',
                                                            style: TextStyle(
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
                                                  discountData['discountName'],
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: width * 0.05,
                                                  ),
                                                ),

                                                // DISCOUNT &  TIME
                                                subtitle: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    // DISCOUNT
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: width * 0.01,
                                                        top: width * 0.01,
                                                      ),
                                                      child: Text(
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        discountData[
                                                                'isPercent']
                                                            ? '${discountData['discountAmount']}% off'
                                                            : 'Rs. ${discountData['discountAmount']} off',
                                                        style: TextStyle(
                                                          color: const Color
                                                              .fromRGBO(
                                                            0,
                                                            72,
                                                            2,
                                                            1,
                                                          ),
                                                          fontSize:
                                                              width * 0.035,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),

                                                    // TEXT DIVIDER
                                                    const Text(
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      '  ●  ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w100,
                                                      ),
                                                    ),

                                                    // TIME
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: width * 0.01,
                                                        top: width * 0.01,
                                                      ),
                                                      child: Text(
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        (discountData['discountStartDateTime']
                                                                    as Timestamp)
                                                                .toDate()
                                                                .isAfter(
                                                                    DateTime
                                                                        .now())
                                                            ? (discountData['discountStartDateTime']
                                                                            as Timestamp)
                                                                        .toDate()
                                                                        .difference(DateTime
                                                                            .now())
                                                                        .inHours <
                                                                    24
                                                                ? 'After ${(discountData['discountStartDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours} Hours'
                                                                : 'After ${(discountData['discountStartDateTime'] as Timestamp).toDate().difference(DateTime.now()).inDays} Days'
                                                            : (discountData['discountEndDateTime']
                                                                        as Timestamp)
                                                                    .toDate()
                                                                    .isAfter(
                                                                        DateTime
                                                                            .now())
                                                                ? (discountData['discountEndDateTime']
                                                                                as Timestamp)
                                                                            .toDate()
                                                                            .difference(DateTime.now())
                                                                            .inHours <
                                                                        24
                                                                    ? '${(discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inHours} Hours left'
                                                                    : '${(discountData['discountEndDateTime'] as Timestamp).toDate().difference(DateTime.now()).inDays} Days left'
                                                                : DateTime.now().difference((discountData['discountEndDateTime'] as Timestamp).toDate()).inHours < 24
                                                                    ? 'Expired ${DateTime.now().difference((discountData['discountEndDateTime'] as Timestamp).toDate()).inHours} Hours Ago'
                                                                    : 'Expired ${DateTime.now().difference((discountData['discountEndDateTime'] as Timestamp).toDate()).inDays} Days Ago',
                                                        style: TextStyle(
                                                          color: const Color
                                                              .fromRGBO(
                                                            211,
                                                            80,
                                                            71,
                                                            1,
                                                          ),
                                                          fontSize:
                                                              width * 0.035,
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
