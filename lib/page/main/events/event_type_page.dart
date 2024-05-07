import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/page/main/events/event_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:flutter/material.dart';

class EventTypePage extends StatefulWidget {
  const EventTypePage({
    super.key,
    required this.eventType,
  });

  final String eventType;

  @override
  State<EventTypePage> createState() => _EventTypePageState();
}

class _EventTypePageState extends State<EventTypePage> {
  final store = FirebaseFirestore.instance;
  Map<String, Map<String, dynamic>> events = {};
  bool isData = false;

  // INIT STATE
  @override
  void initState() {
    getData();
    super.initState();
  }

  // GET DATA
  Future<void> getData() async {
    Map<String, Map<String, dynamic>> myEvents = {};

    final eventSnap = await store
        .collection('Event')
        .where('eventType', isEqualTo: widget.eventType)
        .get();

    eventSnap.docs.forEach((event) {
      myEvents[event.id] = event.data();
    });

    setState(() {
      events = myEvents;
      isData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventType),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            width * 0.006125,
          ),
          child: SizedBox(
            width: width,
            child: GridView.builder(
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: width * 0.633 / width,
              ),
              itemCount: events.length,
              itemBuilder: ((context, index) {
                final id = events.keys.toList()[index];
                final name = events.values.toList()[index]['eventName'];
                final imageUrl = events.values.toList()[index]['imageUrl'][0];

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
                      width * 0.006125,
                    ),
                    margin: EdgeInsets.all(
                      width * 0.006125,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: width * 0.5,
                            height: width * 0.58,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: width * 0.00625,
                            left: width * 0.0125,
                          ),
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}
