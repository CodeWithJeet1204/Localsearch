import 'package:find_easy_user/utils/colors.dart';
import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.head,
    required this.noOfAnswers,
    required this.content,
    required this.propertyValue,
    required this.width,
    this.maxLines = 1,
  });

  final String head;
  final dynamic content;
  final List<dynamic> propertyValue;
  final int noOfAnswers;
  final double width;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.width * 0.0175,
        horizontal: MediaQuery.of(context).size.width * 0.02,
      ),
      child: Container(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.0125,
        ),
        decoration: BoxDecoration(
          color: primary2.withOpacity(0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overflow: TextOverflow.ellipsis,
                  head,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: primaryDark2,
                  ),
                  maxLines: maxLines,
                ),
                noOfAnswers == 1
                    ? Text(
                        content ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.05833,
                          fontWeight: FontWeight.w600,
                          color: primaryDark,
                        ),
                      )
                    : noOfAnswers == 2
                        ? Text(
                            content ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.05833,
                              fontWeight: FontWeight.w600,
                              color: primaryDark,
                            ),
                          )
                        : noOfAnswers == 3
                            ? propertyValue.isNotEmpty
                                ? SizedBox(
                                    width: width * 0.725,
                                    height: 50,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemCount: 1,
                                      itemBuilder: (context, index) {
                                        return Row(
                                          children: propertyValue
                                              .map(
                                                (e) => Container(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.1250,
                                                  margin: EdgeInsets.only(
                                                    right:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.0125,
                                                    top: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.0125,
                                                    bottom:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.0125,
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.0125,
                                                  ),
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: primary2
                                                        .withOpacity(0.8),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.0125,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    e.toString(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.05,
                                                      color: primaryDark2,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        );
                                      },
                                    ),
                                  )
                                : const Text(
                                    "N/A",
                                    overflow: TextOverflow.ellipsis,
                                  )
                            : Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
