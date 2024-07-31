import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:Localsearch_User/models/services_image_map.dart';
import 'package:Localsearch_User/models/services_map.dart';
import 'package:Localsearch_User/page/main/services/services_sub_category_page.dart';
import 'package:Localsearch_User/page/main/services/services_place_page.dart';
import 'package:Localsearch_User/page/main/services/services_category_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/name_container.dart';
import 'package:Localsearch_User/widgets/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ServicesSearchPage extends StatefulWidget {
  const ServicesSearchPage({
    super.key,
    required this.search,
  });

  final String search;

  @override
  State<ServicesSearchPage> createState() => _ServicesSearchPageState();
}

class _ServicesSearchPageState extends State<ServicesSearchPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  List places = [];
  List categories = [];
  List subCategories = [];
  bool isData = false;
  bool isMicPressed = false;
  bool isSearchPressed = false;

  // INIT STATE
  @override
  void initState() {
    searchController.text = widget.search;
    getData();
    super.initState();
  }

  // GET DATA
  Future<void> getData() async {
    final serviceSnap = await store.collection('Services').get();

    for (var service in serviceSnap.docs) {
      final List myPlaces = List.from(service['Place']);
      final List myCategories = List.from(service['Category']);
      final List mySubCategories = List.from(service['SubCategory']);

      for (int i = myPlaces.length - 1; i >= 0; i--) {
        if (!(myPlaces[i].toLowerCase())
            .contains((widget.search).toLowerCase())) {
          myPlaces.removeAt(i);
        }
      }
      for (int i = myCategories.length - 1; i >= 0; i--) {
        if (!(myCategories[i].toLowerCase())
            .contains(widget.search.toLowerCase())) {
          myCategories.removeAt(i);
        }
      }
      for (int i = mySubCategories.length - 1; i >= 0; i--) {
        if (!(mySubCategories[i].toLowerCase())
            .contains(widget.search.toLowerCase())) {
          mySubCategories.removeAt(i);
        }
      }

      setState(() {
        places.addAll(myPlaces);
        categories.addAll(myCategories);
        subCategories.addAll(mySubCategories);
      });
    }

    setState(() {
      isData = true;
    });
  }

  // LISTEN
  Future<void> listen() async {
    var result = await showDialog(
      context: context,
      builder: ((context) => const SpeechToText()),
    );

    if (result != null && result is String) {
      setState(() {
        searchController.text = result;
      });
    }
  }

  // SEARCH
  Future<void> search() async {
    if (searchController.text.isNotEmpty) {
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) => ServicesSearchPage(
                  search: searchController.text,
                )),
          ),
        );
      }
    }
  }

  // GET PLACE
  String getPlace(String category) {
    String myPlaceKey = '';
    servicesMap.forEach((placeKey, placeValue) {
      placeValue.forEach((categoryKey, categoryValue) {
        if (categoryKey == category) {
          myPlaceKey = placeKey;
        }
      });
    });
    return myPlaceKey;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: !isData
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : places.isEmpty && categories.isEmpty && subCategories.isEmpty
              ? SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEARCH BAR
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: width * 0.0125,
                        ),
                        child: Container(
                          color: primary2.withOpacity(0.5),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: width * 0.1,
                                  height: width * 0.1825,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Icon(
                                    FeatherIcons.arrowLeft,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: width * 0.0125,
                                ),
                                child: Container(
                                  width: width * 0.875,
                                  height: width * 0.1825,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    border: Border.all(
                                      color: primaryDark.withOpacity(0.75),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: width * 0.6175,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: TextFormField(
                                          minLines: 1,
                                          maxLines: 1,
                                          controller: searchController,
                                          keyboardType: TextInputType.text,
                                          onTapOutside: (event) =>
                                              FocusScope.of(context).unfocus(),
                                          textInputAction:
                                              TextInputAction.search,
                                          decoration: const InputDecoration(
                                            hintText: 'Search',
                                            hintStyle: TextStyle(
                                              textBaseline:
                                                  TextBaseline.alphabetic,
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTapDown: (details) {
                                              setState(() {
                                                isMicPressed = true;
                                              });
                                            },
                                            onTapUp: (details) {
                                              setState(() {
                                                isMicPressed = false;
                                              });
                                            },
                                            onTapCancel: () {
                                              setState(() {
                                                isMicPressed = false;
                                              });
                                            },
                                            onTap: () async {
                                              await listen();
                                            },
                                            customBorder:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Container(
                                              width: width * 0.125,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isMicPressed
                                                    ? primary2.withOpacity(0.95)
                                                    : primary2
                                                        .withOpacity(0.25),
                                              ),
                                              child: Icon(
                                                FeatherIcons.mic,
                                                size: width * 0.06,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTapDown: (details) {
                                              setState(() {
                                                isSearchPressed = true;
                                              });
                                            },
                                            onTapUp: (details) {
                                              setState(() {
                                                isSearchPressed = false;
                                              });
                                            },
                                            onTapCancel: () {
                                              setState(() {
                                                isSearchPressed = false;
                                              });
                                            },
                                            onTap: () async {
                                              await search();
                                            },
                                            customBorder:
                                                const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(0),
                                                bottomLeft: Radius.circular(0),
                                                bottomRight:
                                                    Radius.circular(12),
                                                topRight: Radius.circular(12),
                                              ),
                                            ),
                                            child: Container(
                                              width: width * 0.125,
                                              decoration: BoxDecoration(
                                                color: isSearchPressed
                                                    ? primary2.withOpacity(0.95)
                                                    : primary2
                                                        .withOpacity(0.25),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(0),
                                                  bottomLeft:
                                                      Radius.circular(0),
                                                  bottomRight:
                                                      Radius.circular(7),
                                                  topRight: Radius.circular(7),
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                FeatherIcons.search,
                                                size: width * 0.06,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // NOTHING
                      const SizedBox(
                        height: 80,
                        child: Center(
                          child: Text('No One Available'),
                        ),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(
                      width * 0.0125,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // SEARCH BAR
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: width * 0.0125,
                            ),
                            child: Container(
                              color: primary2.withOpacity(0.5),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      width: width * 0.1,
                                      height: width * 0.1825,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      child: const Icon(
                                        FeatherIcons.arrowLeft,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: width * 0.0125,
                                    ),
                                    child: Container(
                                      width: width * 0.875,
                                      height: width * 0.1825,
                                      decoration: BoxDecoration(
                                        color: primary,
                                        border: Border.all(
                                          color: primaryDark.withOpacity(0.75),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: width * 0.6175,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                right: BorderSide(
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: TextFormField(
                                              minLines: 1,
                                              maxLines: 1,
                                              controller: searchController,
                                              keyboardType: TextInputType.text,
                                              onTapOutside: (event) =>
                                                  FocusScope.of(context)
                                                      .unfocus(),
                                              textInputAction:
                                                  TextInputAction.search,
                                              decoration: const InputDecoration(
                                                hintText: 'Search',
                                                hintStyle: TextStyle(
                                                  textBaseline:
                                                      TextBaseline.alphabetic,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              InkWell(
                                                onTapDown: (details) {
                                                  setState(() {
                                                    isMicPressed = true;
                                                  });
                                                },
                                                onTapUp: (details) {
                                                  setState(() {
                                                    isMicPressed = false;
                                                  });
                                                },
                                                onTapCancel: () {
                                                  setState(() {
                                                    isMicPressed = false;
                                                  });
                                                },
                                                onTap: () async {
                                                  await listen();
                                                },
                                                customBorder:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Container(
                                                  width: width * 0.125,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: isMicPressed
                                                        ? primary2
                                                            .withOpacity(0.95)
                                                        : primary2
                                                            .withOpacity(0.25),
                                                  ),
                                                  child: Icon(
                                                    FeatherIcons.mic,
                                                    size: width * 0.06,
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTapDown: (details) {
                                                  setState(() {
                                                    isSearchPressed = true;
                                                  });
                                                },
                                                onTapUp: (details) {
                                                  setState(() {
                                                    isSearchPressed = false;
                                                  });
                                                },
                                                onTapCancel: () {
                                                  setState(() {
                                                    isSearchPressed = false;
                                                  });
                                                },
                                                onTap: () async {
                                                  await search();
                                                },
                                                customBorder:
                                                    const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft: Radius.circular(0),
                                                    bottomLeft:
                                                        Radius.circular(0),
                                                    bottomRight:
                                                        Radius.circular(12),
                                                    topRight:
                                                        Radius.circular(12),
                                                  ),
                                                ),
                                                child: Container(
                                                  width: width * 0.125,
                                                  decoration: BoxDecoration(
                                                    color: isSearchPressed
                                                        ? primary2
                                                            .withOpacity(0.95)
                                                        : primary2
                                                            .withOpacity(0.25),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(0),
                                                      bottomLeft:
                                                          Radius.circular(0),
                                                      bottomRight:
                                                          Radius.circular(7),
                                                      topRight:
                                                          Radius.circular(7),
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    FeatherIcons.search,
                                                    size: width * 0.06,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // PLACES
                          places.isEmpty
                              ? Container()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0166,
                                      ),
                                      child: const Text('Places'),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 16 / 9,
                                        ),
                                        itemCount: places.length,
                                        itemBuilder: ((context, index) {
                                          final name = places[index];
                                          final imageUrl = placeImageMap[name];

                                          return NameContainer(
                                            text: name,
                                            imageUrl: imageUrl!,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: ((context) =>
                                                      ServicesPlacePage(
                                                        place: name,
                                                      )),
                                                ),
                                              );
                                            },
                                            width: width,
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),

                          // CATEGORY
                          categories.isEmpty
                              ? Container()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0166,
                                      ),
                                      child: const Text('Categories'),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: categories.length,
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 16 / 9,
                                        ),
                                        itemBuilder: ((context, index) {
                                          final name = categories[index];
                                          final imageUrl =
                                              categoryImageMap[name];
                                          final place = getPlace(name);

                                          return NameContainer(
                                            text: name,
                                            imageUrl: imageUrl!,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: ((context) =>
                                                      ServicesCategoryPage(
                                                        place: place,
                                                        category: name,
                                                      )),
                                                ),
                                              );
                                            },
                                            width: width,
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),

                          // SUB CATEGORIES
                          subCategories.isEmpty
                              ? Container()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0166,
                                      ),
                                      child: const Text('Sub Categories'),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: const ClampingScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 16 / 9,
                                        ),
                                        itemCount: subCategories.length,
                                        itemBuilder: ((context, index) {
                                          final name = subCategories[index];
                                          final imageUrl =
                                              subCategoryImageMap[name];

                                          return NameContainer(
                                            text: name,
                                            imageUrl: imageUrl!,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: ((context) =>
                                                      ServicesSubCategoryPage(
                                                        subCategory: name,
                                                      )),
                                                ),
                                              );
                                            },
                                            width: width,
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
