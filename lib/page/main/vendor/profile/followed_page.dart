import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch/page/main/vendor/vendor_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/sign_in_dialog.dart';
import 'package:localsearch/widgets/skeleton_container.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:localsearch/widgets/text_button.dart';
import 'package:localsearch/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FollowedPage extends StatefulWidget {
  const FollowedPage({super.key});

  @override
  State<FollowedPage> createState() => _FollowedPageState();
}

class _FollowedPageState extends State<FollowedPage>
    with TickerProviderStateMixin {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, List<dynamic>> shops = {};
  // Map<String, List<String>> organizers = {};
  List<String> shopTypes = [];
  // List<String> organizerTypes = [];
  String? selectedShopType;
  // String? selectedOrganizerType;
  bool isShopsData = false;
  // bool isOrganizersData = false;
  // late TabController tabController;
  // late int currentIndex;
  int noOf = 12;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    scrollController.addListener(scrollListener);
    if (auth.currentUser != null) {
      getShops();
    }
    // getOrganizers();
    super.initState();
    // tabController = TabController(
    //   length: 2,
    //   vsync: this,
    // );
    // currentIndex = tabController.index;
    // tabController = TabController(
    //   length: 2,
    //   vsync: this,
    //   initialIndex: currentIndex,
    // );
  }

  // SCROLL LISTENER
  Future<void> scrollListener() async {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      setState(() {
        isLoadMore = true;
      });
      setState(() {
        noOf = noOf + 8;
      });
      setState(() {
        isLoadMore = false;
      });
    }
  }

  // GET SHOPS
  Future<void> getShops() async {
    Map<String, List<dynamic>> vendors = {};

    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final userData = userSnap.data()!;
    final myFollowedShops = userData['followedShops'] as List;

    await Future.forEach(
      myFollowedShops,
      (vendorId) async {
        final vendorSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Shops')
            .doc(vendorId)
            .get();

        if (vendorSnap.exists) {
          final vendorData = vendorSnap.data()!;
          final id = vendorId as String;
          final name = vendorData['Name'] as String;
          final imageUrl = vendorData['Image'] as String;
          final latitude = vendorData['Latitude'] as double;
          final longitude = vendorData['Longitude'] as double;
          final type = vendorData['Type'] as List;

          vendors[id] = [name, imageUrl, latitude, longitude, type];
        } else {
          myFollowedShops.remove(vendorId);

          await store.collection('Users').doc(auth.currentUser!.uid).update({
            'followedShops': myFollowedShops,
          });
        }
      },
    );

    setState(() {
      shops = vendors;
    });

    getShopTypes(shops);
  }

  // GET SHOP TYPES
  void getShopTypes(Map<String, List<dynamic>> shops) {
    List<String> myTypes = [];

    shops.forEach((key, value) {
      final List myType = value[4];
      for (var everyMyType in myType) {
        if (!myTypes.contains(everyMyType)) {
          myTypes.add(everyMyType);
        }
      }
    });

    setState(() {
      shopTypes = myTypes;
      isShopsData = true;
    });
  }

  // GET ORGANIZERS
  // Future<void> getOrganizers() async {
  //   Map<String, List<String>> myOrganizers = {};
  //   final userSnap =
  //       await store.collection('Users').doc(auth.currentUser!.uid).get();
  //   final userData = userSnap.data()!;
  //   final myFollowedOrganizers = userData['followedOrganizers'] as List;
  //   await Future.forEach(myFollowedOrganizers, (organizerId) async {
  //     final organizerSnap =
  //         await store.collection('Organizers').doc(organizerId).get();
  //     if (organizerSnap.exists) {
  //       final organizerData = organizerSnap.data()!;
  //       final id = organizerId as String;
  //       final name = organizerData['Name'] as String;
  //       final imageUrl = organizerData['Image'] as String;
  //       final type = organizerData['Type'] as String;
  //       myOrganizers[id] = [name, imageUrl, type];
  //     } else {
  //       myFollowedOrganizers.remove(organizerId);
  //       await store.collection('Users').doc(auth.currentUser!.uid).update({
  //         'followedOrganizers': myFollowedOrganizers,
  //       });
  //     }
  //   });
  //   setState(() {
  //     organizers = myOrganizers;
  //   });
  //   getOrganizerTypes(organizers);
  // }

  // // GET ORGANIZER TYPES
  // void getOrganizerTypes(Map<String, List<String>> organizers) {
  //   List<String> myTypes = [];
  //   organizers.forEach((key, value) {
  //     final myType = value[2];
  //     if (!myTypes.contains(myType)) {
  //       myTypes.add(myType);
  //     }
  //   });
  //   setState(() {
  //     organizerTypes = myTypes;
  //     isOrganizersData = true;
  //   });
  // }

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

  // REMOVE
  Future<void> remove(String id) async {
    shops.removeWhere((key, value) => key == id);

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'followedShops': shops.keys.toList(),
    });

    await getShops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followed'),
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
        forceMaterialTransparency: true,
        // bottom: PreferredSize(
        //   preferredSize: Size(
        //     MediaQuery.of(context).size.width,
        //     50,
        //   ),
        //   child: TabBar(
        //     indicator: BoxDecoration(
        //       color: primary2,
        //       borderRadius: BorderRadius.circular(8),
        //       border: Border.all(
        //         width: 0.5,
        //         color: primaryDark.withOpacity(0.8),
        //       ),
        //     ),
        //     isScrollable: false,
        //     indicatorPadding: EdgeInsets.only(
        //       bottom: MediaQuery.of(context).size.width * 0.02,
        //       top: MediaQuery.of(context).size.width * 0.0175,
        //       left: -MediaQuery.of(context).size.width * 0.045,
        //       right: -MediaQuery.of(context).size.width * 0.045,
        //     ),
        //     automaticIndicatorColorAdjustment: false,
        //     indicatorWeight: 2,
        //     indicatorSize: TabBarIndicatorSize.label,
        //     labelColor: primaryDark,
        //     labelStyle: const TextStyle(
        //       letterSpacing: 1,
        //       fontWeight: FontWeight.w600,
        //     ),
        //     unselectedLabelStyle: const TextStyle(
        //       letterSpacing: 0,
        //       fontWeight: FontWeight.w500,
        //     ),
        //     dividerColor: white,
        //     indicatorColor: primaryDark,
        //     controller: tabController,
        //     onTap: (value) {
        //       setState(() {
        //         currentIndex = value;
        //       });
        //     },
        //     tabs: const [
        //       Tab(
        //         text: 'Shops',
        //       ),
        //       Tab(
        //         text: 'Organizers',
        //       ),
        //     ],
        //   ),
        // ),
      ),
      body: SafeArea(
        child: /*TabBarView(
          controller: tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [*/
            // SHOPS
            auth.currentUser == null
                ? Center(
                    child: SizedBox(
                      height: 160,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Sign In to Follow Shops'),
                          MyTextButton(
                            onPressed: () async {
                              await showSignInDialog(context);
                            },
                            text: 'SIGN IN',
                            textColor: primaryDark,
                          ),
                        ],
                      ),
                    ),
                  )
                : !isShopsData
                    ? Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width * 0.175,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: 4,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              itemBuilder: ((context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SkeletonContainer(
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                    height: 40,
                                  ),
                                );
                              }),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: 4,
                              physics: const ClampingScrollPhysics(),
                              itemBuilder: ((context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SkeletonContainer(
                                    width: MediaQuery.of(context).size.width,
                                    height: 80,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              MediaQuery.of(context).size.width * 0.00625,
                        ),
                        child: LayoutBuilder(
                          builder: ((context, constraints) {
                            final width = constraints.maxWidth;
                            final currentShops = selectedShopType == null
                                ? shops
                                : Map.fromEntries(
                                    shops.entries.where(
                                      (entry) => (entry.value[4] as List)
                                          .contains(selectedShopType),
                                    ),
                                  );

                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // SHOP TYPE CHIPS
                                  shopTypes.length < 2
                                      ? Container()
                                      : Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.0125,
                                            vertical: width * 0.00625,
                                          ),
                                          child: SizedBox(
                                            width: width,
                                            height: 40,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              scrollDirection: Axis.horizontal,
                                              physics:
                                                  const ClampingScrollPhysics(),
                                              itemCount: shopTypes.length,
                                              itemBuilder: ((context, index) {
                                                final type = shopTypes[index];

                                                return Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: width * 0.01,
                                                  ),
                                                  child: ActionChip(
                                                    label: Text(
                                                      type.toString().trim(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color:
                                                            selectedShopType ==
                                                                    type
                                                                ? white
                                                                : primaryDark,
                                                      ),
                                                    ),
                                                    tooltip: 'See $type',
                                                    onPressed: () {
                                                      setState(() {
                                                        if (selectedShopType ==
                                                            type) {
                                                          selectedShopType =
                                                              null;
                                                        } else {
                                                          selectedShopType =
                                                              type;
                                                        }
                                                      });
                                                    },
                                                    backgroundColor:
                                                        selectedShopType == type
                                                            ? primaryDark
                                                            : primary2,
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ),

                                  currentShops.isEmpty
                                      ? const SizedBox(
                                          height: 80,
                                          child: Center(
                                            child: Text(
                                              'No Shops',
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.0125,
                                            vertical: width * 0.0125,
                                          ),
                                          child: SizedBox(
                                            width: width,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const ClampingScrollPhysics(),
                                              itemCount:
                                                  noOf > currentShops.length
                                                      ? currentShops.length
                                                      : noOf,
                                              itemBuilder: ((context, index) {
                                                final id =
                                                    currentShops.keys.toList()[
                                                        isLoadMore
                                                            ? index == 0
                                                                ? 0
                                                                : index - 1
                                                            : index];
                                                final name = currentShops.values
                                                        .toList()[
                                                    isLoadMore
                                                        ? index - 1
                                                        : index][0];
                                                final imageUrl = currentShops
                                                        .values
                                                        .toList()[
                                                    isLoadMore
                                                        ? index - 1
                                                        : index][1];
                                                final latitude = currentShops
                                                        .values
                                                        .toList()[
                                                    isLoadMore
                                                        ? index - 1
                                                        : index][2];
                                                final longitude = currentShops
                                                        .values
                                                        .toList()[
                                                    isLoadMore
                                                        ? index - 1
                                                        : index][3];

                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: ((context) =>
                                                            VendorPage(
                                                              vendorId: id,
                                                            )),
                                                      ),
                                                    );
                                                  },
                                                  child: ListTile(
                                                    splashColor: white,
                                                    visualDensity:
                                                        VisualDensity.standard,
                                                    tileColor: white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                      side: BorderSide(
                                                        color: primaryDark
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                    leading: CircleAvatar(
                                                      backgroundColor: primary2,
                                                      backgroundImage:
                                                          NetworkImage(
                                                        imageUrl
                                                            .toString()
                                                            .trim(),
                                                      ),
                                                    ),
                                                    title: Text(
                                                      name.toString().trim(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    subtitle: FutureBuilder(
                                                        future: getAddress(
                                                          latitude,
                                                          longitude,
                                                        ),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                              .hasError) {
                                                            return Container();
                                                          }

                                                          if (snapshot
                                                              .hasData) {
                                                            return Text(
                                                              snapshot.data!
                                                                  .toString()
                                                                  .toString()
                                                                  .trim(),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            );
                                                          }

                                                          return Container();
                                                        }),
                                                    titleTextStyle: TextStyle(
                                                      color: primaryDark,
                                                      fontSize: width * 0.0475,
                                                    ),
                                                    subtitleTextStyle:
                                                        TextStyle(
                                                      color: primaryDark2,
                                                      fontSize: width * 0.04,
                                                    ),
                                                    trailing: MyTextButton(
                                                      onPressed: () async {
                                                        await remove(id);
                                                      },
                                                      text: 'Unfollow',
                                                      textColor: Colors.red,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),

        // ORGANIZERS
        // !isOrganizersData
        //     ? Column(
        //         children: [
        //           SizedBox(
        //             width: MediaQuery.of(context).size.width,
        //             height: MediaQuery.of(context).size.width * 0.175,
        //             child: ListView.builder(
        //               shrinkWrap: true,
        //               itemCount: 4,
        //               physics: const ClampingScrollPhysics(),
        //               scrollDirection: Axis.horizontal,
        //               itemBuilder: ((context, index) {
        //                 return Padding(
        //                   padding: const EdgeInsets.all(8),
        //                   child: SkeletonContainer(
        //                     width: MediaQuery.of(context).size.width * 0.3,
        //                     height: 40,
        //                   ),
        //                 );
        //               }),
        //             ),
        //           ),
        //           SizedBox(
        //             width: MediaQuery.of(context).size.width,
        //             child: ListView.builder(
        //               shrinkWrap: true,
        //               itemCount: 4,
        //               physics: const ClampingScrollPhysics(),
        //               itemBuilder: ((context, index) {
        //                 return Padding(
        //                   padding: const EdgeInsets.all(8),
        //                   child: SkeletonContainer(
        //                     width: MediaQuery.of(context).size.width,
        //                     height: 80,
        //                   ),
        //                 );
        //               }),
        //             ),
        //           ),
        //         ],
        //       )
        //     : Padding(
        //         padding: EdgeInsets.symmetric(
        //           horizontal: MediaQuery.of(context).size.width * 0.00625,
        //         ),
        //         child: LayoutBuilder(
        //           builder: ((context, constraints) {
        //             final width = constraints.maxWidth;
        //             final currentOrganizers = selectedOrganizerType == null
        //                 ? organizers
        //                 : Map.fromEntries(
        //                     organizers.entries.where((entry) =>
        //                         entry.value[2] == selectedOrganizerType),
        //                   );

        //             return SingleChildScrollView(
        //               child: Column(
        //                 crossAxisAlignment: CrossAxisAlignment.start,
        //                 children: [
        //                   // ORGANIZER TYPE CHIPS
        //                   organizerTypes.length < 2
        //                       ? Container()
        //                       : Padding(
        //                           padding: EdgeInsets.symmetric(
        //                             horizontal: width * 0.0125,
        //                             vertical: width * 0.00625,
        //                           ),
        //                           child: SizedBox(
        //                             width: width,
        //                             height: 40,
        //                             child: ListView.builder(
        //                               shrinkWrap: true,
        //                               scrollDirection: Axis.horizontal,
        //                               physics:
        //                                   const ClampingScrollPhysics(),
        //                               itemCount: organizerTypes.length,
        //                               itemBuilder: ((context, index) {
        //                                 final type = organizerTypes[index];

        //                                 return Padding(
        //                                   padding: EdgeInsets.symmetric(
        //                                     horizontal: width * 0.01,
        //                                   ),
        //                                   child: ActionChip(
        //                                     label: Text(
        //                                       type,
        //                                       style: TextStyle(
        //                                         color:
        //                                             selectedOrganizerType ==
        //                                                     type
        //                                                 ? white
        //                                                 : primaryDark,
        //                                       ),
        //                                     ),
        //                                     tooltip: 'See $type',
        //                                     onPressed: () {
        //                                       setState(() {
        //                                         if (selectedOrganizerType ==
        //                                             type) {
        //                                           selectedOrganizerType =
        //                                               null;
        //                                         } else {
        //                                           selectedOrganizerType =
        //                                               type;
        //                                         }
        //                                       });
        //                                     },
        //                                     backgroundColor:
        //                                         selectedOrganizerType ==
        //                                                 type
        //                                             ? primaryDark
        //                                             : primary2,
        //                                   ),
        //                                 );
        //                               }),
        //                             ),
        //                           ),
        //                         ),

        //                   currentOrganizers.isEmpty
        //                       ? const SizedBox(
        //                           height: 80,
        //                           child: Center(
        //                             child: Text(
        //                               'No Organizers',
        //                             ),
        //                           ),
        //                         )
        //                       : Padding(
        //                           padding: EdgeInsets.symmetric(
        //                             horizontal: width * 0.0125,
        //                             vertical: width * 0.0125,
        //                           ),
        //                           child: SizedBox(
        //                             width: width,
        //                             child: ListView.builder(
        //                               shrinkWrap: true,
        //                               physics:
        //                                   const ClampingScrollPhysics(),
        //                               itemCount: currentOrganizers.length,
        //                               itemBuilder: ((context, index) {
        //                                 final id = currentOrganizers.keys
        //                                     .toList()[index];
        //                                 final name = currentOrganizers
        //                                     .values
        //                                     .toList()[index][0];
        //                                 final imageUrl = currentOrganizers
        //                                     .values
        //                                     .toList()[index][1];
        //                                 final address = currentOrganizers
        //                                     .values
        //                                     .toList()[index][2];

        //                                 return Slidable(
        //                                   endActionPane: ActionPane(
        //                                     extentRatio: 0.325,
        //                                     motion: const StretchMotion(),
        //                                     children: [
        //                                       SlidableAction(
        //                                         onPressed: (context) async {
        //                                           await remove(id);
        //                                         },
        //                                         backgroundColor: Colors.red,
        //                                         icon: FeatherIcons.trash,
        //                                         label: 'Unfollow',
        //                                         borderRadius:
        //                                             const BorderRadius.only(
        //                                           topRight:
        //                                               Radius.circular(12),
        //                                           bottomRight:
        //                                               Radius.circular(12),
        //                                         ),
        //                                       ),
        //                                     ],
        //                                   ),
        //                                   child: GestureDetector(
        //                                     onTap: () {
        //                                       Navigator.of(context).push(
        //                                         MaterialPageRoute(
        //                                           builder: ((context) =>
        //                                               EventsOrganizerPage(
        //                                                 organizerId: id,
        //                                               )),
        //                                         ),
        //                                       );
        //                                     },
        //                                     child: ListTile(
        //                                       splashColor: white,
        //                                       visualDensity:
        //                                           VisualDensity.comfortable,
        //                                       tileColor:
        //                                           primary2.withOpacity(0.5),
        //                                       shape: RoundedRectangleBorder(
        //                                         borderRadius:
        //                                             BorderRadius.circular(
        //                                                 12),
        //                                       ),
        //                                       leading: CircleAvatar(
        //                                         backgroundColor: primary2,
        //                                         backgroundImage:
        //                                             NetworkImage(imageUrl),
        //                                       ),
        //                                       title: Text(name),
        //                                       subtitle: Text(address),
        //                                       titleTextStyle: TextStyle(
        //                                         color: primaryDark,
        //                                         fontSize: width * 0.0475,
        //                                       ),
        //                                       subtitleTextStyle: TextStyle(
        //                                         color: primaryDark2,
        //                                         fontSize: width * 0.04,
        //                                       ),
        //                                     ),
        //                                   ),
        //                                 );
        //                               }),
        //                             ),
        //                           ),
        //                         ),
        //                 ],
        //               ),
        //             );
        //           }),
        //         ),
        //       ),
        // ],
      ),
      // ),
    );
  }
}
