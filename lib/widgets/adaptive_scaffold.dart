import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackord/utils/styling.dart';
import 'package:trackord/utils/utils.dart';

class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;

  const AdaptiveScaffold(
      {super.key, required this.body, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: Align(
            alignment: Alignment.centerLeft,
            child: getAppBarTitle(context, title),
          ),
          iconTheme: IconThemeData(color: getAppBarIconColor(context)),
          backgroundColor: getAppBarColor(context),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: getStatusBarBrightness(context),
            statusBarIconBrightness: getStatusBarIconBrightness(context),
            systemNavigationBarColor: getPersistentNavColor(context),
          ),
          actions: actions,
        ),
        body: body,
      );
    } else {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: actions ?? [],
          ),
          backgroundColor: getAppBarColor(context),
          border: null,
        ),
        child: body,
      );
    }
  }
}
