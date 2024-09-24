import 'package:localsearch/page/main/vendor/vendor_shorts_tab_tile.dart';
import 'package:flutter/material.dart';

class VendorShortsTabPageView extends StatefulWidget {
  const VendorShortsTabPageView({
    super.key,
    required this.shorts,
    required this.shortsId,
    required this.index,
  });

  final Map<String, dynamic> shorts;
  final int index;
  final String shortsId;

  @override
  State<VendorShortsTabPageView> createState() =>
      _VendorShortsTabPageViewState();
}

class _VendorShortsTabPageViewState extends State<VendorShortsTabPageView> {
  late int snappedPageIndex;

  // INIT STATE
  @override
  void initState() {
    setState(() {
      snappedPageIndex = widget.index;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: PageController(
        initialPage: snappedPageIndex,
        viewportFraction: 1,
      ),
      scrollDirection: Axis.vertical,
      onPageChanged: (pageIndex) {
        setState(() {
          snappedPageIndex = pageIndex;
        });
      },
      itemCount: widget.shorts.length,
      itemBuilder: ((context, index) {
        final currentShortsId = widget.shorts.keys.toList()[index];
        final Map<String, dynamic> currentShortsData =
            widget.shorts.values.toList()[index];
        currentShortsData.addAll({
          'shortsId': currentShortsId,
        });

        return VendorShortsTabTile(
          data: currentShortsData,
        );
      }),
    );
  }
}
