import 'package:localsearch_user/utils/colors.dart';
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
  final width;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: width * 0.0133,
        horizontal: width * 0.02,
      ),
      child: Container(
        width: width,
        padding: EdgeInsets.all(
          width * 0.0125,
        ),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              head,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: primaryDark2,
              ),
            ),
            SizedBox(
              width: width,
              height: 50,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: 1,
                itemBuilder: (context, index) {
                  return Row(
                    children: propertyValue
                        .map(
                          (e) => Container(
                            height: width * 0.1250,
                            margin: EdgeInsets.only(
                              right: width * 0.0125,
                              top: width * 0.0125,
                              bottom: width * 0.0125,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: width * 0.0125,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: primaryDark.withOpacity(0.175),
                              borderRadius: BorderRadius.circular(
                                width * 0.0125,
                              ),
                            ),
                            child: Text(
                              e,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: width * 0.05,
                                color: primaryDark2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
