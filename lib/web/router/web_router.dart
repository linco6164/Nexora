import 'package:flutter/material.dart';

import '../web_home.dart';
import '../../web/widgets/web_explore.dart';

class WebRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case "/":
        return MaterialPageRoute(
          builder: (_) => const WebHome(),
        );

      case "/explore":
        return MaterialPageRoute(
          builder: (_) => const WebExplore(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text("404"),
            ),
          ),
        );
    }
  }
}