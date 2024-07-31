import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:http/http.dart' as http;
import 'package:Localsearch_User/page/main/events/event_page.dart';
import 'package:Localsearch_User/page/main/events/events_organizer_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/skeleton_container.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:Localsearch_User/widgets/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventsSearchResultsPage extends StatefulWidget {
  const EventsSearchResultsPage({
    super.key,
    required this.search,
  });

  final String search;

  @override
  State<EventsSearchResultsPage> createState() =>
      _EventsSearchResultsPageState();
}

class _EventsSearchResultsPageState extends State<EventsSearchResultsPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  bool isMicPressed = false;
  bool isSearchPressed = false;
  Map searchedEvents = {};
  Map allSearchedEvents = {};
  Map searchedOrganizers = {};
  List eventCategories = [];
  bool isOrganizersData = false;
  bool isEventsData = false;
  bool isEventCategoriesData = false;
  String? selectedEventCategory;

  // INIT STATE
  @override
  void initState() {
    setSearch();
    getEvents();
    getOrganizers();
    super.initState();
  }

  // SET SEARCH
  void setSearch() {
    setState(() {
      searchController.text = widget.search;
    });
  }

  // LISTEN
  Future<void> listen() async {
    var result = await showDialog(
      context: context,
      builder: ((context) => const SpeechToText()),
    );

    if (result != null && result is String) {
      searchController.text = result;
    }
  }

  // SEARCH
  Future<void> search() async {
    if (searchController.text.isNotEmpty) {
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) =>
                EventsSearchResultsPage(search: searchController.text)),
          ),
        );
      }
    }
  }

  // GET EVENTS
  Future<void> getEvents() async {
    Map<String, dynamic> mySearchedEvents = {};

    final eventsSnap = await store.collection('Events').get();

    for (var myEventData in eventsSnap.docs) {
      final eventData = myEventData.data();

      final String eventId = eventData['eventId'];
      final String eventName = eventData['eventName'];
      final String imageUrl = eventData['imageUrl'][0];
      final String type = eventData['eventType'];
      final Timestamp startDate = eventData['startDate'];
      final Timestamp endDate = eventData['endDate'];
      final String organizerId = eventData['organizerId'];
      final String organizerName = eventData['organizerName'];

      final eventNameLower = eventName.toLowerCase();
      final searchLower = widget.search.toLowerCase();

      if (eventNameLower.contains(searchLower) &&
          endDate.toDate().isAfter(DateTime.now())) {
        int relevanceScore = calculateRelevanceScore(
          eventNameLower,
          searchLower,
        );

        mySearchedEvents[eventName] = [
          imageUrl,
          organizerId,
          organizerName,
          eventId,
          relevanceScore,
          type,
          startDate,
          endDate,
        ];
      }
    }

    mySearchedEvents = Map.fromEntries(mySearchedEvents.entries.toList()
      ..sort((a, b) => b.value[4].compareTo(a.value[4])));

    setState(() {
      searchedEvents = mySearchedEvents;
      allSearchedEvents = mySearchedEvents;
      isEventsData = true;
    });

    getEventCategories(mySearchedEvents);
  }

  // GET EVENT CATEGORIES
  void getEventCategories(Map<dynamic, dynamic> events) {
    List myEventCategories = [];
    for (var event in events.values) {
      final type = event[5];

      if (!myEventCategories.contains(type)) {
        myEventCategories.add(type);
      }
    }

    setState(() {
      eventCategories = myEventCategories;
      isEventCategoriesData = true;
    });
  }

  // GET TYPE EVENT
  void getTypeEvent(String? type) {
    Map<String, dynamic> filteredEvents = {};
    setState(() {
      searchedEvents = allSearchedEvents;
    });

    if (type != null) {
      searchedEvents.forEach((eventName, eventDetails) {
        if (eventDetails[5] == type) {
          filteredEvents[eventName] = eventDetails;
        }
      });

      setState(() {
        searchedEvents = filteredEvents;
      });
    }
  }

  // CALCULATE RELEVANCE (EVENTS)
  int calculateRelevanceScore(String eventName, String searchKeyword) {
    int score = 0;

    for (int i = 0; i < eventName.length; i++) {
      if (i < searchKeyword.length && eventName[i] == searchKeyword[i]) {
        score += (eventName.length - i) * 3;
      } else {
        break;
      }
    }

    return score;
  }

  // GET ORGANIZERS
  Future<void> getOrganizers() async {
    Map<String, dynamic> allOrganizers = {};

    final organizerSnap = await store.collection('Organizers').get();

    for (var organizerSnap in organizerSnap.docs) {
      final organizerData = organizerSnap.data();

      final String name = organizerData['Name'];
      final String imageUrl = organizerData['Image'];
      final double latitude = organizerData['Latitude'];
      final double longitude = organizerData['Longitude'];
      final String organizerId = organizerSnap.id;

      allOrganizers[organizerId] = {
        'name': name,
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'id': organizerId,
      };
    }

    List<MapEntry<String, int>> relevanceScores = [];

    allOrganizers.forEach((key, value) {
      String organizerName = value['name'];
      if (organizerName.toLowerCase().startsWith(widget.search.toLowerCase())) {
        int relevance = calculateOrganizerRelevance(
            organizerName, widget.search.toLowerCase());
        relevanceScores.add(MapEntry(key, relevance));
      }
    });

    relevanceScores.sort((a, b) {
      int relevanceComparison = b.value.compareTo(a.value);
      if (relevanceComparison != 0) {
        return relevanceComparison;
      }
      return a.key.compareTo(b.key);
    });

    Map<String, dynamic> filteredOrganizers = {};

    for (var entry in relevanceScores) {
      filteredOrganizers[entry.key] = allOrganizers[entry.key];
    }

    setState(() {
      searchedOrganizers = filteredOrganizers;
      isOrganizersData = true;
    });
  }

  // CALCULATE RELEVANCE (ORGANIZERS)
  int calculateOrganizerRelevance(String organizerName, String searchKeyword) {
    int count = 0;
    for (int i = 0; i <= organizerName.length - searchKeyword.length; i++) {
      if (organizerName.substring(i, i + searchKeyword.length).toLowerCase() ==
          searchKeyword) {
        count++;
      }
    }
    return count;
  }

  // GET IF WISHLIST
  Stream<bool> getIfWishlist(String eventId) {
    return store
        .collection('Users')
        .doc(auth.currentUser!.uid)
        .snapshots()
        .map((userSnap) {
      final userData = userSnap.data()!;
      final userWishlist = userData['wishlistEvents'] as List;

      return userWishlist.contains(eventId);
    });
  }

  // WISHLIST EVENT
  Future<void> wishlistEvent(String eventId) async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    List<dynamic> userWishlist = userData['wishlistEvents'] as List<dynamic>;

    bool alreadyInWishlist = userWishlist.contains(eventId);

    if (!alreadyInWishlist) {
      userWishlist.add(eventId);
    } else {
      userWishlist.remove(eventId);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'wishlistEvents': userWishlist,
    });

    final eventSnap = await store.collection('Events').doc(eventId).get();

    final eventData = eventSnap.data()!;

    int noOfWishList = eventData['wishlists'] ?? 0;

    if (!alreadyInWishlist) {
      noOfWishList++;
    } else {
      noOfWishList--;
    }

    await store.collection('Events').doc(eventId).update({
      'wishlists': noOfWishList,
    });
  }

  // GET ADDRESS
  Future<String> getAddress(double shopLatitude, double shopLongitude) async {
    const apiKey = 'AIzaSyCTzhOTUtdVUx0qpAbcXdn1TQKSmqtJbZM';
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final double width = constraints.maxWidth;

              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: SingleChildScrollView(
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
                                        width: width * 0.6125,
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
                                                      Radius.circular(12),
                                                  topRight: Radius.circular(12),
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

                      searchedOrganizers.isEmpty
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.all(width * 0.0225),
                              child: Text(
                                'Organizers',
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.8),
                                  fontSize: width * 0.04,
                                ),
                              ),
                            ),

                      // ORGANIZERS LIST
                      !isOrganizersData
                          ? SizedBox(
                              width: width,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: 2,
                                physics: ClampingScrollPhysics(),
                                itemBuilder: ((context, index) {
                                  return Container(
                                    width: width,
                                    height: width * 0.225,
                                    decoration: BoxDecoration(
                                      color: lightGrey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0225,
                                    ),
                                    margin: EdgeInsets.all(
                                      width * 0.0125,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SkeletonContainer(
                                              width: width * 0.15,
                                              height: width * 0.15,
                                            ),
                                            SizedBox(
                                              width: width * 0.0225,
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SkeletonContainer(
                                                  width: width * 0.33,
                                                  height: 20,
                                                ),
                                                SkeletonContainer(
                                                  width: width * 0.2,
                                                  height: 12,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SkeletonContainer(
                                          width: width * 0.075,
                                          height: width * 0.075,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            )
                          : searchedOrganizers.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'No Organizers Found',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: width,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: searchedOrganizers.length > 3
                                        ? 3
                                        : searchedOrganizers.length,
                                    itemBuilder: ((context, index) {
                                      final currentOrganizer =
                                          searchedOrganizers.keys
                                              .toList()[index];

                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.0125,
                                          vertical: width * 0.00625,
                                        ),
                                        child: ListTile(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    EventsOrganizerPage(
                                                      organizerId:
                                                          searchedOrganizers[
                                                                  currentOrganizer]
                                                              ['id'],
                                                    )),
                                              ),
                                            );
                                          },
                                          splashColor: white,
                                          tileColor:
                                              primary2.withOpacity(0.125),
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: width * 0.0125,
                                            horizontal: width * 0.025,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          leading: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              searchedOrganizers[
                                                  currentOrganizer]['imageUrl'],
                                            ),
                                            radius: width * 0.0575,
                                          ),
                                          title: Text(
                                            searchedOrganizers[currentOrganizer]
                                                ['name'],
                                            style: TextStyle(
                                              fontSize: width * 0.06125,
                                            ),
                                          ),
                                          subtitle: FutureBuilder(
                                              future: getAddress(
                                                searchedOrganizers[
                                                        currentOrganizer]
                                                    ['latitude'],
                                                searchedOrganizers[
                                                        currentOrganizer]
                                                    ['longitude'],
                                              ),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasError) {
                                                  return Container();
                                                }

                                                if (snapshot.hasData) {
                                                  return Text(
                                                    snapshot.data!,
                                                  );
                                                }

                                                return Container();
                                              }),
                                          trailing: const Icon(
                                            FeatherIcons.chevronRight,
                                            color: primaryDark,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                      searchedOrganizers.isNotEmpty && searchedEvents.isNotEmpty
                          ? const Divider()
                          : Container(),

                      // EVENT
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // EVENTS
                          !isEventsData
                              ? SkeletonContainer(
                                  width: width * 0.2,
                                  height: 20,
                                )
                              : searchedEvents.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 40),
                                        child: Text(
                                          'No Events Found',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: EdgeInsets.all(width * 0.0225),
                                      child: Text(
                                        'Events',
                                        style: TextStyle(
                                          color: primaryDark.withOpacity(0.8),
                                          fontSize: width * 0.04,
                                        ),
                                      ),
                                    ),

                          // FILTERS
                          eventCategories.length < 2
                              ? Container()
                              : SizedBox(
                                  width: width,
                                  height: 50,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: eventCategories.length,
                                    itemBuilder: ((context, index) {
                                      final name = eventCategories[index];

                                      return Padding(
                                        padding: EdgeInsets.all(width * 0.0125),
                                        child: ActionChip(
                                          label: Text(
                                            name,
                                            style: TextStyle(
                                              color:
                                                  selectedEventCategory == name
                                                      ? white
                                                      : primaryDark,
                                            ),
                                          ),
                                          tooltip: 'Select $name',
                                          onPressed: () {
                                            setState(() {
                                              if (selectedEventCategory ==
                                                  name) {
                                                selectedEventCategory = null;
                                              } else {
                                                selectedEventCategory = name;
                                              }
                                            });
                                            getTypeEvent(selectedEventCategory);
                                          },
                                          backgroundColor:
                                              selectedEventCategory == name
                                                  ? primaryDark
                                                  : primary2,
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                          // EVENTS LIST
                          !isEventsData
                              ? SizedBox(
                                  width: width,
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.825,
                                    ),
                                    itemCount: 6,
                                    itemBuilder: ((context, index) {
                                      return Padding(
                                        padding: EdgeInsets.all(width * 0.0225),
                                        child: Container(
                                          width: width * 0.28,
                                          height: width * 0.3,
                                          decoration: BoxDecoration(
                                            color: lightGrey,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: SkeletonContainer(
                                                  width: width * 0.4,
                                                  height: width * 0.4,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: width * 0.0225,
                                                ),
                                                child: SkeletonContainer(
                                                  width: width * 0.4,
                                                  height: width * 0.04,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: width * 0.0225,
                                                ),
                                                child: SkeletonContainer(
                                                  width: width * 0.2,
                                                  height: width * 0.03,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                )
                              : searchedEvents.isEmpty
                                  ? Container()
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: width * 0.6 / width,
                                      ),
                                      itemCount: searchedEvents.length,
                                      itemBuilder: ((context, index) {
                                        return StreamBuilder<bool>(
                                          stream: getIfWishlist(
                                            searchedEvents.values
                                                .toList()[index][3],
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              return const Center(
                                                child: Text(
                                                  'Something went wrong',
                                                ),
                                              );
                                            }

                                            final currentEvent = searchedEvents
                                                .keys
                                                .toList()[index]
                                                .toString();

                                            final image =
                                                searchedEvents[currentEvent][0];

                                            final eventId = searchedEvents
                                                .values
                                                .toList()[index][3];

                                            final price = searchedEvents[
                                                        currentEvent][2] ==
                                                    ''
                                                ? 'N/A'
                                                : searchedEvents[currentEvent]
                                                    [2];
                                            final isWishListed =
                                                snapshot.data ?? false;

                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: ((context) =>
                                                        EventPage(
                                                          eventId: eventId,
                                                        )),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    width: 0.25,
                                                    color:
                                                        Colors.grey.withOpacity(
                                                      0.25,
                                                    ),
                                                  ),
                                                ),
                                                padding: EdgeInsets.all(
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.0125,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Center(
                                                      child: Image.network(
                                                        image,
                                                        fit: BoxFit.cover,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.5,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.58,
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceAround,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .only(
                                                                left: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.00625,
                                                                right: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.00625,
                                                                top: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.0225,
                                                              ),
                                                              child: SizedBox(
                                                                width:
                                                                    width * 0.3,
                                                                child: Text(
                                                                  currentEvent,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        width *
                                                                            0.0575,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                horizontal: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.0125,
                                                              ),
                                                              child: Text(
                                                                price,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      width *
                                                                          0.05,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        IconButton(
                                                          onPressed: () async {
                                                            await wishlistEvent(
                                                                eventId);
                                                          },
                                                          icon: Icon(
                                                            isWishListed
                                                                ? Icons.favorite
                                                                : Icons
                                                                    .favorite_border,
                                                            color: Colors.red,
                                                          ),
                                                          color: Colors.red,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }),
                                    ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
