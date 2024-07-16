import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localy_user/models/events_categories.dart';
import 'package:localy_user/page/main/events/all_event_types_page.dart';
import 'package:localy_user/page/main/events/event_page.dart';
import 'package:localy_user/page/main/events/event_type_page.dart';
import 'package:localy_user/page/main/events/events_organizer_page.dart';
import 'package:localy_user/page/main/events/events_search_results_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/speech_to_text.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class EventsHomePage extends StatefulWidget {
  const EventsHomePage({super.key});

  @override
  State<EventsHomePage> createState() => _EventsHomePageState();
}

class _EventsHomePageState extends State<EventsHomePage> {
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  Map<String, dynamic> nearEvents = {};
  Map<String, dynamic> todayEvents = {};
  Map<String, dynamic> sportsEvents = {};
  Map<String, dynamic> musicEvents = {};
  Map<String, dynamic> exhibitionEvents = {};
  Map<String, dynamic> organizers = {};
  bool isMicPressed = false;
  bool isSearchPressed = false;
  bool isData = false;
  bool isNoEvents = false;

  // INIT STATE
  @override
  void initState() {
    getNearEvents();
    getTodayEvents();
    getOrganizers();
    getSportsEvents();
    getMusicEvents();
    getExhibitionEvents();
    super.initState();
  }

  // GET NEAR EVENTS
  Future<void> getNearEvents() async {
    Map<String, dynamic> myNearEvents = {};

    final eventSnap = await store.collection('Events').get();

    if (eventSnap.docs.isEmpty) {
      setState(() {
        isNoEvents = true;
      });
      return;
    }

    for (var event in eventSnap.docs) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];
      final views = eventData['eventViewsTimestamp'];

