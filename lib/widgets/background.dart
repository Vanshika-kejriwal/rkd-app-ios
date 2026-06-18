import 'package:business_app/widgets/myappbar.dart';
import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget childs;
  final Widget? drawer;
  final bool appbar;
  final Widget appbartitle;
  final bool bottomvav;
  final bool showDrawer;
  final bool floatbutton;
  final NavigationBar? bottomNav;
  final Widget? floatbtn;
  final Widget? appbarleading;
  List<Widget> appbaractions = [];
  Background(
      {super.key,
      required this.childs,
      this.appbar = false,
      required this.appbartitle,
      this.bottomvav = false,
      this.floatbutton = false,
      this.showDrawer= false,
      this.bottomNav,
      this.drawer,
      this.floatbtn,
      this.appbarleading,
      required this.appbaractions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/background.jpeg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        drawer: showDrawer? drawer:null,
        appBar: appbar
            ? MyAppbar(
                leading: appbarleading,
                title: appbartitle,
                actions: appbaractions,
              )
            // : AppBar(
            //     backgroundColor: Colors.transparent,
            //   ),
            : null,
        backgroundColor: Colors.transparent,
        body: childs,
        bottomNavigationBar: bottomvav ? bottomNav : null,
        floatingActionButton: floatbutton ? floatbtn : null,
      ),
    );
  }
}
