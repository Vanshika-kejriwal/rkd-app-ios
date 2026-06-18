import "package:flutter/material.dart";

class InputField extends StatelessWidget {
  final String label;
  final TextInputType keyboardtype;
  final bool obscuretext;
  final bool autofocus;
  final TextEditingController? controller;
  final Widget? suff;
  final Widget? sufficon;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final String? Function(String?)? validator;
  final String? initialValue;
  final String? helperText;
  final bool readOnly;
  final int? maxlines;
  final int minlines;

  const InputField(
      {super.key,
      required this.label,
      this.keyboardtype = TextInputType.text,
      this.obscuretext = false,
      this.autofocus = false,
      this.controller,
      this.suff,
      this.sufficon,
      this.onChanged,
      this.onTap,
      this.validator,
      this.initialValue,
      this.readOnly = false,
      this.maxlines = 1,
      this.helperText,
      this.minlines = 1});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        autofocus: autofocus,
        keyboardType: keyboardtype,
        maxLines: maxlines,
        minLines: minlines,
        obscureText: obscuretext ? true : false,
        controller: controller,
        onChanged: onChanged,
        // onEditingComplete: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        initialValue: initialValue,
        decoration: InputDecoration(
          helperText: helperText,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.brown, width: 1.0),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.brown, width: 1.0),
            ),
            labelText: label,
            labelStyle: const TextStyle(color: Colors.brown),
            suffix: suff,
            suffixIcon: sufficon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10)));
  }
}
