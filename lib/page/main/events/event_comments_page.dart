import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/skeleton_container.dart';
import 'package:localy_user/widgets/text_form_field.dart';
import 'package:uuid/uuid.dart';

class EventCommentsPage extends StatefulWidget {
  const EventCommentsPage({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<EventCommentsPage> createState() => _EventCommentsPageState();
}

class _EventCommentsPageState extends State<EventCommentsPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final commentController = TextEditingController();

  // GET COMMENTER NAME
  Future<String> getCommenterName(String userId) async {
    final userSnap = await store.collection('Users').doc(userId).get();

    final userData = userSnap.data()!;

    final name = userData['Name'];

    return name;
  }

  // ADD COMMENT
  Future<void> addComment() async {
    final eventSnap =
        await store.collection('Events').doc(widget.eventId).get();

    final eventData = eventSnap.data()!;

    Map<String, dynamic> comments = eventData['eventComments'];

    if (commentController.text.isNotEmpty) {
      final commentId = Uuid().v4();

      comments.addAll({
        commentId: [
          commentController.text,
          auth.currentUser!.uid,
        ],
      });

      await store.collection('Events').doc(widget.eventId).update({
        'eventComments': comments,
      });

      commentController.clear();
    }
  }

  // CONFIRM DELETE COMMENT
  Future<void> confirmDeletComment(String commentId) async {
    await showDialog(
      context: context,
      builder: ((context) {
        return AlertDialog(
          title: const Text(
            overflow: TextOverflow.ellipsis,
            'Confirm DELETE',
          ),
          content: const Text(
            overflow: TextOverflow.ellipsis,
            'Are you sure you want to delete Comment?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                overflow: TextOverflow.ellipsis,
                'NO',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await deleteComment(commentId);
              },
              child: const Text(
                overflow: TextOverflow.ellipsis,
                'YES',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // DELETE COMMENT
  Future<void> deleteComment(String commentId) async {
    final eventSnap =
        await store.collection('Events').doc(widget.eventId).get();

    final eventData = eventSnap.data()!;

    Map<String, dynamic> comments = eventData['eventComments'];

    final commentId = Uuid().v4();

    comments.remove(commentId);

    await store.collection('Events').doc(widget.eventId).update({
      'eventComments': comments,
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final commentsStream =
        store.collection('Events').doc(widget.eventId).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      bottomSheet: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: height * 0.01),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: width * 0.825,
              child: MyTextFormField(
                hintText: 'Comment',
                controller: commentController,
                borderRadius: 4,
                horizontalPadding: 0,
                autoFillHints: [],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () async {
                await addComment();
              },
              icon: Icon(
                FeatherIcons.send,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width * 0.0125,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final width = MediaQuery.of(context).size.width;

              return SingleChildScrollView(
                child: SizedBox(
                  width: width,
                  height: height - 176,
                  child: StreamBuilder(
                      stream: commentsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Something Went Wrong"),
                          );
                        }

                        if (snapshot.hasData) {
                          final eventData = snapshot.data!;

                          final Map<String, dynamic> comments =
                              eventData['eventComments'];

                          return comments.isEmpty
                              ? Center(
                                  child: Text('No Comments'),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: ClampingScrollPhysics(),
                                  itemCount: comments.length,
                                  itemBuilder: ((context, index) {
                                    final commentId =
                                        comments.keys.toList()[index];
                                    final commenterId =
                                        comments.values.toList()[index][1];
                                    final comment =
                                        comments.values.toList()[index][0];

                                    return Container(
                                      width: width,
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0225,
                                        vertical: width * 0.015,
                                      ),
                                      margin: EdgeInsets.symmetric(
                                        vertical: index != 0 ? 4 : 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // COMMENT
                                          SizedBox(
                                            width: width * 0.7966,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                FutureBuilder(
                                                    future: getCommenterName(
                                                        commenterId),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot.hasError) {
                                                        return Text('User');
                                                      }

                                                      if (snapshot.hasData) {
                                                        final commenter =
                                                            snapshot.data!;

                                                        return Text(
                                                          commenter,
                                                          style: TextStyle(
                                                            color: primaryDark2,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        );
                                                      }

                                                      return Container();
                                                    }),
                                                SizedBox(height: 6),
                                                Text(
                                                  comment,
                                                  style: TextStyle(
                                                    color: primaryDark,
                                                    fontSize: width * 0.0525,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // DELETE
                                          commenterId != auth.currentUser!.uid
                                              ? Container()
                                              : IconButton(
                                                  onPressed: () async {
                                                    await confirmDeletComment(
                                                      commentId,
                                                    );
                                                  },
                                                  icon: Icon(
                                                    FeatherIcons.trash,
                                                    color: Colors.red,
                                                  ),
                                                  color: Colors.red,
                                                  iconSize: width * 0.066,
                                                  tooltip: "Delete Comment",
                                                ),
                                        ],
                                      ),
                                    );
                                  }),
                                );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: ClampingScrollPhysics(),
                          itemCount: 8,
                          itemBuilder: ((context, index) {
                            return Padding(
                              padding: EdgeInsets.all(width * 0.0125),
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                    width: width,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(195, 195, 195, 1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.015,
                                      vertical: 0,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SkeletonContainer(
                                          width: width * 0.33,
                                          height: 12,
                                        ),
                                        SizedBox(height: 12),
                                        SkeletonContainer(
                                          width: width * 0.75,
                                          height: 48,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
