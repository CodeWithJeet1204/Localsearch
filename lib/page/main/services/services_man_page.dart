import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localy_user/models/services_image_map.dart';
import 'package:localy_user/models/services_map.dart';
import 'package:localy_user/page/main/services/services_previous_work_images_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/snack_bar.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesManPage extends StatefulWidget {
  const ServicesManPage({
    super.key,
    required this.id,
  });

  final String id;

  @override
  State<ServicesManPage> createState() => _ServicesManPageState();
}

class _ServicesManPageState extends State<ServicesManPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> servicemanData = {};
  Map<String, dynamic> previousWorkImages = {};
  Map<String, dynamic> allServiceManSubCategories = {};
  Map<String, dynamic> subCategories = {};
  List categories = [];
  List places = [];
  String? selectedCategory;
  String? selectedPlace;
  bool isData = true;

  // INIT STATE
  @override
  void initState() {
    getServiceManData();
    getSubCategories();
    super.initState();
  }

  // GET SERVICEMAN DATA
  Future<void> getServiceManData() async {
    final servicemanSnap =
        await store.collection('Services').doc(widget.id).get();

    final myServicemanData = servicemanSnap.data()!;

    setState(() {
      servicemanData = myServicemanData;
    });

    getPreviousWorkImages(myServicemanData);
  }

  void getPreviousWorkImages(Map<String, dynamic> data) {
    final Map<String, dynamic> myPreviousWorkImages = data['workImages'];

    setState(() {
      previousWorkImages = myPreviousWorkImages;
    });
  }

  // GET SUB CATEGORIES
  Future<void> getSubCategories() async {
    final servicemanSnap =
        await store.collection('Services').doc(widget.id).get();

    final myServicemanData = servicemanSnap.data()!;

    final Map<String, dynamic> mySubCategories =
        myServicemanData['SubCategory'];

    setState(() {
      allServiceManSubCategories = mySubCategories;
      subCategories = mySubCategories;
    });

    getCategories(mySubCategories);
  }

  // GET CATEGORIES
  void getCategories(Map<String, dynamic> subCategories) {
    Set<String> uniqueCategories = {};

    subCategories.forEach((subCategoryName, _) {
      servicesMap.forEach((place, categoriesMap) {
        categoriesMap.forEach((category, subCategoryList) {
          if (subCategoryList.contains(subCategoryName)) {
            uniqueCategories.add(category);
          }
        });
      });
    });

    setState(() {
      categories = uniqueCategories.toList();
    });

    getPlaces(subCategories);
  }

  // GET PLACES
  void getPlaces(Map<String, dynamic> subCategories) {
    Set<String> uniquePlaces = {};

    subCategories.forEach((subCategoryName, _) {
      servicesMap.forEach((place, categoriesMap) {
        categoriesMap.forEach((category, subCategoryList) {
          if (subCategoryList.contains(subCategoryName)) {
            uniquePlaces.add(place);
          }
        });
      });
    });

    setState(() {
      places = uniquePlaces.toList();
      isData = true;
    });
  }

  // GET CATEGORIES FOR SELECTED PLACE
  void getCategoriesForPlace(String? selectedPlace) {
    if (selectedPlace != null) {
      Set<String> uniqueCategories = {};
      final categoriesMapForPlace = servicesMap[selectedPlace];
      if (categoriesMapForPlace != null) {
        allServiceManSubCategories.forEach((subCategoryName, _) {
          categoriesMapForPlace.forEach((category, subCategoryList) {
            for (var subCategoryName in allServiceManSubCategories.keys) {
              if (subCategoryList.contains(subCategoryName)) {
                uniqueCategories.add(category);
              }
            }
          });
        });
      }
      setState(() {
        categories = uniqueCategories.toList();
      });
    } else {
      Set<String> uniqueCategories = {};
      subCategories.forEach((subCategoryName, _) {
        servicesMap.forEach((place, categoriesMap) {
          categoriesMap.forEach((category, subCategoryList) {
            if (subCategoryList.contains(subCategoryName)) {
              uniqueCategories.add(category);
            }
          });
        });
      });
      setState(() {
        categories = uniqueCategories.toList();
      });
    }
  }

  // GET SUBCATEGORIES FOR SELECTED PLACE
  void getSubCategoriesForPlace(String? selectedPlace) {
    if (selectedPlace != null) {
      Map<String, dynamic> filteredCategories = {};
      allServiceManSubCategories.forEach((subCategoryName, _) {
        servicesMap[selectedPlace]!.forEach((categoryName, subCategoryList) {
          for (var subCategory in subCategoryList) {
            if (subCategoryName == subCategory) {
              filteredCategories[subCategory] =
                  allServiceManSubCategories[subCategory];
            }
          }
        });
      });
      setState(() {
        subCategories = filteredCategories;
      });
    } else {
      null;
    }
  }

  // GET SUBCATEGORIES FOR SELECTED CATEGORY
  void getSubCategoriesForCategory(String? selectedCategory) {
    if (selectedCategory != null) {
      Map<String, dynamic> filteredSubCategories = {};

      allServiceManSubCategories.forEach((subCategoryName, _) {
        servicesMap.forEach((place, placeMap) {
          placeMap.forEach((category, subCategoryList) {
            if (category == selectedCategory) {
              for (var subCategory in subCategoryList) {
                if (subCategoryName == subCategory) {
                  filteredSubCategories[subCategory] =
                      allServiceManSubCategories[subCategory];
                }
              }
            }
          });
        });
      });

      setState(() {
        subCategories = filteredSubCategories;
      });
    } else {
      setState(() {
        subCategories = allServiceManSubCategories;
      });
    }
  }

  // SHOW IMAGE
  Future<void> showImage() async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: ((context) {
        return Dialog(
          elevation: 20,
          child: InteractiveViewer(
            child: Image.network(
              servicemanData['Image'] ??
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/ProhibitionSign2.svg/800px-ProhibitionSign2.svg.png',
            ),
          ),
        );
      }),
    );
  }

  // CALL VENDOR
  Future<void> callVendor(Map<String, dynamic> data) async {
    final Uri url = Uri(
      scheme: 'tel',
      path: data['Phone Number'],
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        mySnackBar('Some error occured', context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width * 0.006125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final width = constraints.maxWidth;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DETAILS & CONTACT
                    Container(
                      width: width,
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(bottom: width * 0.01),
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.0225,
                        vertical: width * 0.01125,
                      ),
                      color: primary,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // IMAGE
                          GestureDetector(
                            onTap: () async {
                              await showImage();
                            },
                            child: CircleAvatar(
                              radius: width * 0.1195,
                              backgroundColor: primary2,
                              backgroundImage: NetworkImage(
                                servicemanData['Image'] ??
                                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpFN1Tvo80rYwu-eXsDNNzsuPITOdtyRPlYIsIqKaIbw&s',
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // NAME
                          SizedBox(
                            width: width * 0.8,
                            child: Text(
                              servicemanData['Name'] ?? 'N/A',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: width * 0.07,
                                fontWeight: FontWeight.w700,
                                color: primaryDark.withBlue(5),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // CONTACT & CHAT
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // CALL
                              GestureDetector(
                                onTap: () async {
                                  await callVendor(servicemanData);
                                },
                                child: Container(
                                  width: width * 0.45,
                                  height: 40,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.00625,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary2.withOpacity(0.5),
                                    border: Border.all(
                                      color: primaryDark.withOpacity(0.5),
                                      width: 0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Call',
                                        style: TextStyle(
                                          color: primaryDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(FeatherIcons.phone),
                                    ],
                                  ),
                                ),
                              ),

                              // WHATSAPP
                              GestureDetector(
                                onTap: () async {
                                  final String phoneNumber =
                                      servicemanData['Phone Number'];
                                  const String message =
                                      'Hey, I found you on Localy\n';
                                  final url =
                                      'https://wa.me/$phoneNumber?text=$message';

                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url));
                                  } else {
                                    if (context.mounted) {
                                      mySnackBar(
                                        'Something went Wrong',
                                        context,
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  width: width * 0.45,
                                  height: 40,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.00625,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromRGBO(198, 255, 200, 1),
                                    border: Border.all(
                                      color: primaryDark.withOpacity(0.25),
                                      width: 0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Whatsapp',
                                        style: TextStyle(
                                          color: primaryDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(FeatherIcons.messageCircle),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    previousWorkImages.isEmpty ? Container() : const Divider(),

                    previousWorkImages.isEmpty
                        ? Container()
                        : Padding(
                            padding: EdgeInsets.all(width * 0.0125),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: ((context) =>
                                        ServicesPreviousWorkImagesPage(
                                          imagesData: previousWorkImages,
                                        )),
                                  ),
                                );
                              },
                              splashColor: white,
                              customBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                width: width,
                                decoration: BoxDecoration(
                                  color: primary2.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.all(width * 0.045),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'See Previous Work',
                                      style: TextStyle(
                                        fontSize: width * 0.05,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Icon(FeatherIcons.chevronRight),
                                  ],
                                ),
                              ),
                            ),
                          ),

                    const Divider(),

                    // PLACES CHIPS
                    SizedBox(
                      width: width,
                      height: 50,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: places.length,
                        itemBuilder: ((context, index) {
                          final String place = places[index];

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.01,
                            ),
                            child: ActionChip(
                              label: Text(
                                place,
                                style: TextStyle(
                                  color: selectedPlace == place
                                      ? white
                                      : primaryDark,
                                ),
                              ),
                              tooltip: 'See $place',
                              onPressed: () {
                                setState(() {
                                  if (selectedPlace == place) {
                                    selectedPlace = null;
                                  } else {
                                    selectedPlace = place;
                                  }
                                });
                                getCategoriesForPlace(selectedPlace);
                                getSubCategoriesForPlace(selectedPlace);
                                if (categories.length == 1) {
                                  setState(() {
                                    selectedCategory = categories[0];
                                  });
                                }
                              },
                              backgroundColor: selectedPlace == place
                                  ? primaryDark
                                  : primary2,
                            ),
                          );
                        }),
                      ),
                    ),

                    // CATEGORY CHIPS
                    SizedBox(
                      width: width,
                      height: 50,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: ((context, index) {
                          final String category = categories[index];

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.01,
                            ),
                            child: ActionChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  color: selectedCategory == category
                                      ? white
                                      : primaryDark,
                                ),
                              ),
                              tooltip: 'See $category',
                              onPressed: categories.length <= 1 &&
                                      selectedCategory == category
                                  ? () {}
                                  : () {
                                      setState(() {
                                        if (selectedCategory == category) {
                                          selectedCategory = null;
                                        } else {
                                          selectedCategory = category;
                                        }
                                      });
                                      getSubCategoriesForCategory(
                                          selectedCategory);
                                    },
                              backgroundColor: selectedCategory == category
                                  ? primaryDark
                                  : primary2,
                            ),
                          );
                        }),
                      ),
                    ),

                    // SERVICES CHARGES
                    SizedBox(
                      width: width,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: subCategories.length,
                        itemBuilder: ((context, index) {
                          final name = subCategories.keys.toList()[index];
                          final price = subCategories.values.toList()[index][0];
                          final method =
                              subCategories.values.toList()[index][1];
                          final imageUrl = subCategoryImageMap[name];

                          return Container(
                            width: width,
                            height: 84,
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 1,
                                color: primaryDark,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              image: imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                      opacity: 0.175,
                                    )
                                  : null,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            margin: EdgeInsets.all(width * 0.0125),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: width * 0.6,
                                  height: 50,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: AutoSizeText(
                                      name,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontWeight: FontWeight.w500,
                                        fontSize: width * 0.06,
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      width: width * 0.2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: AutoSizeText(
                                          price == '0'
                                              ? 'Rs. --'
                                              : 'Rs. $price',
                                          style: TextStyle(
                                            fontSize: width * 0.055,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: width * 0.3,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Per ',
                                                style: TextStyle(
                                                  color: primaryDark,
                                                ),
                                              ),
                                              TextSpan(
                                                text: method,
                                                style: TextStyle(
                                                  color: primaryDark,
                                                  fontSize: width * 0.05,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
