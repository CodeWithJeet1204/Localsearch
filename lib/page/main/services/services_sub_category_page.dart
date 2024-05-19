import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/services/services_man_page.dart';
import 'package:find_easy_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class ServicesSubCategoryPage extends StatefulWidget {
  const ServicesSubCategoryPage({
    super.key,
    required this.subCategory,
  });

  final String subCategory;

  @override
  State<ServicesSubCategoryPage> createState() =>
      _ServicesSubCategoryPageState();
}

class _ServicesSubCategoryPageState extends State<ServicesSubCategoryPage> {
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> serviceman = {};
  bool isData = false;

  // INIT STATE
  @override
  void initState() {
    getIdData();
    super.initState();
  }

  // GET ID DATA
  Future<void> getIdData() async {
    List myIds = [];
    final serviceSnap = await store.collection('Services').get();
    serviceSnap.docs.forEach((service) {
      final serviceData = service.data();
      final String id = service.id;
      final Map subCategories = serviceData['SubCategory'];
      subCategories.keys.forEach((subCategoryKey) {
        if (subCategoryKey == widget.subCategory) {
          myIds.add(id);
        }
      });
    });

    await getServicemanData(myIds);
  }

  // GET SERVICEMAN DATA
  Future<void> getServicemanData(List subCategoryId) async {
    Map<String, dynamic> myServiceman = {};
    await Future.forEach(subCategoryId, (id) async {
      final servicemanSnap = await store.collection('Services').doc(id).get();
      final servicemanData = servicemanSnap.data()!;
      final name = servicemanData['Name'];
      final imageUrl = servicemanData['Image'];
      myServiceman[id] = [name, imageUrl];
    });

    setState(() {
      serviceman = myServiceman;
      isData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subCategory),
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
            icon: Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: "Help",
          ),
        ],
      ),
      body: !isData
          ? Center(
              child: CircularProgressIndicator(),
            )
          : serviceman.isEmpty
              ? Center(
                  child: Text('No One Available'),
                )
              : SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(
                      width * 0.006125,
                    ),
                    child: SizedBox(
                      width: width,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemCount: serviceman.length,
                        itemBuilder: ((context, index) {
                          final id = serviceman.keys.toList()[index];
                          final name = serviceman.values.toList()[index][0];
                          final imageUrl = serviceman.values.toList()[index][1];

                          return Padding(
                            padding: EdgeInsets.all(width * 0.0125),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(imageUrl),
                              ),
                              title: Text(name),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: ((context) => ServicesManPage(
                                          id: id,
                                        )),
                                  ),
                                );
                              },
                              trailing: Icon(
                                FeatherIcons.chevronRight,
                                size: width * 0.066,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
    );
  }
}
