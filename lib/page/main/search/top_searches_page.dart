import 'package:feather_icons/feather_icons.dart';
import 'package:localy_user/page/main/search/search_results_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class TopSearchPage extends StatefulWidget {
  const TopSearchPage({
    super.key,
    required this.data,
  });

  final Map data;

  @override
  State<TopSearchPage> createState() => _TopSearchPageState();
}

class _TopSearchPageState extends State<TopSearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Searches 🔥'),
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
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.0225,
            vertical: MediaQuery.of(context).size.width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final double width = constraints.maxWidth;

              return SizedBox(
                width: width,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.data.keys.toList().length,
                  physics: ClampingScrollPhysics(),
                  itemBuilder: ((context, index) {
                    final String name = widget.data.keys.toList()[index];
                    final int number = widget.data.values.toList()[index];

                    return Container(
                      decoration: BoxDecoration(
                        color: primary2.withOpacity(0.125),
                        border: Border.all(
                          width: 0.5,
                          color: primaryDark.withOpacity(0.25),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.only(
                        left: width * 0.04,
                        right: width * 0.05,
                        top: width * 0.03,
                        bottom: width * 0.03,
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: width * 0.0125,
                        vertical: width * 0.0125,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${(index + 1).toString()}.   ',
                                style: TextStyle(
                                  fontSize: width * 0.055,
                                ),
                              ),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: width * 0.06,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  right: width * 0.0225,
                                ),
                                child: Text(
                                  number.toString(),
                                  style: TextStyle(
                                    fontSize: width * 0.055,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: ((context) => SearchResultsPage(
                                            search: name,
                                          )),
                                    ),
                                  );
                                },
                                icon: const Icon(FeatherIcons.search),
                                tooltip: 'Search \'$name\'',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
