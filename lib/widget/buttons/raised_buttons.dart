import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_text.dart';
import 'package:flutter/material.dart';

//stateless Widget for Common Raised Button
class RaisedButtons extends StatelessWidget {
  final String text;
  final GestureTapCallback onPressed;
  RaisedButtons({@required this.text, @required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: CustomizedColors.signInButtonColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.20,
        height: MediaQuery.of(context).size.width * 0.11,
        // padding:EdgeInsets.only(top: MediaQuery.of(context).size.height *0.02),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                  color: CustomizedColors.signInButtonTextColor, fontSize: 18,fontFamily: AppFonts.regular),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      onPressed: onPressed,
      shape: const StadiumBorder(),
    );
  }
}

class RaisedButtonCustom extends StatelessWidget {
  final String text;
  final GestureTapCallback onPressed;
  final buttonColor;
  final textColor;
  RaisedButtonCustom(
      {@required this.text,
      @required this.onPressed,
      @required this.buttonColor,
      @required this.textColor});
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      elevation: 1.8,
      color: buttonColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 57,
        padding: EdgeInsets.all(18.0),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 16,fontFamily: AppFonts.regular),
          textAlign: TextAlign.center,
        ),
      ),
      onPressed: onPressed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class RaisedBttn extends StatelessWidget {
  final String text;
  final button_color;
  final GestureTapCallback onPressed;
  RaisedBttn(
      {@required this.text,
      @required this.onPressed,
      @required this.button_color});
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: button_color,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.45,
        padding: EdgeInsets.all(18.0),
        child: Text(
          text, style: TextStyle(
            fontSize: 14,fontFamily: AppFonts.regular,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      onPressed: onPressed,
      //shape: const (),
    );
  }
}

class RaisedBtn1 extends StatelessWidget {
  RaisedBtn1(
      {@required this.text, @required this.onPressed, @required this.count});

  final String text;
  var count;
  final GestureTapCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    // TODO: implement build
    return Container(
      margin: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height / 40),
      width: width * 0.85,
      height: height * 0.11,
      child: this.count > 0
          ? RaisedButton(
              color: CustomizedColors.raisedBtnColor,
              onPressed: onPressed,
              child: Text(
                '$text ($count)',
                style: TextStyle(
                    color: CustomizedColors.raisedButtonTextColor,fontFamily: AppFonts.regular,
                    fontSize: 20),
                textAlign: TextAlign.center,
              ))
          : Card(
              elevation: 2,
              color: CustomizedColors.raisedBtnColor,
              child: Center(
                  child: Text(
                '$text ($count)',
                style: TextStyle(
                    color: CustomizedColors.raisedButtonTextColor,
                    fontSize: 20,fontFamily: AppFonts.regular,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ))),
    );
  }
}

class RaisedBtn extends StatelessWidget {
  RaisedBtn(
      {@required this.text, @required this.onPressed, @required this.iconData});

  final IconData iconData;
  final String text;
  final GestureTapCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
        width: 350,
        height: 80,
        child: RaisedButton(
            color: CustomizedColors.raisedBtnColor,
            onPressed: onPressed,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                iconData,
                color: CustomizedColors.primaryColor,
                size: 40,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                        color: CustomizedColors.primaryColor, fontSize: 20,fontFamily: AppFonts.regular),
                    textAlign: TextAlign.center,
                  )
                ],
              )
            ])));
  }
}
