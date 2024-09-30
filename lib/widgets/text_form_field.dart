import 'package:flutter/material.dart';

class MyTextFormField extends StatefulWidget {
  const MyTextFormField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.autoFillHints,
    this.verticalPadding = 0,
    this.isPassword = false,
    this.keyboardType = TextInputType.name,
    this.autoFocus = true,
  });

  final String hintText;
  final bool isPassword;
  final bool autoFocus;
  final Iterable<String>? autoFillHints;
  final double borderRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final TextInputType? keyboardType;
  final TextEditingController controller;

  @override
  State<MyTextFormField> createState() => _MyTextFormFieldState();
}

class _MyTextFormFieldState extends State<MyTextFormField> {
  bool isShowPassword = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding,
        vertical: widget.verticalPadding,
      ),
      child: widget.isPassword
          ? Row(
              children: [
                Expanded(
                  child: TextFormField(
                    autofocus: false,
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    textCapitalization: TextCapitalization.words,
                    obscureText: isShowPassword,
                    onTapOutside: (event) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                        borderSide: BorderSide(
                          color: Colors.cyan.shade700,
                        ),
                      ),
                      hintText: widget.hintText,
                    ),
                    validator: (value) {
                      if (value != null) {
                        if (value.isEmpty) {
                          return 'Please enter ${widget.hintText}';
                        } else {
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                        }
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isShowPassword = !isShowPassword;
                    });
                  },
                  icon: isShowPassword
                      ? const Icon(Icons.remove_red_eye)
                      : const Icon(Icons.remove_red_eye_outlined),
                ),
              ],
            )
          : TextFormField(
              autofillHints: widget.autoFillHints,
              autofocus: false,
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              textCapitalization: TextCapitalization.words,
              onTapOutside: (event) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: Colors.cyan.shade700,
                  ),
                ),
                hintText: widget.hintText,
              ),
              validator: (value) {
                if (value != null) {
                  if (value.isNotEmpty) {
                    if (widget.hintText == 'Email') {
                      if (!value.contains('@') || !value.contains('.co')) {
                        return 'Invalid email';
                      }
                    } else if (widget.hintText == 'Phone Number') {
                      if (value.length != 10) {
                        return 'Phone No. should be 10 chars long';
                      }
                    }
                  } else {
                    return 'Pls enter ${widget.hintText}';
                  }
                }
                return null;
              },
            ),
    );
  }
}
