import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// SHOW YOUTUBE PLAYER DIALOG
Future<void> showYouTubePlayerDialog(BuildContext context, String? url) async {
  if (url != null) {
    String? videoId = YoutubePlayer.convertUrlToId(url);
    print("Video id: $videoId");
    if (videoId != null) {
      if (videoId.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return YouTubePlayerDialog(videoId: videoId);
          },
        );
      } else {
        mySnackBar('Some error occured', context);
      }
    } else {
      mySnackBar('Some error occured', context);
    }
  } else {
    mySnackBar('Some error occured', context);
  }
}

// GET YOUTUBE VIDEO ID
String? getYoutubeVideoId(String url) {
  return YoutubePlayer.convertUrlToId(url);
}

class YouTubePlayerDialog extends StatefulWidget {
  const YouTubePlayerDialog({
    Key? key,
    required this.videoId,
  });

  final String videoId;

  @override
  _YouTubePlayerDialogState createState() => _YouTubePlayerDialogState();
}

class _YouTubePlayerDialogState extends State<YouTubePlayerDialog> {
  late YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        showLiveFullscreenButton: false,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YoutubePlayer(
            controller: controller,
            aspectRatio: 9 / 16,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
            bottomActions: [
              CurrentPosition(),
              ProgressBar(
                isExpanded: true,
                colors: ProgressBarColors(
                  playedColor: primary2,
                  handleColor: darkGrey,
                ),
              ),
            ],
            onEnded: (metaData) {
              controller.seekTo(Duration(seconds: 0));
              controller.play();
            },
          ),
        ],
      ),
    );
  }
}
