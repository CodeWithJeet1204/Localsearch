import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/models/events_categories.dart';
import 'package:find_easy_user/page/main/events/event_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:flutter/material.dart';

class EventsHomePage extends StatefulWidget {
  const EventsHomePage({super.key});

  @override
  State<EventsHomePage> createState() => _EventsHomePageState();
}

class _EventsHomePageState extends State<EventsHomePage> {
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> nearEvents = {};
  Map<String, dynamic> todayEvents = {};
  Map<String, dynamic> sportsEvents = {};
  Map<String, dynamic> musicEvents = {};
  Map<String, dynamic> exhibitionEvents = {};
  bool isNearEvents = false;
  bool isTodayEvents = false;
  bool isSportsEvents = false;
  bool isMusicEvents = false;
  bool isExhibitionEvents = false;

  // INIT STATE
  @override
  void initState() {
    getNearEvents();
    getTodayEvents();
    getSportsEvents();
    getMusicEvents();
    getExhibitionEvents();
    super.initState();
  }

  // GET NEAR EVENTS
  Future<void> getNearEvents() async {
    Map<String, dynamic> myNearEvents = {};

    final eventSnap = await store.collection('Event').get();

    eventSnap.docs.forEach((event) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];

      myNearEvents[id] = [name, imageUrl];
    });

    setState(() {
      nearEvents = myNearEvents;
      isNearEvents = true;
    });
  }

  // GET TODAY EVENTS
  Future<void> getTodayEvents() async {
    Map<String, dynamic> myTodayEvents = {};

    final eventSnap = await store.collection('Event').get();

    eventSnap.docs.forEach((event) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];

      final Timestamp startDate = eventData['startDate'];
      final Timestamp endDate = eventData['endDate'];

      if (DateTime.now().isBefore(endDate.toDate()) &&
          DateTime.now().isAfter(startDate.toDate())) {
        myTodayEvents[id] = [name, imageUrl];
      }

      setState(() {
        todayEvents = myTodayEvents;
        isTodayEvents = true;
      });
    });
  }

  // GET SPORTS EVENTS
  Future<void> getSportsEvents() async {
    Map<String, dynamic> mySportsEvents = {};

    final eventSnap = await store.collection('Event').get();

    eventSnap.docs.forEach((event) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];

      final String type = eventData['eventType'];

      if (type == 'Sports Tournaments' ||
          type == 'Marathons' ||
          type == 'Fitness Classes' ||
          type == 'Yoga Retreats' ||
          type == 'Cycling Events' ||
          type == 'Fitness Competitions') {
        mySportsEvents[id] = [name, imageUrl];
      }

      setState(() {
        sportsEvents = mySportsEvents;
        isSportsEvents = true;
      });
    });
  }

  // GET MUSIC EVENTS
  Future<void> getMusicEvents() async {
    Map<String, dynamic> myMusicEvents = {};

    final eventSnap = await store.collection('Event').get();

    eventSnap.docs.forEach((event) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];

      final String type = eventData['eventType'];

      if (type == 'Music and Dance Performances') {
        myMusicEvents[id] = [name, imageUrl];
      }

      setState(() {
        musicEvents = myMusicEvents;
        isMusicEvents = true;
      });
    });
  }

  // GET EXHIBITION EVENTS
  Future<void> getExhibitionEvents() async {
    Map<String, dynamic> myExhibitionEvents = {};

    final eventSnap = await store.collection('Event').get();

    eventSnap.docs.forEach((event) {
      final eventData = event.data();

      final id = eventData['eventId'];
      final name = eventData['eventName'];
      final imageUrl = eventData['imageUrl'][0];

      final String type = eventData['eventType'];

      if (type == 'Trade Shows/Exhibitions' || type == 'Art Exhibitions') {
        myExhibitionEvents[id] = [name, imageUrl];
      }

      setState(() {
        exhibitionEvents = myExhibitionEvents;
        isExhibitionEvents = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
      ),
      body: SafeArea(
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
                  // EVENT CATEGORIES
                  SizedBox(
                    width: width,
                    height: 90,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      physics: ClampingScrollPhysics(),
                      itemCount: 8,
                      itemBuilder: ((context, index) {
                        final name = eventCategories.keys.toList()[index];
                        final imageUrl = eventCategories.values.toList()[index];

                        return Container(
                          width: 70,
                          height: 70,
                          margin: EdgeInsets.symmetric(
                            horizontal: width * 0.0125,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: width * 0.033,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  nearEvents.isEmpty ? Container() : Divider(),

                  // NEAR YOU
                  nearEvents.isEmpty
                      ? Container()
                      : Padding(
                          padding: EdgeInsets.only(left: width * 0.0225),
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
                            physics: ClampingScrollPhysics(),
                            itemCount: nearEvents.length,
                            itemBuilder: ((context, index) {
                              final id = nearEvents.keys.toList()[index];
                              final name = nearEvents.values.toList()[index][0];
                              final imageUrl =
                                  nearEvents.values.toList()[index][1];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: ((context) => EventPage(
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
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  padding: EdgeInsets.all(
                                    width * 0.00625,
                                  ),
                                  margin: EdgeInsets.all(
                                    width * 0.0125,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
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
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: width * 0.05,
                                            fontWeight: FontWeight.w500,
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

                  todayEvents.isEmpty ? Container() : Divider(),

                  // TODAY
                  todayEvents.isEmpty
                      ? Container()
                      : Padding(
                          padding: EdgeInsets.only(left: width * 0.0225),
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
                            physics: ClampingScrollPhysics(),
                            itemCount: todayEvents.length,
                            itemBuilder: ((context, index) {
                              final id = todayEvents.keys.toList()[index];
                              final name =
                                  todayEvents.values.toList()[index][0];
                              final imageUrl =
                                  todayEvents.values.toList()[index][1];

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
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  padding: EdgeInsets.all(
                                    width * 0.00625,
                                  ),
                                  margin: EdgeInsets.all(
                                    width * 0.0125,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
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
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: width * 0.05,
                                            fontWeight: FontWeight.w500,
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

                  sportsEvents.isEmpty ? Container() : Divider(),

                  // SPORTS
                  sportsEvents.isEmpty
                      ? Container()
                      : Padding(
                          padding: EdgeInsets.only(left: width * 0.0225),
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
                            physics: ClampingScrollPhysics(),
                            itemCount: sportsEvents.length,
                            itemBuilder: ((context, index) {
                              final id = sportsEvents.keys.toList()[index];
                              final name =
                                  sportsEvents.values.toList()[index][0];
                              final imageUrl =
                                  sportsEvents.values.toList()[index][1];

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
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  padding: EdgeInsets.all(
                                    width * 0.00625,
                                  ),
                                  margin: EdgeInsets.all(
                                    width * 0.0125,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
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
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: width * 0.05,
                                            fontWeight: FontWeight.w500,
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

                  musicEvents.isEmpty ? Container() : Divider(),

                  // MUSIC
                  musicEvents.isEmpty
                      ? Container()
                      : Padding(
                          padding: EdgeInsets.only(left: width * 0.0225),
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
                            physics: ClampingScrollPhysics(),
                            itemCount: musicEvents.length,
                            itemBuilder: ((context, index) {
                              final id = musicEvents.keys.toList()[index];
                              final name =
                                  musicEvents.values.toList()[index][0];
                              final imageUrl =
                                  musicEvents.values.toList()[index][1];

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
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  padding: EdgeInsets.all(
                                    width * 0.00625,
                                  ),
                                  margin: EdgeInsets.all(
                                    width * 0.0125,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
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
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: width * 0.05,
                                            fontWeight: FontWeight.w500,
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

                  exhibitionEvents.isEmpty ? Container() : Divider(),

                  // EXHIBITION
                  exhibitionEvents.isEmpty
                      ? Container()
                      : Padding(
                          padding: EdgeInsets.only(left: width * 0.0225),
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
                            physics: ClampingScrollPhysics(),
                            itemCount: exhibitionEvents.length,
                            itemBuilder: ((context, index) {
                              final id = exhibitionEvents.keys.toList()[index];
                              final name =
                                  exhibitionEvents.values.toList()[index][0];
                              final imageUrl =
                                  exhibitionEvents.values.toList()[index][1];

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
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  padding: EdgeInsets.all(
                                    width * 0.00625,
                                  ),
                                  margin: EdgeInsets.all(
                                    width * 0.0125,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
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
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: width * 0.05,
                                            fontWeight: FontWeight.w500,
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
