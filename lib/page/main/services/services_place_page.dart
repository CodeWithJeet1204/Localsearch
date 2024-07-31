import 'package:Localsearch_User/models/services_image_map.dart';
import 'package:Localsearch_User/models/services_map.dart';
import 'package:Localsearch_User/page/main/services/services_category_page.dart';
import 'package:Localsearch_User/widgets/name_container.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class ServicesPlacePage extends StatefulWidget {
  const ServicesPlacePage({
    super.key,
    required this.place,
  });

  final String place;

  @override
  State<ServicesPlacePage> createState() => _ServicesPlacePageState();
}

class _ServicesPlacePageState extends State<ServicesPlacePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place),
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
      body: Padding(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.006125,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 25 / 9,
            ),
            itemCount: servicesMap[widget.place]!.length,
            itemBuilder: ((context, index) {
              final name = servicesMap[widget.place]!.keys.toList()[index];
              final imageUrl = categoryImageMap[name]!;

              return NameContainer(
                text: name,
                imageUrl: imageUrl,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: ((context) => ServicesCategoryPage(
                            place: widget.place,
                            category: name,
                          )),
                    ),
                  );
                },
                width: MediaQuery.of(context).size.width,
              );
            }),
          ),
        ),
      ),
    );
  }
}
