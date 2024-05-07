import 'package:find_easy_user/models/services_image_map.dart';
import 'package:find_easy_user/models/services_map.dart';
import 'package:find_easy_user/page/main/services/services_sub_category_page.dart';
import 'package:find_easy_user/widgets/name_container.dart';
import 'package:flutter/material.dart';

class ServicesCategoryPage extends StatefulWidget {
  const ServicesCategoryPage({
    super.key,
    required this.place,
    required this.category,
  });

  final String place;
  final String category;

  @override
  State<ServicesCategoryPage> createState() => _ServicesCategoryPageState();
}

class _ServicesCategoryPageState extends State<ServicesCategoryPage> {
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
              crossAxisCount: 1,
              childAspectRatio: 25 / 9,
            ),
            itemCount: servicesMap[widget.place]![widget.category]!.length,
            itemBuilder: ((context, index) {
              final name = servicesMap[widget.place]![widget.category]![index];
              final imageUrl = subCategoryImageMap[name]!;

              return NameContainer(
                text: name,
                imageUrl: imageUrl,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: ((context) => ServicesSubCategoryPage(
                            subCategory: name,
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
