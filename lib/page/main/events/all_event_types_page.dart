import 'package:Localsearch_User/models/events_categories.dart';
import 'package:Localsearch_User/page/main/events/event_type_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class AllEventsTypePage extends StatefulWidget {
  const AllEventsTypePage({super.key});

  @override
  State<AllEventsTypePage> createState() => _AllEventsTypePageState();
}

class _AllEventsTypePageState extends State<AllEventsTypePage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Event Types'),
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
            width * 0.006125,
          ),
          child: SizedBox(
            width: width,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: eventCategories.length,
              itemBuilder: ((context, index) {
                final name = eventCategories.keys.toList()[index];
                final imageUrl = eventCategories.values.toList()[index];

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.025,
                    vertical: width * 0.015,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: ((context) => EventTypePage(
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.0125,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: width * 0.2,
                                height: width * 0.2,
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
