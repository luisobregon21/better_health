import 'package:better_health/auth.dart';
import 'package:better_health/pages/home_page.dart';
import 'package:better_health/pages/login_register_page.dart';
import 'package:flutter/material.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authstateChanges,
      builder: (context, snapshot) {
        // if (snapshot.hasData) {
        return MapPage();
        // } else {
        //   return const LoginPage();
        // }
      },
    );
  }
}
