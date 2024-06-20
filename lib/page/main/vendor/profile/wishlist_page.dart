import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localy_user/page/main/events/event_page.dart';
import 'package:localy_user/page/main/vendor/product/product_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/skeleton_container.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage>
    with TickerProviderStateMixin {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, List<dynamic>> wishlistProducts = {};
  Map<String, Map<String, dynamic>> events = {};
  List types = [];
  String? selectedCategory;
  String? selectedType;
  List categories = ['Pens'];
  bool getProductsData = false;
  bool getEventsData = false;
  late TabController tabController;
  late int currentIndex;

  // INIT STATE
  @override
  void initState() {
    getProductWishlist();
    getEventWishlist();
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

  // GET PRODUCT WISHLIST
  Future<void> getProductWishlist() async {
    Map<String, List<dynamic>> wishlist = {};

    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final userData = userSnap.data()!;
    final myWishlists = userData['wishlists'] as List;

    await Future.forEach(myWishlists, (productId) async {
      final productSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(productId)
          .get();

      if (productSnap.exists) {
        final productData = productSnap.data()!;
        final id = productId as String;
        final name = productData['productName'] as String;
        final imageUrl = productData['images'][0] as String;
        final price = productData['productPrice'] as String;
        final productCategoryName = productData['categoryName'] as String;
        final vendorId = productData['vendorId'];

        final vendorSnap = await store
            .collection('Business')
            .doc('Owners')
            .collection('Shops')
            .doc(vendorId)
            .get();

        final vendorData = vendorSnap.data()!;

        final String shopType = vendorData['Type'];

        if (productCategoryName != '0') {
          print("Shop Type: $shopType");
          print("Product Category name: $productCategoryName");
          final categorySnap = await store
              .collection('Business')
              .doc('Special Categories')
              .collection(shopType)
              .doc(productCategoryName)
              .get();

          final categoryData = categorySnap.data()!;

          final categoryName = categoryData['specialCategoryName'];

          if (!categories.contains(categoryName)) {
            categories.add(categoryName);
          }
          wishlist[id] = [
            name,
            imageUrl,
            price,
            categoryName,
            productData,
          ];
        } else {
          wishlist[id] = [
            name,
            imageUrl,
            price,
            '0',
            productData,
          ];
        }
      } else {
        myWishlists.remove(productId);

        await store.collection('Users').doc(auth.currentUser!.uid).update({
          'wishlists': myWishlists,
        });
      }
    });

    setState(() {
      wishlistProducts = wishlist;
      getProductsData = true;
    });
  }

  // GET EVENT WISHLIST
  Future<void> getEventWishlist() async {
    Map<String, Map<String, dynamic>> myEvents = {};
    List myTypes = [];
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final List wishlistEvents = userData['wishlistEvents'];

    // ignore: avoid_function_literals_in_foreach_calls
    wishlistEvents.forEach((eventId) async {
      final eventSnap = await store.collection('Events').doc(eventId).get();

      if (eventSnap.exists) {
        final eventData = eventSnap.data()!;

        if ((eventData['endDate'] as Timestamp)
            .toDate()
            .isAfter(DateTime.now())) {
          myEvents[eventId] = eventData;

          if (!myTypes.contains(eventData['eventType'])) {
            myTypes.add(eventData['eventType']);
          }
        } else {
          wishlistEvents.remove(eventId);

          await store.collection('Users').doc(auth.currentUser!.uid).update({
            'wishlistEvents': wishlistEvents,
          });
        }
      } else {
        wishlistEvents.remove(eventId);

        await store.collection('Users').doc(auth.currentUser!.uid).update({
          'wishlistEvents': wishlistEvents,
        });
      }
    });

    setState(() {
      events = myEvents;
      types = myTypes;
      getEventsData = true;
    });
  }

  // REMOVE
  Future<void> remove(String id, bool isEvent) async {
    if (isEvent) {
      events.removeWhere((key, value) => key == id);

      await store.collection('Users').doc(auth.currentUser!.uid).update({
        'wishlistEvents': events.keys.toList(),
      });
    } else {
      wishlistProducts.removeWhere((key, value) => key == id);

      await store.collection('Users').doc(auth.currentUser!.uid).update({
        'wishlists': wishlistProducts.keys.toList(),
      });
    }

    await getProductWishlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wishlist',
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
                text: 'Products',
              ),
              Tab(
                text: 'Events',
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
            // PRODUCTS
            !getProductsData
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
                        final currentWishlists = selectedCategory == null
                            ? wishlistProducts
                            : Map.fromEntries(
                                wishlistProducts.entries.where((entry) =>
                                    entry.value[3] == selectedCategory),
                              );

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CATEGORY CHIPS
                              categories.length < 2
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
                                          itemCount: categories.length,
                                          itemBuilder: ((context, index) {
                                            final category = categories[index];

                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.01,
                                              ),
                                              child: ActionChip(
                                                label: Text(
                                                  category,
                                                  style: TextStyle(
                                                    color: selectedCategory ==
                                                            category
                                                        ? white
                                                        : primaryDark,
                                                  ),
                                                ),
                                                tooltip: 'See $category',
                                                onPressed: () {
                                                  setState(() {
                                                    if (selectedCategory ==
                                                        category) {
                                                      selectedCategory = null;
                                                    } else {
                                                      selectedCategory =
                                                          category;
                                                    }
                                                  });
                                                },
                                                backgroundColor:
                                                    selectedCategory == category
                                                        ? primaryDark
                                                        : primary2,
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ),

                              currentWishlists.isEmpty
                                  ? const SizedBox(
                                      height: 80,
                                      child: Center(
                                        child: Text(
                                          'No Products',
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
                                          itemCount: currentWishlists.length,
                                          itemBuilder: ((context, index) {
                                            final id = currentWishlists.keys
                                                .toList()[index];
                                            final name = currentWishlists.values
                                                .toList()[index][0];
                                            final imageUrl = currentWishlists
                                                .values
                                                .toList()[index][1];
                                            final price = currentWishlists
                                                .values
                                                .toList()[index][2];
                                            final data = currentWishlists.values
                                                .toList()[index][4];

                                            return Slidable(
                                              endActionPane: ActionPane(
                                                extentRatio: 0.325,
                                                motion: const StretchMotion(),
                                                children: [
                                                  SlidableAction(
                                                    onPressed: (context) async {
                                                      await remove(id, false);
                                                    },
                                                    backgroundColor: Colors.red,
                                                    icon: Icons
                                                        .heart_broken_outlined,
                                                    label: 'Remove',
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
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: width * 0.0125,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: ((context) =>
                                                            ProductPage(
                                                              productData: data,
                                                            )),
                                                      ),
                                                    );
                                                  },
                                                  child: ListTile(
                                                    splashColor: white,
                                                    visualDensity: VisualDensity
                                                        .comfortable,
                                                    tileColor: primary2
                                                        .withOpacity(0.5),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    leading: CircleAvatar(
                                                      backgroundColor: primary2,
                                                      backgroundImage:
                                                          NetworkImage(
                                                              imageUrl),
                                                    ),
                                                    title: Text(
                                                      name,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    subtitle: Text(
                                                      price == ''
                                                          ? 'N/A'
                                                          : 'Rs. $price',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    titleTextStyle: TextStyle(
                                                      color: primaryDark,
                                                      fontSize: width * 0.0475,
                                                    ),
                                                    subtitleTextStyle:
                                                        TextStyle(
                                                      color: primaryDark2,
                                                      fontSize: width * 0.04,
                                                    ),
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

            // EVENTS
            !getEventsData
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
                        final currentWishlists = selectedType == null
                            ? events
                            : Map.fromEntries(
                                events.entries.where(
                                  (entry) =>
                                      entry.value['eventType'] == selectedType,
                                ),
                              );

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TYPE CHIPS
                              types.length < 2
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
                                          itemCount: types.length,
                                          itemBuilder: ((context, index) {
                                            final type = types[index];

                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.01,
                                              ),
                                              child: ActionChip(
                                                label: Text(
                                                  type,
                                                  style: TextStyle(
                                                    color: selectedType == type
                                                        ? white
                                                        : primaryDark,
                                                  ),
                                                ),
                                                tooltip: 'See $type',
                                                onPressed: () {
                                                  int previousIndex =
                                                      currentIndex;
                                                  setState(() {
                                                    if (selectedType == type) {
                                                      selectedType = null;
                                                    } else {
                                                      selectedType = type;
                                                    }
                                                  });
                                                  setState(() {
                                                    tabController.index =
                                                        previousIndex;
                                                  });
                                                },
                                                backgroundColor:
                                                    selectedType == type
                                                        ? primaryDark
                                                        : primary2,
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ),

                              currentWishlists.isEmpty
                                  ? const SizedBox(
                                      height: 80,
                                      child: Center(
                                        child: Text(
                                          'No Events',
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
                                          itemCount: currentWishlists.length,
                                          itemBuilder: ((context, index) {
                                            final id = currentWishlists.keys
                                                .toList()[index];
                                            final name = currentWishlists.values
                                                .toList()[index]['eventName'];
                                            final imageUrl = currentWishlists
                                                .values
                                                .toList()[index]['imageUrl'][0];
                                            final organizer = currentWishlists
                                                    .values
                                                    .toList()[index]
                                                ['organizerName'];

                                            return Slidable(
                                              endActionPane: ActionPane(
                                                extentRatio: 0.325,
                                                motion: const StretchMotion(),
                                                children: [
                                                  SlidableAction(
                                                    onPressed: (context) async {
                                                      await remove(id, true);
                                                    },
                                                    backgroundColor: Colors.red,
                                                    icon: Icons
                                                        .heart_broken_outlined,
                                                    label: 'Remove',
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
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: width * 0.0125,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: ((context) =>
                                                            EventPage(
                                                              eventId: id,
                                                            )),
                                                      ),
                                                    );
                                                  },
                                                  child: ListTile(
                                                    splashColor: white,
                                                    visualDensity: VisualDensity
                                                        .comfortable,
                                                    tileColor: primary2
                                                        .withOpacity(0.5),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    leading: CircleAvatar(
                                                      backgroundColor: primary2,
                                                      backgroundImage:
                                                          NetworkImage(
                                                              imageUrl),
                                                    ),
                                                    title: Text(
                                                      name,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    subtitle: Text(
                                                      organizer == ''
                                                          ? 'N/A'
                                                          : organizer,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    titleTextStyle: TextStyle(
                                                      color: primaryDark,
                                                      fontSize: width * 0.0475,
                                                    ),
                                                    subtitleTextStyle:
                                                        TextStyle(
                                                      color: primaryDark2,
                                                      fontSize: width * 0.04,
                                                    ),
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
