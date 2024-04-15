import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/vendor/vendor_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/skeleton_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class FollowedShopsPage extends StatefulWidget {
  const FollowedShopsPage({super.key});

  @override
  State<FollowedShopsPage> createState() => _FollowedShopsPageState();
}

class _FollowedShopsPageState extends State<FollowedShopsPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, List<String>> shops = {};
  List<String> types = [];
  String? selectedType;
  bool getData = false;

  // INIT STATE
  @override
  void initState() {
    getFollowedShops();
    super.initState();
  }

  // GET FOLLOWED SHOPS
  Future<void> getFollowedShops() async {
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

      final vendorData = vendorSnap.data()!;
      final id = vendorId as String;
      final name = vendorData['Name'] as String;
      final imageUrl = vendorData['Image'] as String;
      final address = vendorData['Address'] as String;
      final type = vendorData['Type'] as String;

      vendors[id] = [name, imageUrl, address, type];
    });

    setState(() {
      shops = vendors;
    });

    await getShopTypes(shops);
  }

  // GET SHOP TYPES
  Future<void> getShopTypes(Map<String, List<String>> shops) async {
    List<String> myTypes = ['Electronics'];

    shops.forEach((key, value) {
      final myType = value[3];
      if (!myTypes.contains(myType)) {
        myTypes.add(myType);
      }
    });

    setState(() {
      types = myTypes;
      getData = true;
    });
  }

  // REMOVE
  Future<void> remove(String id) async {
    shops.removeWhere((key, value) => key == id);

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'followedShops': shops.keys.toList(),
    });

    await getFollowedShops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Followed Shops"),
      ),
      body: SafeArea(
        child: !getData
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
                          padding: EdgeInsets.all(8),
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
                          padding: EdgeInsets.all(8),
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
                    final currentShops = selectedType == null
                        ? shops
                        : Map.fromEntries(
                            shops.entries.where(
                                (entry) => entry.value[3] == selectedType),
                          );

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SHOP TYPE CHIPS
                          Padding(
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
                                      tooltip: "See $type",
                                      onPressed: () {
                                        setState(() {
                                          if (selectedType == type) {
                                            selectedType = null;
                                          } else {
                                            selectedType = type;
                                          }
                                        });
                                      },
                                      backgroundColor: selectedType == type
                                          ? primaryDark
                                          : primary2,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0125,
                              vertical: width * 0.0125,
                            ),
                            child: SizedBox(
                              width: width,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: currentShops.length,
                                itemBuilder: ((context, index) {
                                  final id = currentShops.keys.toList()[index];
                                  final name =
                                      currentShops.values.toList()[index][0];
                                  final imageUrl =
                                      currentShops.values.toList()[index][1];
                                  final address =
                                      currentShops.values.toList()[index][2];

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
                                          label: "Unfollow",
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) => VendorPage(
                                                  vendorId: id,
                                                )),
                                          ),
                                        );
                                      },
                                      child: ListTile(
                                        splashColor: white,
                                        visualDensity:
                                            VisualDensity.comfortable,
                                        tileColor: primary2.withOpacity(0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
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
      ),
    );
  }
}
