import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/models/business_categories.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/text_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  String name = '';
  String recentShop = '';

  List<int> numbers = [0, 1, 2, 3];
  List<int> reverseNumbers = [4, 5, 6, 7];

  // INIT STATE
  @override
  void initState() {
    getUserName();
    super.initState();
  }

  // GET USER NAME
  getUserName() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    setState(() {
      name = userData['Name'];
    });

    return name;
  }

  // GET RECENT SHOP
  getRecentShop() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    setState(() {
      recentShop = userData['recentShop'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Hello, '),
            Text(
              name,
              style: TextStyle(
                color: primaryDark2,
                fontSize: MediaQuery.of(context).size.width * 0.07,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(FeatherIcons.search),
            tooltip: 'Search',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.0225,
          vertical: MediaQuery.of(context).size.width * 0.0166,
        ),
        child: LayoutBuilder(
          builder: ((context, constraints) {
            final double width = constraints.maxWidth;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CATEGORIES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.025,
                          vertical: width * 0.025,
                        ),
                        child: Text(
                          'Categories',
                          style: TextStyle(
                            color: primaryDark,
                            fontSize: width * 0.07,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      MyTextButton(
                        onPressed: () {},
                        text: 'See All',
                        textColor: primaryDark2,
                      ),
                    ],
                  ),
                  // CATEGORIES BOX
                  Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: width,
                          height: width * 0.3,
                          child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: 4,
                            itemBuilder: ((context, index) {
                              final String name =
                                  businessCategories[numbers[index]][0];
                              final String imageUrl =
                                  businessCategories[numbers[index]][1];

                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.025,
                                  vertical: width * 0.015,
                                ),
                                child: Container(
                                  width: width * 0.2,
                                  height: width * 0.25,
                                  decoration: BoxDecoration(
                                    color: white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0125,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            height: width * 0.175,
                                          ),
                                        ),
                                        Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          height: width * 0.3,
                          child: ListView.builder(
                            // shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: 4,
                            itemBuilder: ((context, index) {
                              final String name =
                                  businessCategories[reverseNumbers[index]][0];
                              final String imageUrl =
                                  businessCategories[reverseNumbers[index]][1];

                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.025,
                                  vertical: width * 0.015,
                                ),
                                child: Container(
                                  width: width * 0.2,
                                  height: width * 0.25,
                                  decoration: BoxDecoration(
                                    color: white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0125,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            imageUrl,
                                            height: width * 0.175,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
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
                  ),

                  // RECENT
                  recentShop != ''
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.025,
                            vertical: width * 0.025,
                          ),
                          child: Text(
                            'Recent',
                            style: TextStyle(
                              color: primaryDark,
                              fontSize: width * 0.07,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