      myNearEvents[id] = [name, imageUrl, views];
    }
    myNearEvents = Map.fromEntries(myNearEvents.entries.toList()
      ..sort((e2, e1) => e1.value[2].length.compareTo(e2.value[2].length)));

    setState(() {
      nearEvents = myNearEvents;
    });
  }

  // GET TODAY EVENTS
  Future<void> getTodayEvents() async {
    Map<String, dynamic> myTodayEvents = {};

    final eventSnap = await store.collection('Events').get();

    if (eventSnap.docs.isEmpty) {
      return;
    }

    for (var event in eventSnap.docs) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];
      final views = eventData['eventViewsTimestamp'];

      final Timestamp startDate = eventData['startDate'];
      final Timestamp endDate = eventData['endDate'];

      if (DateTime.now().isBefore(endDate.toDate()) &&
          DateTime.now().isAfter(startDate.toDate())) {
        myTodayEvents[id] = [name, imageUrl, views];
      }
      myTodayEvents = Map.fromEntries(myTodayEvents.entries.toList()
        ..sort((e2, e1) => e1.value[2].length.compareTo(e2.value[2].length)));

      setState(() {
        todayEvents = myTodayEvents;
      });
    }
  }

  // GET ORGANIZERS
  Future<void> getOrganizers() async {
    Map<String, dynamic> myOrganizers = {};
    final organizerSnap = await store.collection('Organizers').get();

    if (organizerSnap.docs.isEmpty) {
      setState(() {
        isNoEvents = true;
      });
      return;
    }

    for (var organizer in organizerSnap.docs) {
      final organizerData = organizer.data();

      final id = organizer.id;
      final name = organizerData['Name'];
      final imageUrl = organizerData['Image'];
      final views = organizerData['ViewsTimestamp'];

      myOrganizers[id] = [name, imageUrl, views];
    }
    myOrganizers = Map.fromEntries(myOrganizers.entries.toList()
      ..sort((e2, e1) => e1.value[2].length.compareTo(e2.value[2].length)));

    setState(() {
      organizers = myOrganizers;
    });
  }

  // GET SPORTS EVENTS
  Future<void> getSportsEvents() async {
    Map<String, dynamic> mySportsEvents = {};

    final eventSnap = await store.collection('Events').get();

    if (eventSnap.docs.isEmpty) {
      return;
    }

    for (var event in eventSnap.docs) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];
      final views = eventData['eventViewsTimestamp'];

      final String type = eventData['eventType'];

      if (type == 'Sports Tournaments' ||
          type == 'Marathons' ||
          type == 'Fitness Classes' ||
          type == 'Yoga Retreats' ||
          type == 'Cycling Events' ||
          type == 'Fitness Competitions') {
        mySportsEvents[id] = [name, imageUrl, views];
      }
    }
    mySportsEvents = Map.fromEntries(mySportsEvents.entries.toList()
      ..sort((e2, e1) => e1.value[2].length.compareTo(e2.value[2].length)));

    setState(() {
      sportsEvents = mySportsEvents;
    });
  }

  // GET MUSIC EVENTS
  Future<void> getMusicEvents() async {
    Map<String, dynamic> myMusicEvents = {};

    final eventSnap = await store.collection('Events').get();

    if (eventSnap.docs.isEmpty) {
      return;
    }

    for (var event in eventSnap.docs) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];
      final views = eventData['eventViewsTimestamp'];

      final String type = eventData['eventType'];

      if (type == 'Music and Dance Performances') {
        myMusicEvents[id] = [name, imageUrl, views];
      }
      myMusicEvents = Map.fromEntries(myMusicEvents.entries.toList()
        ..sort((e2, e1) => e1.value[2].length.compareTo(e2.value[2].length)));

      setState(() {
        musicEvents = myMusicEvents;
      });
    }
  }

  // GET EXHIBITION EVENTS
  Future<void> getExhibitionEvents() async {
    Map<String, dynamic> myExhibitionEvents = {};

    final eventSnap = await store.collection('Events').get();

    if (eventSnap.docs.isEmpty) {
      return;
    }

    for (var event in eventSnap.docs) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];
      final views = eventData['eventViewsTimestamp'];

      final String type = eventData['eventType'];

      if (type == 'Trade Shows/Exhibitions' || type == 'Art Exhibitions') {
        myExhibitionEvents[id] = [name, imageUrl, views];
      }
      myExhibitionEvents = Map.fromEntries(myExhibitionEvents.entries.toList()
        ..sort((e2, e1) => e1.value[2].length.compareTo(e2.value[2].length)));

      setState(() {
        exhibitionEvents = myExhibitionEvents;
        isData = true;
      });
    }
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) =>
                EventsSearchResultsPage(search: searchController.text)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
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
      body: isNoEvents
          ? const Center(
              child: Text('No Events Nearby'),
            )
          : !isData
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.006125,
                    ),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SEARCH BAR
                            Center(
                              child: Container(
                                color: primary2.withOpacity(0.5),
                                padding: EdgeInsets.symmetric(
                                  vertical: width * 0.0125,
                                ),
                                margin: EdgeInsets.only(
                                  bottom: width * 0.0125,
                                ),
                                child: Container(
                                  width: width * 0.985,
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
                                        width: width * 0.7275,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: TextField(
                                          minLines: 1,
                                          maxLines: 1,
                                          controller: searchController,
                                          onTapOutside: (event) =>
                                              FocusScope.of(context).unfocus(),
                                          keyboardType: TextInputType.text,
                                          textInputAction:
                                              TextInputAction.search,
                                          onSubmitted: (value) async {
                                            await search();
                                          },
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
                            ),

                            // EVENT CATEGORIES
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: width,
                                    height: width * 0.3,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: 4,
                                      itemBuilder: ((context, index) {
                                        final String name = eventCategories.keys
                                            .toList()[index];
                                        final String imageUrl = eventCategories
                                            .values
                                            .toList()[index];

                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: width * 0.025,
                                            vertical: width * 0.015,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: ((context) =>
                                                      EventTypePage(
                                                        eventType: name,
                                                      )),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: width * 0.2,
                                              height: width * 0.25,
                                              decoration: BoxDecoration(
                                                color: white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: width * 0.0125,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        12,
                                                      ),
                                                      child: Image.network(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        height: width * 0.175,
                                                      ),
                                                    ),
                                                    Text(
                                                      name,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: width * 0.725,
                                        height: width * 0.3,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: 3,
                                          itemBuilder: ((context, index) {
                                            final String name = eventCategories
                                                .keys
                                                .toList()[index + 4];
                                            final String imageUrl =
                                                eventCategories.values
                                                    .toList()[index + 4];

                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.025,
                                                vertical: width * 0.015,
                                              ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: ((context) =>
                                                          EventTypePage(
                                                            eventType: name,
                                                          )),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  width: width * 0.2,
                                                  height: width * 0.25,
                                                  decoration: BoxDecoration(
                                                    color: white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          width * 0.0125,
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          child: Image.network(
                                                            imageUrl,
                                                            height:
                                                                width * 0.175,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        Text(
                                                          name,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),

                                      // SEE ALL
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) =>
                                                  const AllEventsTypePage()),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: width * 0.225,
                                          height: width * 0.25,
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.125),
                                            border: Border.all(
                                              width: 0.125,
                                              color: primaryDark,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                FeatherIcons.grid,
                                                color: primaryDark,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'See All',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            nearEvents.isEmpty ? Container() : const Divider(),

                            // NEAR YOU
                            nearEvents.isEmpty
                                ? Container()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.0225),
                                    child: Text(
                                      'Near You',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: width * 0.06,
                                      ),
                                    ),
                                  ),

                            // NEAR YOU EVENTS
                            nearEvents.isEmpty
                                ? Container()
                                : SizedBox(
                                    width: width,
                                    height: width * 0.45,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: nearEvents.length,
                                      itemBuilder: ((context, index) {
                                        final id =
                                            nearEvents.keys.toList()[index];
                                        final name = nearEvents.values
                                            .toList()[index][0];
                                        final imageUrl = nearEvents.values
                                            .toList()[index][1];

                                        return GestureDetector(
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
                                          child: Container(
                                            width: width * 0.325,
                                            height: width * 0.225,
                                            decoration: BoxDecoration(
                                              color: white,
                                              border: Border.all(
                                                width: 0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                            padding: EdgeInsets.all(
                                              width * 0.00625,
                                            ),
                                            margin: EdgeInsets.all(
                                              width * 0.0125,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    width: width * 0.325,
                                                    height: width * 0.325,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: width * 0.00625,
                                                    left: width * 0.0125,
                                                  ),
                                                  child: Text(
                                                    name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: width * 0.05,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),

                            todayEvents.isEmpty ? Container() : const Divider(),

                            // TODAY
                            todayEvents.isEmpty
                                ? Container()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.0225),
                                    child: Text(
                                      'Today',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: width * 0.06,
                                      ),
                                    ),
                                  ),

                            // TODAY EVENTS
                            todayEvents.isEmpty
                                ? Container()
                                : SizedBox(
                                    width: width,
                                    height: width * 0.45,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: todayEvents.length,
                                      itemBuilder: ((context, index) {
                                        final id =
                                            todayEvents.keys.toList()[index];
                                        final name = todayEvents.values
                                            .toList()[index][0];
                                        final imageUrl = todayEvents.values
                                            .toList()[index][1];

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    EventPage(eventId: id)),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: width * 0.325,
                                            height: width * 0.225,
                                            decoration: BoxDecoration(
                                              color: white,
                                              border: Border.all(
                                                width: 0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                            padding: EdgeInsets.all(
                                              width * 0.00625,
                                            ),
                                            margin: EdgeInsets.all(
                                              width * 0.0125,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    width: width * 0.325,
                                                    height: width * 0.325,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: width * 0.00625,
                                                    left: width * 0.0125,
                                                  ),
                                                  child: Text(
                                                    name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: width * 0.05,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),

                            organizers.isEmpty ? Container() : const Divider(),

                            // ORGANIZER
                            organizers.isEmpty
                                ? Container()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.0225),
                                    child: Text(
                                      'Organizers',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: width * 0.06,
                                      ),
                                    ),
                                  ),

                            // ORGANIZERS
                            organizers.isEmpty
                                ? Container()
                                : SizedBox(
                                    width: width,
                                    height: width * 0.45,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: organizers.length,
                                      itemBuilder: ((context, index) {
                                        final id =
                                            organizers.keys.toList()[index];
                                        final name = organizers.values
                                            .toList()[index][0];
                                        final imageUrl = organizers.values
                                            .toList()[index][1];

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    EventsOrganizerPage(
                                                      organizerId: id,
                                                    )),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: width * 0.325,
                                            height: width * 0.225,
                                            decoration: BoxDecoration(
                                              color: white,
                                              border: Border.all(
                                                width: 0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                            padding: EdgeInsets.all(
                                              width * 0.00625,
                                            ),
                                            margin: EdgeInsets.all(
                                              width * 0.0125,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    width: width * 0.325,
                                                    height: width * 0.325,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: width * 0.00625,
                                                    left: width * 0.0125,
                                                  ),
                                                  child: Text(
                                                    name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: width * 0.05,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),

                            sportsEvents.isEmpty
                                ? Container()
                                : const Divider(),

                            // SPORTS
                            sportsEvents.isEmpty
                                ? Container()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.0225),
                                    child: Text(
                                      'Sports',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: width * 0.06,
                                      ),
                                    ),
                                  ),

                            // SPORTS EVENTS
                            sportsEvents.isEmpty
                                ? Container()
                                : SizedBox(
                                    width: width,
                                    height: width * 0.45,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: sportsEvents.length,
                                      itemBuilder: ((context, index) {
                                        final id =
                                            sportsEvents.keys.toList()[index];
                                        final name = sportsEvents.values
                                            .toList()[index][0];
                                        final imageUrl = sportsEvents.values
                                            .toList()[index][1];

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    EventPage(eventId: id)),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: width * 0.325,
                                            height: width * 0.225,
                                            decoration: BoxDecoration(
                                              color: white,
                                              border: Border.all(
                                                width: 0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                            padding: EdgeInsets.all(
                                              width * 0.00625,
                                            ),
                                            margin: EdgeInsets.all(
                                              width * 0.0125,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    width: width * 0.325,
                                                    height: width * 0.325,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: width * 0.00625,
                                                    left: width * 0.0125,
                                                  ),
                                                  child: Text(
                                                    name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: width * 0.05,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),

                            musicEvents.isEmpty ? Container() : const Divider(),

                            // MUSIC
                            musicEvents.isEmpty
                                ? Container()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.0225),
                                    child: Text(
                                      'Music',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: width * 0.06,
                                      ),
                                    ),
                                  ),

                            // MUSIC EVENTS
                            musicEvents.isEmpty
                                ? Container()
                                : SizedBox(
                                    width: width,
                                    height: width * 0.45,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: musicEvents.length,
                                      itemBuilder: ((context, index) {
                                        final id =
                                            musicEvents.keys.toList()[index];
                                        final name = musicEvents.values
                                            .toList()[index][0];
                                        final imageUrl = musicEvents.values
                                            .toList()[index][1];

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    EventPage(eventId: id)),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: width * 0.325,
                                            height: width * 0.225,
                                            decoration: BoxDecoration(
                                              color: white,
                                              border: Border.all(
                                                width: 0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                            padding: EdgeInsets.all(
                                              width * 0.00625,
                                            ),
                                            margin: EdgeInsets.all(
                                              width * 0.0125,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    width: width * 0.325,
                                                    height: width * 0.325,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: width * 0.00625,
                                                    left: width * 0.0125,
                                                  ),
                                                  child: Text(
                                                    name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: width * 0.05,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),

                            exhibitionEvents.isEmpty
                                ? Container()
                                : const Divider(),

                            // EXHIBITION
                            exhibitionEvents.isEmpty
                                ? Container()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.0225),
                                    child: Text(
                                      'Exhibition',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: width * 0.06,
                                      ),
                                    ),
                                  ),

                            // EXHIBITION EVENTS
                            exhibitionEvents.isEmpty
                                ? Container()
                                : SizedBox(
                                    width: width,
                                    height: width * 0.45,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: exhibitionEvents.length,
                                      itemBuilder: ((context, index) {
                                        final id = exhibitionEvents.keys
                                            .toList()[index];
                                        final name = exhibitionEvents.values
                                            .toList()[index][0];
                                        final imageUrl = exhibitionEvents.values
                                            .toList()[index][1];

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: ((context) =>
                                                    EventPage(eventId: id)),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: width * 0.325,
                                            height: width * 0.225,
                                            decoration: BoxDecoration(
                                              color: white,
                                              border: Border.all(
                                                width: 0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                            padding: EdgeInsets.all(
                                              width * 0.00625,
                                            ),
                                            margin: EdgeInsets.all(
                                              width * 0.0125,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    width: width * 0.325,
                                                    height: width * 0.325,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: width * 0.00625,
                                                    left: width * 0.0125,
                                                  ),
                                                  child: Text(
                                                    name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: width * 0.05,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
    );
  }
}
