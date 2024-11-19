import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/page/main/vendor/vendor_page.dart';
import 'package:localsearch/utils/colors.dart';

class StatusPageView extends StatefulWidget {
  const StatusPageView({
    super.key,
    required this.vendorId,
    required this.status,
  });

  final String vendorId;
  final Map<String, Map<String, dynamic>> status;

  @override
  State<StatusPageView> createState() => _StatusPageViewState();
}

class _StatusPageViewState extends State<StatusPageView> {
  late int currentVendorIndex;
  late int currentStatusIndex;

  @override
  void initState() {
    super.initState();
    // Set the current vendor index based on the initial vendorId
    currentVendorIndex = widget.status.keys.toList().indexOf(widget.vendorId);
    currentStatusIndex = 0; // Start with the first status of the vendor
  }

  // FLATTEN POSTS
  List<Map<String, dynamic>> flattenStatus() {
    List<Map<String, dynamic>> statusList = [];
    widget.status.forEach((vendorId, vendorData) {
      String vendorName = vendorData['vendorName'] ?? '';
      String vendorImageUrl = vendorData['vendorImageUrl'] ?? '';
      Map<String, dynamic> vendorStatus = vendorData['status'] ?? {};
      List<Map<String, dynamic>> vendorStatuses = [];

      vendorStatus.forEach((statusId, status) {
        if (status is Map<String, dynamic>) {
          vendorStatuses.add({
            'statusId': statusId,
            'statusText': status['statusText'].toString().trim().isEmpty
                ? ''
                : status['statusText'],
            'statusImage': status['statusImage'] ?? [],
          });
        }
      });

      if (vendorStatuses.isNotEmpty) {
        statusList.add({
          'vendorId': vendorId,
          'vendorName': vendorName,
          'vendorImageUrl': vendorImageUrl,
          'statuses': vendorStatuses,
        });
      }
    });
    return statusList;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    List<Map<String, dynamic>> flattenedStatus = flattenStatus();
    final currentVendorData = flattenedStatus[currentVendorIndex];
    final List<Map<String, dynamic>> statuses = currentVendorData['statuses'];

    return Scaffold(
      backgroundColor: black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(width * 0.025),
          child: GestureDetector(
            onTapUp: (details) {
              final screenWidth = MediaQuery.sizeOf(context).width;
              if (details.localPosition.dx > screenWidth / 2) {
                if (currentStatusIndex < statuses.length - 1) {
                  setState(() {
                    currentStatusIndex++;
                  });
                } else if (currentVendorIndex < flattenedStatus.length - 1) {
                  setState(() {
                    currentVendorIndex++;
                    currentStatusIndex = 0;
                  });
                }
              } else {
                if (currentStatusIndex > 0) {
                  setState(() {
                    currentStatusIndex--;
                  });
                } else if (currentVendorIndex > 0) {
                  setState(() {
                    currentVendorIndex--;
                    currentStatusIndex =
                        flattenedStatus[currentVendorIndex]['statuses'].length -
                            1;
                  });
                }
              }
            },
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => VendorPage(
                                vendorId: currentVendorData['vendorId'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.0125,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: width * 0.05,
                                backgroundImage: NetworkImage(
                                  currentVendorData['vendorImageUrl']
                                      .toString()
                                      .trim(),
                                ),
                                backgroundColor: Colors.black,
                              ),
                              SizedBox(width: width * 0.0125),
                              Text(
                                currentVendorData['vendorName']
                                    .toString()
                                    .trim(),
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
                      SizedBox(height: width * 0.02),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: (statuses[currentStatusIndex]['statusImage']
                                  as List)
                              .map<Widget>((e) => CachedNetworkImage(
                                    progressIndicatorBuilder:
                                        (context, url, progress) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: white,
                                        ),
                                      );
                                    },
                                    imageUrl: e,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                statuses[currentStatusIndex]['statusText'] == ''
                    ? Container()
                    : Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            color: Colors.black.withOpacity(0.6),
                            child: Text(
                              statuses[currentStatusIndex]['statusText'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
