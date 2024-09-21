import 'package:flutter/material.dart';
import 'package:localsearch/utils/colors.dart';

class SeeMoreText extends StatefulWidget {
  const SeeMoreText(
    this.text, {
    this.textStyle,
    this.maxWords = 40,
    this.seeMoreStyle,
    super.key,
  });

  final String text;
  final int maxWords;
  final TextStyle? textStyle;
  final TextStyle? seeMoreStyle;

  @override
  // ignore: library_private_types_in_public_api
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
    _currentMaxWords += widget.maxWords;
    if (_currentMaxWords >= widget.text.split(' ').length) {
      _isExpanded = true;
      _currentMaxWords = widget.maxWords;
    }
  }

  @override
  Widget build(BuildContext context) {
    String trimmedText = widget.text.trim();

    List<String> words = trimmedText.split(' ');
    if (!_isExpanded && words.length > _currentMaxWords) {
      trimmedText = '${words.sublist(0, _currentMaxWords).join(' ')}... ';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                textAlign: TextAlign.end,
                style: widget.seeMoreStyle ??
                    const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        if (_isExpanded && widget.text.length > widget.maxWords)
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
                textAlign: TextAlign.end,
                style: widget.seeMoreStyle ??
                    const TextStyle(
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
