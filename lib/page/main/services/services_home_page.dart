import 'package:feather_icons/feather_icons.dart';
import 'package:localsearch_user/models/services_image_map.dart';
import 'package:localsearch_user/page/main/services/services_place_page.dart';
import 'package:localsearch_user/page/main/services/services_search_page.dart';
import 'package:localsearch_user/utils/colors.dart';
import 'package:localsearch_user/widgets/name_container.dart';
import 'package:localsearch_user/widgets/speech_to_text.dart';
import 'package:localsearch_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ServicesHomePage extends StatefulWidget {
  const ServicesHomePage({super.key});

  @override
  State<ServicesHomePage> createState() => _ServicesHomePageState();
}

class _ServicesHomePageState extends State<ServicesHomePage> {
  final searchController = TextEditingController();
  bool isMicPressed = false;
  bool isSearchPressed = false;

  // NAVIGATE TO
  void navigateTo(String text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: ((context) => ServicesPlacePage(
              place: text,
            )),
      ),
    );
  }

  // SEARCH
  Future<void> search() async {
    if (searchController.text.isNotEmpty) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) => ServicesSearchPage(
                  search: searchController.text,
                )),
          ),
        );
      }
    }
  }

  // GET SUGGESTIONS
  List<String> getSuggestions(String pattern) {
    final List<String> places = List.from(placeImageMap.keys);
    final List<String> categories = List.from(categoryImageMap.keys);
    final List<String> subCategories = List.from(subCategoryImageMap.keys);
    final List<String> suggestions = [
      ...places,
      ...categories,
      ...subCategories
    ];

    return suggestions
        .where((item) => item.toLowerCase().contains(pattern.toLowerCase()))
        .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            onPressed: () async {
              await showYouTubePlayerDialog(
                context,
                getYoutubeVideoId(
                  'https://youtube.com/shorts/gBJxIC0qkVI?si=Ax5ZaPP5KKpWmahY',
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
            MediaQuery.of(context).size.width * 0.006125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final width = constraints.maxWidth;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: width,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primary2.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryDark.withOpacity(0.25),
                        ),
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: width * 0.0225,
                        vertical: width * 0.0125,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TypeAheadField(
                              controller: searchController,
                              onSelected: (value) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: ((context) => ServicesSearchPage(
                                          search: value,
                                        )),
                                  ),
                                );
                              },
                              suggestionsCallback: (pattern) {
                                return getSuggestions(pattern);
                              },
                              builder: (context, controller, focusNode) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  textInputAction: TextInputAction.search,
                                  onTapOutside: (event) =>
                                      FocusScope.of(context).unfocus(),
                                  onSubmitted: (value) async {
                                    await search();
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(7),
                                        bottomLeft: Radius.circular(7),
                                      ),
                                      borderSide: BorderSide(
                                        width: 1,
                                        color: Colors.cyan.shade700,
                                      ),
                                    ),
                                    hintText: 'Search...',
                                  ),
                                );
                              },
                              itemBuilder: (context, value) {
                                return ListTile(
                                  title: Text(value.toString()),
                                );
                              },
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
                            splashColor: Colors.transparent,
                            customBorder: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(0),
                                bottomLeft: Radius.circular(0),
                                bottomRight: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            child: Container(
                              width: width * 0.175,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSearchPressed
                                    ? primary2.withOpacity(0.95)
                                    : primary2.withOpacity(0.25),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(0),
                                  bottomLeft: Radius.circular(0),
                                  bottomRight: Radius.circular(6),
                                  topRight: Radius.circular(6),
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
                    ),
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
      ),
    );
  }
}
