import 'package:business_app/screens/user_registration.dart';
import 'package:business_app/widgets/background.dart';
import 'package:flutter/material.dart';

class UserRegHeader extends StatelessWidget {
  bool fromLogin;
  UserRegHeader({super.key, this.fromLogin = false});

  @override
  Widget build(BuildContext context) {
    return Background(
        appbaractions: const [],
        appbar: true,
        appbartitle: const Text("User Registration"),
        childs: SafeArea(
          child: UserRegistration(fromLogin: fromLogin,),
        ));
  }
}
