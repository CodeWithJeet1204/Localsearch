import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localy_user/page/main/vendor/vendor_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/skeleton_container.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class FollowedPage extends StatefulWidget {
  const FollowedPage({super.key});

  @override
  State<FollowedPage> createState() => _FollowedPageState();
}

class _FollowedPageState extends State<FollowedPage>
    with TickerProviderStateMixin {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, List<String>> shops = {};
  Map<String, List<String>> organizers = {};
  List<String> shopTypes = [];
  List<String> organizerTypes = [];
  String? selectedShopType;
  String? selectedOrganizerType;
  bool isShopsData = false;
  bool isOrganizersData = false;
  late TabController tabController;
  late int currentIndex;

  // INIT STATE
  @override
  void initState() {
    getShops();
    getOrganizers();
    super.initState();
    tabController = TabController(
      length: 2,
      vsync: this,
    );
    currentIndex = tabController.index;
    tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: currentIndex,
    );
  }

  // GET SHOPS
  Future<void> getShops() async {
    Map<String, List<String>> vendors = {};

    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final userData = userSnap.data()!;
    final myFollowedShops = userData['followedShops'] as List;

    await Future.forEach(myFollowedShops, (vendorId) async {
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
        final address = vendorData['Address'] as String;
        final type = vendorData['Type'] as String;

        vendors[id] = [name, imageUrl, address, type];
      } else {
        myFollowedShops.remove(vendorId);

        await store.collection('Users').doc(auth.currentUser!.uid).update({
          'followedShops': myFollowedShops,
        });
      }
    });

    setState(() {
      shops = vendors;
    });

    getShopTypes(shops);
  }

  // GET SHOP TYPES
  void getShopTypes(Map<String, List<String>> shops) {
    List<String> myTypes = ['Electronics'];

    shops.forEach((key, value) {
      final myType = value[3];
      if (!myTypes.contains(myType)) {
        myTypes.add(myType);
      }
    });

    setState(() {
      shopTypes = myTypes;
      isShopsData = true;
    });
  }

  // GET ORGANIZERS
  Future<void> getOrganizers() async {
    Map<String, List<String>> myOrganizers = {};

    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final userData = userSnap.data()!;

    final myFollowedOrganizers = userData['followedOrganizers'] as List;

    await Future.forEach(myFollowedOrganizers, (organizerId) async {
      final organizerSnap =
          await store.collection('Organizers').doc(organizerId).get();

      if (organizerSnap.exists) {
        final organizerData = organizerSnap.data()!;
        final id = organizerId as String;
        final name = organizerData['Name'] as String;
        final imageUrl = organizerData['Image'] as String;
        final type = organizerData['Type'] as String;

        myOrganizers[id] = [name, imageUrl, type];
      } else {
        myFollowedOrganizers.remove(organizerId);

        await store.collection('Users').doc(auth.currentUser!.uid).update({
          'followedOrganizers': myFollowedOrganizers,
        });
      }
    });

    setState(() {
      organizers = myOrganizers;
    });

    getOrganizerTypes(organizers);
  }

  // GET ORGANIZER TYPES
  void getOrganizerTypes(Map<String, List<String>> organizers) {
    List<String> myTypes = ['Conference'];

    organizers.forEach((key, value) {
      final myType = value[2];
      if (!myTypes.contains(myType)) {
        myTypes.add(myType);
      }
    });

    setState(() {
      organizerTypes = myTypes;
      isOrganizersData = true;
    });
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
        bottom: PreferredSize(
          preferredSize: Size(
            MediaQuery.of(context).size.width,
            50,
          ),
          child: TabBar(
            indicator: BoxDecoration(
              color: primary2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: 0.5,
                color: primaryDark.withOpacity(0.8),
              ),
            ),
            isScrollable: false,
            indicatorPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.width * 0.02,
              top: MediaQuery.of(context).size.width * 0.0175,
              left: -MediaQuery.of(context).size.width * 0.045,
              right: -MediaQuery.of(context).size.width * 0.045,
            ),
            automaticIndicatorColorAdjustment: false,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: primaryDark,
            labelStyle: const TextStyle(
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
            ),
            dividerColor: white,
            indicatorColor: primaryDark,
            controller: tabController,
            onTap: (value) {
              setState(() {
                currentIndex = value;
              });
            },
            tabs: const [
              Tab(
                text: 'Shops',
              ),
              Tab(
                text: 'Organizers',
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // SHOPS
            !isShopsData
                ? Column(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width * 0.175,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: 4,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: ((context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: SkeletonContainer(
                                width: MediaQuery.of(context).size.width * 0.3,
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
                      horizontal: MediaQuery.of(context).size.width * 0.00625,
                    ),
                    child: LayoutBuilder(
                      builder: ((context, constraints) {
                        final width = constraints.maxWidth;
                        final currentShops = selectedShopType == null
                            ? shops
                            : Map.fromEntries(
                                shops.entries.where((entry) =>
                                    entry.value[3] == selectedShopType),
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
                                          itemCount: shopTypes.length,
                                          itemBuilder: ((context, index) {
                                            final type = shopTypes[index];

                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.01,
                                              ),
                                              child: ActionChip(
                                                label: Text(
                                                  type,
                                                  style: TextStyle(
                                                    color:
                                                        selectedShopType == type
                                                            ? white
                                                            : primaryDark,
                                                  ),
                                                ),
                                                tooltip: 'See $type',
                                                onPressed: () {
                                                  setState(() {
                                                    if (selectedShopType ==
                                                        type) {
                                                      selectedShopType = null;
                                                    } else {
                                                      selectedShopType = type;
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
                                          itemCount: currentShops.length,
                                          itemBuilder: ((context, index) {
                                            final id = currentShops.keys
                                                .toList()[index];
                                            final name = currentShops.values
                                                .toList()[index][0];
                                            final imageUrl = currentShops.values
                                                .toList()[index][1];
                                            final address = currentShops.values
                                                .toList()[index][2];

                                            return Slidable(
                                              endActionPane: ActionPane(
                                                extentRatio: 0.325,
                                                motion: const StretchMotion(),
                                                children: [
                                                  SlidableAction(
                                                    onPressed: (context) async {
                                                      await remove(id);
                                                    },
                                                    backgroundColor: Colors.red,
                                                    icon: FeatherIcons.trash,
                                                    label: 'Unfollow',
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topRight:
                                                          Radius.circular(12),
                                                      bottomRight:
                                                          Radius.circular(12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              child: GestureDetector(
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
                                                      VisualDensity.comfortable,
                                                  tileColor:
                                                      primary2.withOpacity(0.5),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  leading: CircleAvatar(
                                                    backgroundColor: primary2,
                                                    backgroundImage:
                                                        NetworkImage(imageUrl),
                                                  ),
                                                  title: Text(name),
                                                  subtitle: Text(address),
                                                  titleTextStyle: TextStyle(
                                                    color: primaryDark,
                                                    fontSize: width * 0.0475,
                                                  ),
                                                  subtitleTextStyle: TextStyle(
                                                    color: primaryDark2,
                                                    fontSize: width * 0.04,
                                                  ),
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
            !isOrganizersData
                ? Column(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width * 0.175,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: 4,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: ((context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: SkeletonContainer(
                                width: MediaQuery.of(context).size.width * 0.3,
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
                      horizontal: MediaQuery.of(context).size.width * 0.00625,
                    ),
                    child: LayoutBuilder(
                      builder: ((context, constraints) {
                        final width = constraints.maxWidth;
                        final currentOrganizers = selectedOrganizerType == null
                            ? organizers
                            : Map.fromEntries(
                                organizers.entries.where((entry) =>
                                    entry.value[2] == selectedOrganizerType),
                              );

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ORGANIZER TYPE CHIPS
                              organizerTypes.length < 2
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
                                          itemCount: organizerTypes.length,
                                          itemBuilder: ((context, index) {
                                            final type = organizerTypes[index];

                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.01,
                                              ),
                                              child: ActionChip(
                                                label: Text(
                                                  type,
                                                  style: TextStyle(
                                                    color:
                                                        selectedOrganizerType ==
                                                                type
                                                            ? white
                                                            : primaryDark,
                                                  ),
                                                ),
                                                tooltip: 'See $type',
                                                onPressed: () {
                                                  setState(() {
                                                    if (selectedOrganizerType ==
                                                        type) {
                                                      selectedOrganizerType =
                                                          null;
                                                    } else {
                                                      selectedOrganizerType =
                                                          type;
                                                    }
                                                  });
                                                },
                                                backgroundColor:
                                                    selectedOrganizerType ==
                                                            type
                                                        ? primaryDark
                                                        : primary2,
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ),

                              currentOrganizers.isEmpty
                                  ? const SizedBox(
                                      height: 80,
                                      child: Center(
                                        child: Text(
                                          'No Organizers',
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
                                          itemCount: currentOrganizers.length,
                                          itemBuilder: ((context, index) {
                                            final id = currentOrganizers.keys
                                                .toList()[index];
                                            final name = currentOrganizers
                                                .values
                                                .toList()[index][0];
                                            final imageUrl = currentOrganizers
                                                .values
                                                .toList()[index][1];
                                            final address = currentOrganizers
                                                .values
                                                .toList()[index][2];

                                            return Slidable(
                                              endActionPane: ActionPane(
                                                extentRatio: 0.325,
                                                motion: const StretchMotion(),
                                                children: [
                                                  SlidableAction(
                                                    onPressed: (context) async {
                                                      await remove(id);
                                                    },
                                                    backgroundColor: Colors.red,
                                                    icon: FeatherIcons.trash,
                                                    label: 'Unfollow',
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topRight:
                                                          Radius.circular(12),
                                                      bottomRight:
                                                          Radius.circular(12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              child: GestureDetector(
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
                                                      VisualDensity.comfortable,
                                                  tileColor:
                                                      primary2.withOpacity(0.5),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  leading: CircleAvatar(
                                                    backgroundColor: primary2,
                                                    backgroundImage:
                                                        NetworkImage(imageUrl),
                                                  ),
                                                  title: Text(name),
                                                  subtitle: Text(address),
                                                  titleTextStyle: TextStyle(
                                                    color: primaryDark,
                                                    fontSize: width * 0.0475,
                                                  ),
                                                  subtitleTextStyle: TextStyle(
                                                    color: primaryDark2,
                                                    fontSize: width * 0.04,
                                                  ),
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
          ],
        ),
      ),
    );
  }
}
