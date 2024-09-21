import 'package:localsearch/page/main/vendor/vendor_shorts_tab_tile.dart';
import 'package:flutter/material.dart';

class VendorShortsTabPageView extends StatefulWidget {
  const VendorShortsTabPageView({
    super.key,
    required this.shorts,
    required this.shortsId,
  });

  final Map<String, dynamic> shorts;
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
      snappedPageIndex = widget.shorts.keys.toList().indexOf(widget.shortsId);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: PageController(
        initialPage: 0,
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
        final String currentKey = widget.shorts.keys.toList()[index];
        final List<dynamic> currentValue = widget.shorts.values.toList()[index];
        final Map<String, dynamic> currentShort = {
          currentKey: currentValue,
        };

        return VendorShortsTabTile(
          data: currentShort,
          snappedPageIndex: index,
          currentIndex: snappedPageIndex,
        );
      }),
    );
  }
}
