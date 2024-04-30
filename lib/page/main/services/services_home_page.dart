import 'package:find_easy_user/models/services_image_map.dart';
import 'package:find_easy_user/page/main/services/services_category_page.dart';
import 'package:find_easy_user/widgets/name_container.dart';
import 'package:flutter/material.dart';

class ServicesHomePage extends StatefulWidget {
  const ServicesHomePage({super.key});

  @override
  State<ServicesHomePage> createState() => _ServicesHomePageState();
}

class _ServicesHomePageState extends State<ServicesHomePage> {
  // NAVIGATE TO
  void navigateTo(String text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: ((context) => ServicesCategoryPage(
              place: text,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services'),
      ),
      body: Padding(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      NameContainer(
                        text: 'Home',
                        imageUrl: placeImageMap['Home']!,
                        onTap: () {
                          navigateTo('Home');
                        },
                        width: width,
                      ),
                      NameContainer(
                        text: 'Office',
                        imageUrl: placeImageMap['Office']!,
                        onTap: () {
                          navigateTo('Office');
                        },
                        width: width,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      NameContainer(
                        text: 'Outdoor',
                        imageUrl: placeImageMap['Outdoor']!,
                        onTap: () {
                          navigateTo('Outdoor');
                        },
                        width: width,
                      ),
                      NameContainer(
                        text: 'Retail Stores',
                        imageUrl: placeImageMap['Retail Stores']!,
                        onTap: () {
                          navigateTo('Retail Stores');
                        },
                        width: width,
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: width * 0.0065),
                    child: NameContainer(
                      text: 'Educational Institutes',
                      imageUrl: placeImageMap['Educational Institutes']!,
                      onTap: () {
                        navigateTo('Educational Institutes');
                      },
                      width: width,
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
