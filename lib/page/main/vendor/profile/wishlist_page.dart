import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch/page/main/vendor/product/product_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/skeleton_container.dart';
import 'package:localsearch/widgets/text_button.dart';
import 'package:localsearch/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, List<dynamic>> wishlistProducts = {};
  String? selectedCategory;
  List categories = [];
  bool isData = false;
  // Map<String, Map<String, dynamic>> events = {};
  // bool getEventsData = false;
  // late TabController tabController;
  // late int currentIndex;
  int noOf = 12;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    scrollController.addListener(scrollListener);
    getWishlists();
    // getEventWishlist();
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

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
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

  // GET WISHLISTS
  Future<void> getWishlists() async {
    Map<String, List<dynamic>> wishlist = {};

    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final myWishlists = userData['wishlists'] as List;

    await Future.forEach(
      myWishlists,
      (productId) async {
        final productSnap = await store
            .collection('Business')
            .doc('Data')
            .collection('Products')
            .doc(productId)
            .get();

        if (productSnap.exists) {
          final productData = productSnap.data()!;
          final id = productId as String;
          final name = productData['productName'];
          final imageUrl = productData['images'][0];
          final price = productData['productPrice'];
          final productCategoryName = productData['categoryName'];
          final vendorId = productData['vendorId'];

          final vendorSnap = await store
              .collection('Business')
              .doc('Owners')
              .collection('Shops')
              .doc(vendorId)
              .get();

          final vendorData = vendorSnap.data()!;

          final List shopTypes = vendorData['Type'];

          if (productCategoryName != '0') {
            final categoriesSnap = await store
                .collection('Shop Types And Category Data')
                .doc('Category Data')
                .get();

            final categoriesData = categoriesSnap.data()!;

            final householdCategories = categoriesData['householdCategoryData'];

            householdCategories.forEach((shopType, categoryData) {
              if (shopTypes.contains(shopType)) {
                categoryData.forEach((categoryName, categoryImage) {
                  if (categoryName == productCategoryName) {
                    wishlist[id] = [
                      name,
                      imageUrl,
                      price,
                      categoryName,
                      productData,
                    ];
                    if (!categories.contains(categoryName)) {
                      categories.add(categoryName);
                    }
                    return;
                  }
                });
              }
            });
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
      },
    );

    setState(() {
      wishlistProducts = wishlist;
      isData = true;
    });
  }

  // GET EVENT WISHLIST
  // Future<void> getEventWishlist() async {
  //   Map<String, Map<String, dynamic>> myEvents = {};
  //   List myTypes = [];
  //   final userSnap =
  //       await store.collection('Users').doc(auth.currentUser!.uid).get();
  //   final userData = userSnap.data()!;
  //   final List wishlistEvents = userData['wishlistEvents'];
  //   // ignore: avoid_function_literals_in_foreach_calls
  //   wishlistEvents.forEach((eventId) async {
  //     final eventSnap = await store.collection('Events').doc(eventId).get();
  //     if (eventSnap.exists) {
  //       final eventData = eventSnap.data()!;
  //       if ((eventData['endDate'] as Timestamp)
  //           .toDate()
  //           .isAfter(DateTime.now())) {
  //         myEvents[eventId] = eventData;
  //         if (!myTypes.contains(eventData['eventType'])) {
  //           myTypes.add(eventData['eventType']);
  //         }
  //       } else {
  //         wishlistEvents.remove(eventId);
  //         await store.collection('Users').doc(auth.currentUser!.uid).update({
  //           'wishlistEvents': wishlistEvents,
  //         });
  //       }
  //     } else {
  //       wishlistEvents.remove(eventId);
  //       await store.collection('Users').doc(auth.currentUser!.uid).update({
  //         'wishlistEvents': wishlistEvents,
  //       });
  //     }
  //   });
  //   setState(() {
  //     events = myEvents;
  //     types = myTypes;
  //     getEventsData = true;
  //   });
  // }

  // REMOVE
  Future<void> remove(
    String id,
    /*bool isEvent*/
  ) async {
    // if (isEvent) {
    //   events.removeWhere((key, value) => key == id);

    //   await store.collection('Users').doc(auth.currentUser!.uid).update({
    //     'wishlistEvents': events.keys.toList(),
    //   });
    // } else {
    setState(() {
      isData = false;
    });

    wishlistProducts.removeWhere((key, value) => key == id);
    categories = [];

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'wishlists': wishlistProducts.keys.toList(),
    });
    // }

    await getWishlists();
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

              // final Map<String, dynamic> householdCategories = {};

              // householdSubCategories.forEach((shopType, shopTypeData) {
              //   shopTypeData.forEach((categoryName, categoryImageUrl) {
              //     householdCategories.addAll({
              //       categoryName: categoryImageUrl,
              //     });
              //   });
              // });

              // await store
              //     .collection('Shop Types And Category Data')
              //     .doc('Just Category Data')
              //     .update({
              //   'householdCategories': householdCategories,
              // });
            },
            icon: const Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: 'Help',
          ),
        ],
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
        //         text: 'Products',
        //       ),
        //       Tab(
        //         text: 'Events',
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

            Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.0125,
              ),
              child: LayoutBuilder(
                builder: ((context, constraints) {
                  final width = constraints.maxWidth;
                  final currentWishlists = selectedCategory == null
                      ? wishlistProducts
                      : Map.fromEntries(
                          wishlistProducts.entries.where(
                            (entry) => entry.value[3] == selectedCategory,
                          ),
                        );

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CATEGORY CHIPS
                        !isData
                            ? SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.width * 0.175,
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
                                            (MediaQuery.of(context).size.width *
                                                    0.3)
                                                .toDouble(),
                                        height: 40,
                                      ),
                                    );
                                  }),
                                ),
                              )
                            : categories.length < 2
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
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: categories.length,
                                        itemBuilder: ((context, index) {
                                          final category = categories[index];

                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.01,
                                            ),
                                            child: ActionChip(
                                              label: Text(
                                                category.toString().trim(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                                    selectedCategory = category;
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

                        !isData
                            ? SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: 4,
                                  physics: const ClampingScrollPhysics(),
                                  itemBuilder: ((context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: SkeletonContainer(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 80,
                                      ),
                                    );
                                  }),
                                ),
                              )
                            : currentWishlists.isEmpty
                                ? const SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: Text(
                                        'No Products',
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    width: width,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: noOf > currentWishlists.length
                                          ? currentWishlists.length
                                          : noOf,
                                      itemBuilder: ((context, index) {
                                        final id = currentWishlists.keys
                                            .toList()[index];
                                        final name = currentWishlists.values
                                            .toList()[index][0];
                                        final imageUrl = currentWishlists.values
                                            .toList()[index][1];
                                        final price = currentWishlists.values
                                            .toList()[index][2];
                                        final data = currentWishlists.values
                                            .toList()[index][4];

                                        return Padding(
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
                                              visualDensity:
                                                  VisualDensity.comfortable,
                                              tileColor: white,
                                              shape: RoundedRectangleBorder(
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
                                                backgroundImage: NetworkImage(
                                                  imageUrl,
                                                ),
                                              ),
                                              title: Text(
                                                name.toString().trim(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Text(
                                                'Rs. ${price.round()}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              titleTextStyle: TextStyle(
                                                color: primaryDark,
                                                fontSize: width * 0.0475,
                                              ),
                                              subtitleTextStyle: TextStyle(
                                                color: primaryDark2,
                                                fontSize: width * 0.04,
                                              ),
                                              trailing: MyTextButton(
                                                onPressed: () async {
                                                  await remove(id);
                                                },
                                                text: 'Remove',
                                                textColor: Colors.red,
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
          ],
        ),

        // EVENTS
        // !getEventsData
        //     ? Column(
        //         children: [
        //           SizedBox(
        //             width: MediaQuery.of(context).size.width,
        //             height: MediaQuery.of(context).size.width * 0.175,
        //             child: ListView.builder(
        //               shrinkWrap: true,
        //               itemCount: 4,
        //               scrollDirection: Axis.horizontal,
        //               physics: const ClampingScrollPhysics(),
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
        //             final currentWishlists = selectedType == null
        //                 ? events
        //                 : Map.fromEntries(
        //                     events.entries.where(
        //                       (entry) =>
        //                           entry.value['eventType'] == selectedType,
        //                     ),
        //                   );

        //             return SingleChildScrollView(
        //               child: Column(
        //                 crossAxisAlignment: CrossAxisAlignment.start,
        //                 children: [
        //                   // TYPE CHIPS
        //                   types.length < 2
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
        //                               itemCount: types.length,
        //                               itemBuilder: ((context, index) {
        //                                 final type = types[index];

        //                                 return Padding(
        //                                   padding: EdgeInsets.symmetric(
        //                                     horizontal: width * 0.01,
        //                                   ),
        //                                   child: ActionChip(
        //                                     label: Text(
        //                                       type,
        //                                       style: TextStyle(
        //                                         color: selectedType == type
        //                                             ? white
        //                                             : primaryDark,
        //                                       ),
        //                                     ),
        //                                     tooltip: 'See $type',
        //                                     onPressed: () {
        //                                       int previousIndex =
        //                                           currentIndex;
        //                                       setState(() {
        //                                         if (selectedType == type) {
        //                                           selectedType = null;
        //                                         } else {
        //                                           selectedType = type;
        //                                         }
        //                                       });
        //                                       setState(() {
        //                                         tabController.index =
        //                                             previousIndex;
        //                                       });
        //                                     },
        //                                     backgroundColor:
        //                                         selectedType == type
        //                                             ? primaryDark
        //                                             : primary2,
        //                                   ),
        //                                 );
        //                               }),
        //                             ),
        //                           ),
        //                         ),

        //                   currentWishlists.isEmpty
        //                       ? const SizedBox(
        //                           height: 80,
        //                           child: Center(
        //                             child: Text(
        //                               'No Events',
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
        //                               itemCount: currentWishlists.length,
        //                               itemBuilder: ((context, index) {
        //                                 final id = currentWishlists.keys
        //                                     .toList()[index];
        //                                 final name = currentWishlists.values
        //                                     .toList()[index]['eventName'];
        //                                 final imageUrl = currentWishlists
        //                                     .values
        //                                     .toList()[index]['imageUrl'][0];
        //                                 final organizer = currentWishlists
        //                                         .values
        //                                         .toList()[index]
        //                                     ['organizerName'];

        //                                 return Slidable(
        //                                   endActionPane: ActionPane(
        //                                     extentRatio: 0.325,
        //                                     motion: const StretchMotion(),
        //                                     children: [
        //                                       SlidableAction(
        //                                         onPressed: (context) async {
        //                                           await remove(id, true);
        //                                         },
        //                                         backgroundColor: Colors.red,
        //                                         icon: Icons
        //                                             .heart_broken_outlined,
        //                                         label: 'Remove',
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
        //                                   child: Padding(
        //                                     padding: EdgeInsets.symmetric(
        //                                       vertical: width * 0.0125,
        //                                     ),
        //                                     child: GestureDetector(
        //                                       onTap: () {
        //                                         Navigator.of(context).push(
        //                                           MaterialPageRoute(
        //                                             builder: ((context) =>
        //                                                 EventPage(
        //                                                   eventId: id,
        //                                                 )),
        //                                           ),
        //                                         );
        //                                       },
        //                                       child: ListTile(
        //                                         splashColor: white,
        //                                         visualDensity: VisualDensity
        //                                             .comfortable,
        //                                         tileColor: primary2
        //                                             .withOpacity(0.5),
        //                                         shape:
        //                                             RoundedRectangleBorder(
        //                                           borderRadius:
        //                                               BorderRadius.circular(
        //                                                   12),
        //                                         ),
        //                                         leading: CircleAvatar(
        //                                           backgroundColor: primary2,
        //                                           backgroundImage:
        //                                               NetworkImage(
        //                                                   imageUrl),
        //                                         ),
        //                                         title: Text(
        //                                           name,
        //                                           maxLines: 2,
        //                                           overflow:
        //                                               TextOverflow.ellipsis,
        //                                         ),
        //                                         subtitle: Text(
        //                                           organizer == ''
        //                                               ? 'N/A'
        //                                               : organizer,
        //                                           maxLines: 2,
        //                                           overflow:
        //                                               TextOverflow.ellipsis,
        //                                         ),
        //                                         titleTextStyle: TextStyle(
        //                                           color: primaryDark,
        //                                           fontSize: width * 0.0475,
        //                                         ),
        //                                         subtitleTextStyle:
        //                                             TextStyle(
        //                                           color: primaryDark2,
        //                                           fontSize: width * 0.04,
        //                                         ),
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
