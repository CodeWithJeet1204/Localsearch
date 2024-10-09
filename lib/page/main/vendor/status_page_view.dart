import 'package:carousel_slider/carousel_slider.dart';
import 'package:localsearch/page/main/vendor/vendor_page.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/utils/colors.dart';

class StatusPageView extends StatefulWidget {
  const StatusPageView({
    super.key,
    required this.currentIndex,
    required this.status,
  });

  final int currentIndex;
  final Map<String, Map<String, dynamic>> status;

  @override
  State<StatusPageView> createState() => _StatusPageViewState();
}

class _StatusPageViewState extends State<StatusPageView> {
  final PageController _pageController = PageController();
  final carouselController = CarouselSliderController();
  late int index;
  int currentImageIndex = 0;

  // INIT STATE
  @override
  void initState() {
    index = widget.currentIndex;
    super.initState();
  }

  // SHOW TEXT DIALOG
  Future<void> showTextDialog(String text, double width) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: primary2,
          child: Container(
            padding: EdgeInsets.all(width * 0.033),
            child: SingleChildScrollView(
              child: Text(
                text.toString().trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  // FLATTEN POSTS
  List<Map<String, dynamic>> flattenStatus() {
    List<Map<String, dynamic>> statusList = [];

    widget.status.forEach((vendorId, vendorData) {
      String vendorName = vendorData['vendorName'] ?? '';
      String vendorImageUrl = vendorData['vendorImageUrl'] ?? '';

      Map<String, dynamic> vendorStatus = vendorData['status'] ?? {};

      vendorStatus.forEach((statusId, status) {
        if (status is Map<String, dynamic>) {
          statusList.add({
            'vendorId': vendorId,
            'vendorName': vendorName,
            'vendorImageUrl': vendorImageUrl,
            'statusId': statusId,
            'statusText': status['statusText'] ?? '',
            'statusImage': status['statusImage'] ?? '',
            'statusViews': status['statusViews'] ?? '',
            'isViewed': status['isViewed'] ?? false,
          });
        }
      });
    });

    return statusList;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    List<Map<String, dynamic>> flattenedStatus = flattenStatus();

    return Scaffold(
      backgroundColor: black,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              FeatherIcons.x,
              color: white,
            ),
            color: white,
            tooltip: 'CLOSE',
          ),
        ],
        automaticallyImplyLeading: false,
        foregroundColor: white,
        backgroundColor: black,
        shadowColor: black,
        surfaceTintColor: black,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: flattenedStatus.length,
        itemBuilder: (context, index) {
          final status = flattenedStatus[index];
          final vendorId = status['vendorId'];
          final statusText = status['statusText'];
          final List statusImageUrl = status['statusImage'];

          return Padding(
            padding: EdgeInsets.all(width * 0.006125),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => VendorPage(
                          vendorId: vendorId,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.0125),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: width * 0.05,
                          backgroundImage: NetworkImage(
                            status['vendorImageUrl'].toString().trim(),
                          ),
                          backgroundColor: Colors.black,
                        ),
                        SizedBox(width: width * 0.0125),
                        Text(
                          status['vendorName'].toString().trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.055,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Center(
                      child: CarouselSlider(
                        carouselController: carouselController,
                        items: statusImageUrl
                            .map(
                              (e) => Image.network(
                                e,
                                width: width,
                                height: width,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.low,
                              ),
                            )
                            .toList(),
                        options: CarouselOptions(
                          enableInfiniteScroll: false,
                          aspectRatio: 1,
                          enlargeCenterPage: true,
                          onPageChanged: (index, reason) {
                            setState(() {
                              carouselController.animateToPage(index);
                            });
                          },
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        index == 0
                            ? Container()
                            : Container(
                                decoration: BoxDecoration(
                                  color: primaryDark2,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.arrow_left,
                                    color: Colors.white,
                                    size: width * 0.09,
                                  ),
                                  padding: EdgeInsets.all(width * 0.025),
                                ),
                              ),
                        index == (flattenedStatus.length - 1)
                            ? Container()
                            : Container(
                                decoration: BoxDecoration(
                                  color: primaryDark2,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.arrow_right,
                                    color: Colors.white,
                                    size: width * 0.09,
                                  ),
                                  padding: EdgeInsets.all(width * 0.025),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: width * 0.025),
                    child: GestureDetector(
                      onTap: () async {
                        await showTextDialog(statusText, width);
                      },
                      child: Text(
                        statusText.toString().trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
