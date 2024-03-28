import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/utils/colors.dart';
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
        title: Text('Top Searches 🔥'),
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
                  itemBuilder: ((context, index) {
                    final String name = widget.data.keys.toList()[index];
                    final int number = widget.data.values.toList()[index];

                    return Container(
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
                      decoration: BoxDecoration(
                        color: primary2.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(12),
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
                                onPressed: () {},
                                icon: Icon(FeatherIcons.search),
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
