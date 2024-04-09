import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/search/search_results_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MySearchBar extends StatefulWidget {
  const MySearchBar({
    super.key,
    required this.width,
  });

  final double width;

  @override
  State<MySearchBar> createState() => _MySearchBarState();
}

class _MySearchBarState extends State<MySearchBar> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  bool isMicPressed = false;
  bool isSearchPressed = false;

  // LISTEN
  Future<void> listen() async {
    var result = await showDialog(
      context: context,
      builder: ((context) => const SpeechToText()),
    );

    if (result != null && result is String) {
      searchController.text = result;
    }
  }

  // SEARCH
  Future<void> search() async {
    await addRecentSearch();

    if (searchController.text.isNotEmpty) {
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) =>
                SearchResultsPage(search: searchController.text)),
          ),
        );
      }
    }
  }

  // ADD RECENT SEARCH
  Future<void> addRecentSearch() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final recent = userData['recentSearches'] as List;

    if (recent.contains(searchController.text)) {
      recent.remove(searchController.text);
    }

    if (searchController.text.isNotEmpty) {
      recent.insert(0, searchController.text);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'recentSearches': recent,
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;

    return Padding(
      padding: EdgeInsets.only(
        bottom: width * 0.0125,
      ),
      child: Container(
        color: primary2,
        child: Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                width: width * 0.1,
                height: width * 0.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(
                  FeatherIcons.arrowLeft,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: width * 0.025,
                bottom: width * 0.0225,
                right: width * 0.0125,
              ),
              child: Container(
                width: width * 0.875,
                height: width * 0.1875,
                decoration: BoxDecoration(
                  color: primary,
                  border: Border.all(
                    color: primaryDark.withOpacity(0.75),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: width * 0.566,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            width: 0.5,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: TextFormField(
                        autofillHints: const [],
                        autofocus: false,
                        minLines: 1,
                        maxLines: 1,
                        controller: searchController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            textBaseline: TextBaseline.alphabetic,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTapDown: (details) {
                            setState(() {
                              isMicPressed = true;
                            });
                          },
                          onTapUp: (details) {
                            setState(() {
                              isMicPressed = false;
                            });
                          },
                          onTapCancel: () {
                            setState(() {
                              isMicPressed = false;
                            });
                          },
                          onTap: () async {
                            await listen();
                          },
                          customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            width: width * 0.15,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isMicPressed
                                  ? primary2.withOpacity(0.95)
                                  : primary2.withOpacity(0.25),
                            ),
                            child: Icon(
                              FeatherIcons.mic,
                              size: width * 0.066,
                            ),
                          ),
                        ),
                        InkWell(
                          onTapDown: (details) {
                            setState(() {
                              isSearchPressed = true;
                            });
                          },
                          onTapUp: (details) {
                            setState(() {
                              isSearchPressed = false;
                            });
                          },
                          onTapCancel: () {
                            setState(() {
                              isSearchPressed = false;
                            });
                          },
                          onTap: () async {
                            await search();
                          },
                          customBorder: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(0),
                              bottomLeft: Radius.circular(0),
                              bottomRight: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Container(
                            width: width * 0.15,
                            decoration: BoxDecoration(
                              color: isSearchPressed
                                  ? primary2.withOpacity(0.95)
                                  : primary2.withOpacity(0.25),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(0),
                                bottomLeft: Radius.circular(0),
                                bottomRight: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              FeatherIcons.search,
                              size: width * 0.066,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
