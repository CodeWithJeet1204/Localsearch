import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/skeleton_container.dart';
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
  bool isReplying = false;
  String currentReplyCommentId = '';
  String currentReplyCommenter = '';
  FocusNode focusNode = FocusNode();

  // DISPOSE
  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

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
      final commentId = const Uuid().v4();

      comments.addAll({
        commentId: [
          commentController.text,
          auth.currentUser!.uid,
          {},
        ],
      });

      await store.collection('Events').doc(widget.eventId).update({
        'eventComments': comments,
      });

      commentController.clear();
    }
  }

  // CONFIRM DELETE COMMENT
  Future<void> confirmDeleteComment(
    String commentId,
    String? replyCommentId,
  ) async {
    await showDialog(
      context: context,
      builder: ((context) {
        return AlertDialog(
          title: const Text(
            'Confirm DELETE',
          ),
          content: Text(
            'Are you sure you want to delete this ${replyCommentId != null ? 'Reply' : ''} Comment?',
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
                await deleteComment(commentId, replyCommentId);
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
  Future<void> deleteComment(
    String replyCommentId,
    String? parentCommentId,
  ) async {
    final eventSnap =
        await store.collection('Events').doc(widget.eventId).get();

    final eventData = eventSnap.data()!;

    Map<String, dynamic> comments = eventData['eventComments'];

    if (parentCommentId != null) {
      (comments[parentCommentId][2] as Map<String, dynamic>)
          .remove(replyCommentId);
    } else {
      comments.remove(replyCommentId);
    }

    await store.collection('Events').doc(widget.eventId).update({
      'eventComments': comments,
    });
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // REPLY COMMENT
  Future<void> replyComment(String commentId, String commenter) async {
    final eventSnap =
        await store.collection('Events').doc(widget.eventId).get();

    final eventData = eventSnap.data()!;

    Map<String, dynamic> comments = eventData['eventComments'];

    final newCommentId = const Uuid().v4();

    (comments[commentId][2] as Map<String, dynamic>).addAll({
      newCommentId: [
        '@$commenter ${commentController.text}',
        auth.currentUser!.uid,
      ],
    });

    await store.collection('Events').doc(widget.eventId).update({
      'eventComments': comments,
    });

    commentController.clear();

    setState(() {
      isReplying = false;
      currentReplyCommentId = '';
      currentReplyCommenter = '';
    });
  }

  // REPLY COMMENT WIDGET
  List<Widget> replyCommentWidget(
    Map<String, dynamic> replyComments,
    String parentReplyCommentId,
    double width,
  ) {
    List<Widget> replyCommentsWidget = [];
    for (var reply in replyComments.entries) {
      final replyCommentId = reply.key;
      final replyComment = reply.value[0];
      final replyCommenterId = reply.value[1];

      replyCommentsWidget.add(
        Container(
          width: width * 0.85,
          decoration: BoxDecoration(
            color: primary2.withOpacity(0.1),
            border: Border.all(
              width: 1,
              color: primaryDark.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.0225,
            vertical: width * 0.015,
          ),
          margin: const EdgeInsets.symmetric(
            vertical: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // COMMENT
              SizedBox(
                width: replyCommenterId == auth.currentUser!.uid
                    ? width * 0.666
                    : width * 0.7975,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder(
                        future: getCommenterName(
                          replyCommenterId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text('User');
                          }

                          if (snapshot.hasData) {
                            final commenter = snapshot.data!;

                            return Text(
                              commenter,
                              style: TextStyle(
                                color: primaryDark2.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }

                          return Container();
                        }),
                    const SizedBox(height: 6),
                    Text(
                      replyComment,
                      style: TextStyle(
                        color: primaryDark.withOpacity(0.8),
                        fontSize: width * 0.0525,
                      ),
                    ),
                  ],
                ),
              ),

              // DELETE
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  replyCommenterId == auth.currentUser!.uid
                      ? IconButton(
                          onPressed: () async {
                            await confirmDeleteComment(
                              replyCommentId,
                              parentReplyCommentId,
                            );
                          },
                          icon: const Icon(
                            FeatherIcons.trash,
                            color: Colors.red,
                          ),
                          color: Colors.red,
                          iconSize: width * 0.066,
                          tooltip: "Delete Comment",
                        )
                      : Container(),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return replyCommentsWidget;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final commentsStream =
        store.collection('Events').doc(widget.eventId).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
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
              child: TextFormField(
                controller: commentController,
                focusNode: focusNode,
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: Colors.cyan.shade700,
                    ),
                  ),
                  hintText: 'Comment',
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () async {
                isReplying
                    ? await replyComment(
                        currentReplyCommentId,
                        currentReplyCommenter,
                      )
                    : await addComment();
              },
              icon: const Icon(
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
                          return const Center(
                            child: Text("Something Went Wrong"),
                          );
                        }

                        if (snapshot.hasData) {
                          final eventData = snapshot.data!;

                          final Map<String, dynamic> comments =
                              eventData['eventComments'];

                          return comments.isEmpty
                              ? const Center(
                                  child: Text('No Comments'),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: comments.length,
                                  itemBuilder: ((context, index) {
                                    final commentId =
                                        comments.keys.toList()[index];
                                    final commenterId =
                                        comments.values.toList()[index][1];
                                    final comment =
                                        comments.values.toList()[index][0];
                                    final Map<String, dynamic> replyComments =
                                        comments.values.toList()[index][2];

                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        // COMMENT
                                        Container(
                                          width: width,
                                          decoration: BoxDecoration(
                                            color: primary2.withOpacity(0.125),
                                            border: Border.all(
                                              width: 1,
                                              color:
                                                  primaryDark.withOpacity(0.25),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
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
                                                width: commenterId ==
                                                        auth.currentUser!.uid
                                                    ? width * 0.655
                                                    : width * 0.79,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    FutureBuilder(
                                                        future:
                                                            getCommenterName(
                                                          commenterId,
                                                        ),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                              .hasError) {
                                                            return const Text(
                                                                'User');
                                                          }

                                                          if (snapshot
                                                              .hasData) {
                                                            final commenter =
                                                                snapshot.data!;

                                                            return Text(
                                                              commenter,
                                                              style:
                                                                  const TextStyle(
                                                                color:
                                                                    primaryDark2,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            );
                                                          }

                                                          return Container();
                                                        }),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      comment,
                                                      style: TextStyle(
                                                        color: primaryDark,
                                                        fontSize:
                                                            width * 0.0525,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // DELETE
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  commenterId !=
                                                          auth.currentUser!.uid
                                                      ? Container()
                                                      : IconButton(
                                                          onPressed: () async {
                                                            await confirmDeleteComment(
                                                              commentId,
                                                              null,
                                                            );
                                                          },
                                                          icon: const Icon(
                                                            FeatherIcons.trash,
                                                            color: Colors.red,
                                                          ),
                                                          color: Colors.red,
                                                          iconSize:
                                                              width * 0.066,
                                                          tooltip:
                                                              "Delete Comment",
                                                        ),

                                                  // REPLY
                                                  IconButton(
                                                    onPressed: () async {
                                                      focusNode.requestFocus();

                                                      final commenter =
                                                          await getCommenterName(
                                                        commenterId,
                                                      );

                                                      setState(() {
                                                        currentReplyCommentId =
                                                            commentId;
                                                        currentReplyCommenter =
                                                            commenter;
                                                        isReplying = true;
                                                      });
                                                    },
                                                    icon: const Icon(
                                                      FeatherIcons.cornerUpLeft,
                                                      color: primaryDark2,
                                                    ),
                                                    color: primaryDark2,
                                                    iconSize: width * 0.066,
                                                    tooltip: "Reply",
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // REPLY COMMENT
                                        replyComments.isEmpty
                                            ? Container()
                                            : SizedBox(
                                                width: width * 0.85,
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const ClampingScrollPhysics(),
                                                  itemCount: replyCommentWidget(
                                                    replyComments,
                                                    commentId,
                                                    width,
                                                  ).length,
                                                  itemBuilder:
                                                      ((context, index) {
                                                    return replyCommentWidget(
                                                      replyComments,
                                                      commentId,
                                                      width,
                                                    )[index];
                                                  }),
                                                ),
                                              ),
                                      ],
                                    );
                                  }),
                                );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
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
                                      color: const Color.fromRGBO(
                                          195, 195, 195, 1),
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
                                        const SizedBox(height: 12),
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
