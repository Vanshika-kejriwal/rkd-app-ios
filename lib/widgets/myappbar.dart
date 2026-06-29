import "package:flutter/material.dart";

class MyAppbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  List<Widget>? actions = [];
  final Widget? leading;

  MyAppbar({super.key, required this.title, this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    return AppBar(
        leading: leading,
        backgroundColor: Color(0xFFFFBF4D),
        title: title,
        centerTitle: true,
        actions: actions);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
