import 'package:flutter/material.dart';
import 'package:find_easy_user/utils/colors.dart';

class SeeMoreText extends StatefulWidget {
  const SeeMoreText(
    this.text, {
    Key? key,
    this.textStyle,
    this.seeMoreStyle,
  });

  final String text;
  final TextStyle? textStyle;
  final TextStyle? seeMoreStyle;

  @override
  _SeeMoreTextState createState() => _SeeMoreTextState();
}

class _SeeMoreTextState extends State<SeeMoreText> {
  bool _isExpanded = false;
  int _currentMaxWords = 0;

  // INIT STATE
  @override
  void initState() {
    super.initState();
    _updateMaxWords();
  }

  // UPDATE MAX WORDS
  void _updateMaxWords() {
    _currentMaxWords += int.parse((widget.text.length / 3).toStringAsFixed(0));
    if (_currentMaxWords >= widget.text.split(' ').length) {
      _isExpanded = true;
      _currentMaxWords = int.parse((widget.text.length / 3).toStringAsFixed(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWords = int.parse((widget.text.length / 3).toStringAsFixed(0));
    String trimmedText = widget.text.trim();

    List<String> words = trimmedText.split(' ');
    if (!_isExpanded && words.length > _currentMaxWords) {
      trimmedText = words.sublist(0, _currentMaxWords).join(' ') + '... ';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          trimmedText,
          style: widget.textStyle ??
              TextStyle(
                color: primaryDark,
                fontSize: MediaQuery.of(context).size.width * 0.0425,
              ),
        ),
        if (!_isExpanded && words.length > _currentMaxWords)
          GestureDetector(
            onTap: () {
              setState(() {
                _updateMaxWords();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              child: Text(
                'See more',
                style: widget.seeMoreStyle ??
                    TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        if (_isExpanded && widget.text.length < maxWords)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = false;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              child: Text(
                'See less',
                style: widget.seeMoreStyle ??
                    TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
