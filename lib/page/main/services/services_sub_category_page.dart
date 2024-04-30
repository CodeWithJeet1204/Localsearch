import 'package:find_easy_user/models/services_image_map.dart';
import 'package:find_easy_user/models/services_map.dart';
import 'package:find_easy_user/widgets/name_container.dart';
import 'package:flutter/material.dart';

class ServicesSubCategoryPage extends StatefulWidget {
  const ServicesSubCategoryPage({
    super.key,
    required this.place,
    required this.category,
  });

  final String place;
  final String category;

  @override
  State<ServicesSubCategoryPage> createState() =>
      _ServicesSubCategoryPageState();
}

class _ServicesSubCategoryPageState extends State<ServicesSubCategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
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
            itemCount: servicesMap[widget.place]![widget.category]!.length,
            itemBuilder: ((context, index) {
              final name = servicesMap[widget.place]![widget.category]![index];
              final imageUrl = subCategoryImageMap[name]!;

              return NameContainer(
                text: name,
                imageUrl: imageUrl,
                onTap: () {},
                width: MediaQuery.of(context).size.width,
              );
            }),
          ),
        ),
      ),
    );
  }
}
