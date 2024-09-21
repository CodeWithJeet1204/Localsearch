// import 'package:avatar_glow/avatar_glow.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToText extends StatefulWidget {
  const SpeechToText({super.key});

  @override
  State<SpeechToText> createState() => _SpeechToTextState();
}

class _SpeechToTextState extends State<SpeechToText> {
  late stt.SpeechToText speech;
  bool isListening = false;
  String text = 'Press the button to speak';
  double confidence = 1;

  // INIT STATE
  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }

  // LISTEN
  Future<void> listen() async {
    if (!isListening) {
      bool available = await speech.initialize(
        onStatus: (status) {},
        onError: (errorNotification) {},
      );
      if (available) {
        setState(() {
          isListening = true;
        });
        speech.listen(
          onResult: (result) {
            setState(() {
              text = result.recognizedWords;
              if (result.hasConfidenceRating && result.confidence > 0) {
                confidence = result.confidence;
              }
            });
          },
        );
      }
    } else {
      setState(() {
        isListening = false;
      });
      speech.stop();
      await done();
    }
  }

  // DONE
  Future<void> done() async {
    Navigator.of(context).pop(text == 'Press the button to speaks' ? '' : text);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: width,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: width * 0.9,
              height: 220,
              margin: EdgeInsets.all(width * 0.0125),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary2.withOpacity(0.66),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                maxLines: 5,
                style: TextStyle(
                  color: primaryDark,
                  fontSize: width * 0.05,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: width * 0.15,
                ),
                // AvatarGlow(
                //   animate: isListening,
                //   glowCount: 3,
                //   glowRadiusFactor: 0.2,
                //   glowColor: Theme.of(context).primaryColor,
                //   duration: const Duration(milliseconds: 1750),
                //   child: IconButton.filledTonal(
                //     onPressed: () async {
                //       await listen();
                //     },
                //     icon: Icon(
                //       isListening ? FeatherIcons.mic : FeatherIcons.micOff,
                //       size: width * 0.1125,
                //     ),
                //     tooltip: isListening ? 'Done' : 'Start Speaking',
                //   ),
                // ),
                IconButton.filledTonal(
                  onPressed: () async {
                    await listen();
                  },
                  icon: Icon(
                    isListening ? FeatherIcons.mic : FeatherIcons.micOff,
                    size: width * 0.1125,
                  ),
                  tooltip: isListening ? 'Done' : 'Start Speaking',
                ),
                Padding(
                  padding: EdgeInsets.only(right: width * 0.0125),
                  child: IconButton.outlined(
                    onPressed: () async {
                      await done();
                    },
                    icon: const Icon(
                      FeatherIcons.check,
                    ),
                    tooltip: 'Done',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
