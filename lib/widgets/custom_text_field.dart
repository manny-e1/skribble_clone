import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isMessageField;
  final Function(String value)? onSubmitted;
  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.isMessageField = false,
    this.onSubmitted
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction:
          isMessageField ? TextInputAction.done : TextInputAction.none,
      onSubmitted: onSubmitted,
      autocorrect: isMessageField ? false : true,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: const Color(0xffF5F5FA),
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),
    );
  }
}
