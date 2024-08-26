import 'package:Localsearch_User/page/main/vendor/vendor_shorts_tab_page_view.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:flutter/material.dart';

class VendorShortsTabPage extends StatefulWidget {
  const VendorShortsTabPage({
    super.key,
    required this.width,
    required this.shorts,
  });

  final double width;
  final Map<String, List> shorts;

  @override
  State<VendorShortsTabPage> createState() => _VendorShortsTabPageState();
}

class _VendorShortsTabPageState extends State<VendorShortsTabPage> {
  // GET SCREEN HEIGHT
  double getScreenHeight() {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final paddingTop = mediaQuery.padding.top;
    final paddingBottom = mediaQuery.padding.bottom;

    final availableHeight = screenHeight - paddingTop - paddingBottom;
    return availableHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: widget.width,
        height: getScreenHeight() * 0.606125,
        child: widget.shorts.isEmpty
            ? const SizedBox(
                height: 80,
                child: Center(
                  child: Text('No Shorts'),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 9 / 15.66,
                ),
                itemCount: widget.shorts.length,
                itemBuilder: (context, index) {
                  final shortsId = widget.shorts.keys.toList()[index][0];
                  // final shortsURL = widget.shorts.values.toList()[index][0];
                  final shortsThumbnail =
                      widget.shorts.values.toList()[index][3];

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => VendorShortsTabPageView(
                            shorts: widget.shorts,
                            shortsId: shortsId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: primaryDark,
                      ),
                      padding: EdgeInsets.all(
                        widget.width * 0.00306125,
                      ),
                      margin: EdgeInsets.all(widget.width * 0.0036125),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            shortsThumbnail,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            width: widget.width * 0.125,
                            height: widget.width * 0.125,
                            decoration: BoxDecoration(
                              color: white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(
                                100,
                              ),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: white,
                              size: widget.width * 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
