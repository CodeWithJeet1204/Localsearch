import 'package:find_easy_user/models/services_image_map.dart';
import 'package:find_easy_user/models/services_map.dart';
import 'package:find_easy_user/page/main/services/services_category_page.dart';
import 'package:find_easy_user/widgets/name_container.dart';
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
      ),
      body: Padding(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.006125,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: GridView.builder(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 16 / 9,
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
