import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/network/repo/local/preference/local_storage.dart';
import 'package:YOURDRS_FlutterAPP/ui/external_attachment/externalattchment_main.dart';

import 'package:YOURDRS_FlutterAPP/ui/login/login_screen/loginscreen.dart';
import 'package:YOURDRS_FlutterAPP/ui/manual_dictaions/manual_dictations.dart';
import 'package:YOURDRS_FlutterAPP/utils/route_generator.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Pop extends StatefulWidget {
  final int initialValue;
  Pop({@required this.initialValue});

  @override
  _PopState createState() => _PopState();
}

class _PopState extends State<Pop> {
  SharedPreferences logindata;
  String username;
  @override
  void initState() {
    super.initState();
    initial();
  }

  void initial() async {
    logindata = await SharedPreferences.getInstance();
    setState(() {
      username = logindata.getString('username');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  int number;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final mediaQueryData = MediaQuery.of(context);
    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0))),
      itemBuilder: (context) => [
// -----> list of items in the PopupMenuButton <--------
        PopupMenuItem(
          // height: MediaQuery.of(context).size.height *0.07,
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.mic,
                color: CustomizedColors.primaryColor,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                AppStrings.item1,
                style: TextStyle(
                    color: CustomizedColors.dropdowntxtcolor,
                    fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          // height: MediaQuery.of(context).size.height*0.07,
          value: 2,
          child: Row(
            children: [
              Icon(
                Icons.attach_file_sharp,
                color: CustomizedColors.primaryColor,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                AppStrings.item2,
                style: TextStyle(
                    color: CustomizedColors.dropdowntxtcolor,
                    fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),

      ],
      icon: Icon(Icons.add),
// ----> it will display the PopupMenuButton based on the value <---

      offset: Offset(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height / 2 * -0.50),

// ------> this method is called when particular item is selected <------
      onSelected: (value) async {
        if (value == 1) {
          RouteGenerator.navigatorKey.currentState.pushReplacementNamed(ManualDictations.routeName);
        } else if (value == 2) {
          RouteGenerator.navigatorKey.currentState.pushReplacementNamed(ExternalAttachments.routeName);
        } else {}
      },
      initialValue: widget.initialValue,
    );
  }
}
