import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/common/app_text.dart';
import 'package:YOURDRS_FlutterAPP/common/app_toast_message.dart';
import 'package:YOURDRS_FlutterAPP/helper/db_helper.dart';
import 'package:YOURDRS_FlutterAPP/network/models/dictations/allImages_models.dart';
import 'package:YOURDRS_FlutterAPP/network/models/dictations/imageFilename_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/photo_list.dart';
import 'package:YOURDRS_FlutterAPP/network/services/dictation/getAllImages_service.dart';
import 'package:YOURDRS_FlutterAPP/network/services/dictation/getFilename_service.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;

class ViewImages extends StatefulWidget {
  static const String routeName = "/ViewImages";

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return ViewImagesState();
  }
}

class ViewImagesState extends State<ViewImages> {
  final GetImage getImage = GetImage();
  List imagesList = [];
  var decoded;
  int gIndex, olineIndex;
  String items;
  bool isInternetAvalibale = false;

  //check internet connection
  Future<bool> checkNetwork() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    try {
      if (connectivityResult == ConnectivityResult.mobile) {
        return true;
      } else if (connectivityResult == ConnectivityResult.wifi) {
        return true;
      }
    } catch (e) {
      print(e.toString());
      AppToast().showToast(AppStrings.no_internet);
      return false;
    }
  }


  //...get filenames of image
  getImageFile() async {
    final List item = ModalRoute.of(this.context).settings.arguments;
    try {
      for (int i = 0; i < item.length; i++) {
        GetFileNames getFileNames = await getImage.getImageFile(item[i]);
        if (getFileNames != null) {
          if (getFileNames.content != null && getFileNames.content.isNotEmpty) {
            Uint8List decoded = base64.decode(getFileNames.content);
            imagesList.add(decoded);
            setState(() {});
          }
        }
      }
    } catch (e) {}
  }

  void initState() {
    checkNetwork().then((internet) async {
      ///..........Internet Present Case
      try {
        if (internet != null && internet) {
          isInternetAvalibale = true;
          await getImageFile();
        } else {
          isInternetAvalibale = false;
        }
        super.initState();
      } catch (e) {
        print(e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.uploadedImages,
            style: TextStyle(fontFamily: AppFonts.regular),
          ),
          backgroundColor: CustomizedColors.primaryColor,
        ),
        body: isInternetAvalibale ? onlineData() : offlineData());
  }


  //....view online data
  @override
  Widget onlineData() {
    return Column(children: [
      Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 0, 0),
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(
              color: CustomizedColors.homeSubtitleColor,
            ),
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(0),
                bottomLeft: Radius.circular(10),
                topLeft: Radius.circular(10),
                bottomRight: Radius.zero),
          ),
          child: imagesList == null || imagesList.isEmpty
              ? _loader(AppStrings.loading)
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagesList.length,
                  itemBuilder: (context, index) {
                    try {
                      return GestureDetector(
                        child: Container(
                            margin: const EdgeInsets.all(10.0),
                            height: 130,
                            width: 150,
                            child: Image.memory(
                              imagesList[index],
                              fit: BoxFit.cover,
                            )),
                        onTap: () {
                          setState(() {
                            gIndex = index;
                          });
                        },
                      );
                    }catch (e) {
                      print(e.toString());
                    }
                    return Container();
                  })),
      SizedBox(
        height: 20,
      ),
      Expanded(
        child: Container(
            margin: const EdgeInsets.all(30),
            child: gIndex == null
                ? Container()
                : Image.memory(
                    imagesList[gIndex],
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      return wasSynchronouslyLoaded ? child : _loader('');
                    },
                    fit: BoxFit.contain,
                  )),
      )
    ]);
  }

  //...view offline images
  @override
  Widget offlineData() {
    final List dictaId = ModalRoute.of(this.context).settings.arguments;
    return Column(children: [
      Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 0, 0),
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(
              color: CustomizedColors.homeSubtitleColor,
            ),
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(0),
                bottomLeft: Radius.circular(10),
                topLeft: Radius.circular(10),
                bottomRight: Radius.zero),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dictaId.length,
            itemBuilder: (context, index) {
              try {
                PhotoList item = dictaId[index];
                return GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.all(10.0),
                    height: 130,
                    width: 150,
                    color: CustomizedColors.homeSubtitleColor,
                    child: Image.file(
                      File('${item.physicalfilename}'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      items = item.physicalfilename;
                    });
                  },
                );
              } catch (e) {
                print(e.toString());
              }
              return Container();
            },
          )),
      SizedBox(
        height: 20,
      ),
      Expanded(
        child: Container(
          margin: const EdgeInsets.all(10),
          child: Image.file(
            File(items == null ? "" : items),
            fit: BoxFit.contain,
          ),
        ),
      )
    ]);
  }
}

//show loading dialog
Widget _loader(String msg) {
  return Center(
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 25,
      ),
      CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(CustomizedColors.primaryColor),
      ),
      SizedBox(
        width: 35,
      ),
      Text(
        msg,
        style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: AppFonts.regular),
      )
    ]),
  );
}
