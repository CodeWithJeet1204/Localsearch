import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localsearch_user/providers/location_provider.dart';
import 'package:localsearch_user/utils/colors.dart';
import 'package:localsearch_user/widgets/snack_bar.dart';
import 'package:provider/provider.dart';

class LocationChangePage extends StatefulWidget {
  const LocationChangePage({
    super.key,
    required this.page,
  });

  final Widget page;

  @override
  State<LocationChangePage> createState() => _LocationChangePageState();
}

class _LocationChangePageState extends State<LocationChangePage> {
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  Map<String, Map<String, dynamic>> currentCities = {};
  Map<String, Map<String, dynamic>> allCities = {};
  bool isData = false;
  int noOf = 16;
  int? total;
  bool isLoadMore = false;
  final scrollController = ScrollController();
  bool isGettingLocation = false;

  // INIT STATE
  @override
  void initState() {
    getTotal();
    scrollController.addListener(scrollListener);
    getData();
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // GET TOTAL
  Future<void> getTotal() async {
    final citySnap = await store.collection('Cities').get();

    final totalCityLength = citySnap.docs.length;

    setState(() {
      total = totalCityLength;
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
        noOf = noOf + 20;
        await getData();
        setState(() {
          isLoadMore = false;
        });
      }
    }
  }

  // GET DATA
  Future<void> getData() async {
    Map<String, Map<String, dynamic>> tempCities = {};
    final citySnap = await store.collection('Cities').limit(noOf).get();

    for (var city in citySnap.docs) {
      final cityData = city.data();
      final cityId = cityData['cityId'];

      tempCities[cityId] = cityData;
    }

    setState(() {
      currentCities = tempCities;
      allCities = tempCities;
      isData = true;
    });
  }

  // UPDATE CITIES
  void updateCities(String search) async {
    Map<String, Map<String, dynamic>> tempCities = {};

    if (search.isEmpty) {
      setState(() {
        currentCities = allCities;
      });
    } else {
      allCities.forEach((key, value) {
        if ((value['cityName'] as String)
            .toLowerCase()
            .contains(search.toLowerCase())) {
          tempCities[key] = value;
        }
      });

      setState(() {
        currentCities = tempCities;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final locationProvider = Provider.of<LocationProvider>(context);
    final cityName = locationProvider.cityName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Location'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            width * 0.006125,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
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
                    children: currentCities.isEmpty
                        ? [
                            Container(
                              width: width,
                              decoration: BoxDecoration(
                                color: darkGrey.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: EdgeInsets.all(width * 0.0125),
                              child: TextField(
                                controller: searchController,
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.cyan.shade700,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  updateCities(value);
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 100,
                              child: Center(
                                child: Text('No Cities'),
                              ),
                            ),
                          ]
                        : [
                            Container(
                              width: width,
                              decoration: BoxDecoration(
                                color: darkGrey.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: EdgeInsets.all(width * 0.0125),
                              child: TextField(
                                controller: searchController,
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.cyan.shade700,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  updateCities(value);
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                setState(() {
                                  isGettingLocation = true;
                                });
                                await getLocation().then((value) async {
                                  if (value != null) {
                                    locationProvider.changeCity({
                                      'Your Location': {
                                        'cityId': 'Your Location',
                                        'cityName': 'Your Location',
                                        'cityLatitude': value.latitude,
                                        'cityLongitude': value.longitude,
                                      },
                                    });
                                  }
                                });
                                setState(() {
                                  isGettingLocation = false;
                                });
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => widget.page,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: width,
                                decoration: BoxDecoration(
                                  color: darkGrey.withOpacity(0.25),
                                  border: cityName != 'Your Location' &&
                                          cityName != null
                                      ? null
                                      : Border.all(
                                          width: 3,
                                          color: darkGrey,
                                        ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.all(width * 0.05),
                                margin: EdgeInsets.all(width * 0.0225),
                                child: isGettingLocation
                                    ? Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment: cityName !=
                                                    'Your Location' &&
                                                cityName != null
                                            ? MainAxisAlignment.start
                                            : MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Your Location 📍',
                                            style: TextStyle(
                                              fontSize: width * 0.05,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          cityName != 'Your Location' &&
                                                  cityName != null
                                              ? Container()
                                              : Container(
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  decoration:
                                                      const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: primaryDark2,
                                                  ),
                                                  child: Icon(
                                                    FeatherIcons.check,
                                                    color: Colors.white,
                                                    size: width * 0.1,
                                                  ),
                                                ),
                                        ],
                                      ),
                              ),
                            ),
                            const Divider(),
                            Padding(
                              padding: EdgeInsets.all(width * 0.0125),
                              child: Text(
                                'Cities',
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: ListView.builder(
                                controller: scrollController,
                                primary: false,
                                cacheExtent: height * 1.5,
                                addAutomaticKeepAlives: true,
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: isLoadMore
                                    ? currentCities.length + 1
                                    : currentCities.length,
                                itemBuilder: (context, index) {
                                  final currentCityId =
                                      currentCities.values.toList()[isLoadMore
                                          ? index == 0
                                              ? 0
                                              : index - 1
                                          : index]['cityId'];
                                  final currentCityName =
                                      currentCities.values.toList()[isLoadMore
                                          ? index == 0
                                              ? 0
                                              : index - 1
                                          : index]['cityName'];
                                  final currentCityLatitude =
                                      currentCities.values.toList()[isLoadMore
                                          ? index - 1
                                          : index]['cityLatitude'];
                                  final currentCityLongitude =
                                      currentCities.values.toList()[isLoadMore
                                          ? index - 1
                                          : index]['cityLongitude'];

                                  return index <= currentCities.length
                                      ? GestureDetector(
                                          onTap: () {
                                            locationProvider.changeCity({
                                              currentCityId: {
                                                'cityId': currentCityId,
                                                'cityName': currentCityName,
                                                'cityLatitude':
                                                    currentCityLatitude,
                                                'cityLongitude':
                                                    currentCityLongitude,
                                              },
                                            });
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    widget.page,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: width,
                                            decoration: BoxDecoration(
                                              color: darkGrey.withOpacity(0.25),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border:
                                                  cityName != currentCityName
                                                      ? null
                                                      : Border.all(
                                                          width: 3,
                                                          color: darkGrey,
                                                        ),
                                            ),
                                            padding:
                                                EdgeInsets.all(width * 0.04),
                                            margin:
                                                EdgeInsets.all(width * 0.0125),
                                            child: Row(
                                              mainAxisAlignment:
                                                  cityName != currentCityName
                                                      ? MainAxisAlignment.start
                                                      : MainAxisAlignment
                                                          .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: cityName !=
                                                          currentCityName
                                                      ? width * 0.875
                                                      : width * 0.75,
                                                  child: Text(
                                                    currentCityName,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: width * 0.045,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                cityName != currentCityName
                                                    ? Container()
                                                    : Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(2),
                                                        decoration:
                                                            const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: primaryDark2,
                                                        ),
                                                        child: Icon(
                                                          FeatherIcons.check,
                                                          color: Colors.white,
                                                          size: width * 0.1,
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : isLoadMore
                                          ? SizedBox(
                                              height: 45,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : Container();
                                },
                              ),
                            ),
                          ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
