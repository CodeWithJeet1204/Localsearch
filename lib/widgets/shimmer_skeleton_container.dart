import 'package:localsearch/widgets/skeleton_container.dart';
import 'package:flutter/material.dart';

class GridViewSkeleton extends StatelessWidget {
  const GridViewSkeleton({
    super.key,
    required this.width,
    required this.isPrice,
    this.isDelete = false,
    this.isDiscount = false,
  });

  final double width;
  final bool isPrice;
  final bool isDelete;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(width * 0.01),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            // IMAGE
            Padding(
              padding: EdgeInsets.fromLTRB(
                width * 0.015,
                width * 0.01,
                width * 0.01,
                0,
              ),
              child: SkeletonContainer(
                width: isDiscount ? width : width * 0.4,
                height: width * 0.4,
              ),
            ),
            // NAME, PRICE & DELETE
            isDelete
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            // NAME
                            padding: EdgeInsets.fromLTRB(
                              width * 0.025,
                              width * 0.05,
                              width * 0.02,
                              0,
                            ),
                            child: SkeletonContainer(
                              width: width * 0.2,
                              height: width * 0.04,
                            ),
                          ),
                          // PRICE
                          isPrice
                              ? Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    width * 0.025,
                                    width * 0.025,
                                    width * 0.01,
                                    0,
                                  ),
                                  child: SkeletonContainer(
                                    width:
                                        isDiscount ? width * 0.6 : width * 0.1,
                                    height: width * 0.025,
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                      // DELETE
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          width * 0.05,
                          width * 0.02,
                          width * 0.025,
                          0,
                        ),
                        child: SkeletonContainer(
                          width: width * 0.1,
                          height: width * 0.1,
                        ),
                      ),
                    ],
                  )
                // NAME & PRICE
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NAME
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          width * 0.025,
                          width * 0.05,
                          width * 0.02,
                          0,
                        ),
                        child: SkeletonContainer(
                          width: width * 0.3,
                          height: width * 0.04,
                        ),
                      ),
                      // PRICE
                      isPrice
                          ? Padding(
                              padding: EdgeInsets.fromLTRB(
                                width * 0.025,
                                width * 0.025,
                                width * 0.01,
                                0,
                              ),
                              child: SkeletonContainer(
                                width: isDiscount ? width * 0.6 : width * 0.1,
                                height: width * 0.025,
                              ),
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

class ListViewSkeleton extends StatelessWidget {
  const ListViewSkeleton({
    super.key,
    required this.width,
    required this.height,
    required this.isPrice,
    this.isDelete = false,
    this.isDiscount = false,
  });

  final double width;
  final double height;
  final bool isPrice;
  final bool isDelete;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(width * 0.01),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                // IMAGE
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    width * 0.015,
                    width * 0.0125,
                    width * 0.01,
                    width * 0.0125,
                  ),
                  child: SkeletonContainer(
                    width: width * 0.166,
                    height: width * 0.15,
                  ),
                ),
                isPrice
                    // NAME & PRICE
                    ? Column(
                        mainAxisAlignment: isPrice
                            ? MainAxisAlignment.spaceBetween
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              width * 0.025,
                              width * 0.025,
                              width * 0.02,
                              0,
                            ),
                            child: SkeletonContainer(
                              width: width * 0.3,
                              height: width * 0.04,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              width * 0.025,
                              width * 0.05,
                              width * 0.01,
                              0,
                            ),
                            child: SkeletonContainer(
                              width: isDiscount ? width * 0.4 : width * 0.1,
                              height: width * 0.025,
                            ),
                          )
                        ],
                      )
                    // NAME
                    : Padding(
                        padding: EdgeInsets.fromLTRB(
                          width * 0.025,
                          width * 0,
                          width * 0.02,
                          0,
                        ),
                        child: SkeletonContainer(
                          width: width * 0.3,
                          height: width * 0.04,
                        ),
                      ),
              ],
            ),
            // DELETE
            isDelete
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      width * 0.05,
                      width * 0.01,
                      width * 0.025,
                      0,
                    ),
                    child: SkeletonContainer(
                      width: width * 0.1,
                      height: width * 0.1,
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
