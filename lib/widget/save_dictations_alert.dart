import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';

import '../common/app_text.dart';

class SaveDictationsAlert extends StatefulWidget {
  String title;
  var clr;
  int count;
  SaveDictationsAlert({@required this.title, @required this.clr, @required this.count});
  @override
  _SaveDictationsAlertState createState() => _SaveDictationsAlertState();
}

class _SaveDictationsAlertState extends State<SaveDictationsAlert> {
  bool isInternetAvailable;

  Future<bool> checkNetwork() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    isInternetAvailable = await checkNetwork();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: [
            Expanded(child: Text(widget.title,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: widget.clr,
              fontFamily: AppFonts.regular,),textAlign: TextAlign.center,)),
          ],
        ),
        actions: [
          FlatButton(
            child: Text(AppStrings.ok,style: TextStyle(fontFamily: AppFonts.regular,),),
            onPressed: () {
              int count = isInternetAvailable ? 0 : 1;
              Navigator.of(context).popUntil((_) => count++ >= widget.count);
              // if (isInternetAvailable) {
              //   int count = 0;
              //   Navigator.of(context).popUntil((_) => count++ >= widget.count);
              // } else if (!isInternetAvailable) {
              //   int count = 2;
              //   Navigator.of(context).popUntil((_) => count++ >= widget.count);
              // }
            },
          ),
        ],
      ),
    );
  }
}


