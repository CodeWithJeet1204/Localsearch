// import 'package:flick_video_player/flick_video_player.dart';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

// class FlickManagerProvider with ChangeNotifier {
//   FlickManager? _flickManager;
//   FlickManager? get flickManager => _flickManager;

//   // INITIALIZE
//   void initialize(String url) {
//     _flickManager = FlickManager(
//       videoPlayerController: VideoPlayerController.networkUrl(
//         Uri.parse(
//           url,
//         ),
//       ),
//     );

//     notifyListeners();
//   }

//   // PAUSE PLAY SHORT
//   void pausePlayShort() {
//     flickManager!.flickControlManager?.togglePlay();
//   }
// }
