import 'dart:convert';
import 'dart:io';

import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/common/app_toast_message.dart';
import 'package:YOURDRS_FlutterAPP/helper/db_helper.dart';
import 'package:YOURDRS_FlutterAPP/network/models/external_dictations/external_databse_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/external_dictation_attacment_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/photo_list.dart';
import 'package:YOURDRS_FlutterAPP/network/repo/local/preference/local_storage.dart';
import 'package:YOURDRS_FlutterAPP/network/services/external_attachment/external_localtoserver_postapi.dart';
import 'package:YOURDRS_FlutterAPP/ui/home/home_screen.dart';
import 'package:YOURDRS_FlutterAPP/utils/route_generator.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/app_text.dart';
import 'allattachment/attachment_details/server/externalpage_get_api.dart';
import 'external_submitnew/external_submitscreen.dart';


//-----------------------This is ExternalAttachment home page this is the main page for submitne class and all attachment class

class ExternalAttachments extends StatefulWidget {
  static const String routeName = '/ExternalAttachments';
  @override
  _ExternalAttachmentStat createState() => _ExternalAttachmentStat();
}

class _ExternalAttachmentStat extends State<ExternalAttachments> {
  AppToast appToast=AppToast();
  bool isInternetAvailable=false;

  bool emergencyAddOn = true;
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  int toggleVal;
  Future<bool> checkNetwork() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi;
  }
    @override
  void initState() {
    // TODO: implement initState
      checkNetwork();
    super.initState();
     // _syncOfflineRecords();
  }
  Future<void> showLoadingDialog(BuildContext context, GlobalKey key) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new WillPopScope(
          onWillPop: () async => false,
          child: SimpleDialog(
            key: key,
            backgroundColor: Colors.white,
            children: <Widget>[
              Center(
                child: Row(
                  children: [
                    SizedBox(
                      width: 25,
                    ),
                    CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation(CustomizedColors.primaryColor),
                    ),
                    SizedBox(
                      width: 35,
                    ),
                    Text(
                      AppStrings.loading,
                      style: TextStyle( fontFamily: AppFonts.regular,
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  ///sync offline records to server
  // _syncOfflineRecords() async {
  //   try {
  //     if(await checkNetwork()){
  //       var allRows = await DatabaseHelper.db.queryUnsynchedRecords();
  //       print('_syncOfflineRecords ${allRows?.length}');
  //       allRows.forEach((row) async {
  //         int dictationId = await saveOfflineDictations(row);
  //         print('SaveDbDictations res $dictationId');
  //         if(dictationId!=null){
  //           await DatabaseHelper.db.updateRecords(1, dictationId, row['id']);
  //         }
  //       });
  //     } else {
  //       print("Failed to update the records");
  //     }
  //   } catch (e) {
  //     print(e.toString());
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
          appBar: AppBar(
           // automaticallyImplyLeading: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: ()
              {
                RouteGenerator.navigatorKey.currentState
                    .pushReplacementNamed(PatientAppointment.routeName);
              },
            ),
            backgroundColor: CustomizedColors.appbarColor,
            title: Text(AppStrings.externalattachment,style: TextStyle(fontFamily: AppFonts.regular,fontSize: 22),),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.cloud_upload_outlined, size: 35),
                onPressed: () async {
                  List<ExternalAttachmentList> offlineRecords =
                      await DatabaseHelper.db.getAllExtrenalAttachmentList();
                 // print('offlineRecords ${offlineRecords?.length}');
                  /// Each manual record
                  if(offlineRecords.length!=0){
                  for(ExternalAttachmentList record in offlineRecords){
                    toggleVal=record.isemergencyaddon;
                   // print('offlineRecords record id ${record?.id}');

                    showLoadingDialog(context, _keyLoader);
                for(ExternalAttachmentList record in offlineRecords){
                  //  print('offlineRecords record id ${record?.id}');
                    List<PhotoList> offlinePhotoList = await DatabaseHelper.db.getAttachmentImages(record?.id);

                    /// Each offline manual photo for id
                    var photoListOfGallery = [];
                    for(PhotoList photo in offlinePhotoList){
                     // print('offlineRecords photo id ${record?.id}');
                      String filePath = photo.physicalfilename;
                      // String audioFileName = path.basename(filePath);
                      List<int> fileBytes = await File(filePath).readAsBytes();
                      String convertedImg = base64Encode(fileBytes);

                      photoListOfGallery.add({
                        "header": {
                          "status": "string",
                          "statusCode": "string",
                          "statusMessage": "string"
                        },
                        "content": convertedImg,
                        "name": photo?.attachmentname,
                        "attachmentType": photo?.attachmenttype
                      });
                    }

                    try {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      String memberId = (prefs.getString(Keys.memberId) ?? '');
                              if (toggleVal == 0) {
                                     emergencyAddOn = false;
                                   } else {
                                     emergencyAddOn = true;
                                }
                      ExternalAttachmentDataApi apiAttachmentPostServices =
                          ExternalAttachmentDataApi();
                      SaveExternalDictationOrAttachment saveDictationAttachments =
                          await apiAttachmentPostServices.postApiServiceMethod(
                        record?.practiceid,
                        //selectedPracticeId
                        record?.locationid,
                        //locationId
                        record?.providerid,
                        //providerId
                        record?.patientfirstname,
                        //patientFname
                        record?.patientlastname,
                        //patientLname
                        record?.patientdob,
                        //patientDob
                        memberId,
                        record?.externaldocumenttypeid,
                            emergencyAddOn,
                        record?.description,
                        null,
                        null,
                        null,
                        photoListOfGallery,
                      );

                      String statusCode =
                          saveDictationAttachments?.header?.statusCode;
                      //printing status code
                      print("status!!!!!!!!!!!!!!!!!!!!!!!!!! $statusCode");
                      int externalDocumentUploadId =
                          saveDictationAttachments?.externalDocumentUploadId;
                      print('SaveDbDictations res $externalDocumentUploadId');
                      if (statusCode == '200' &&
                          externalDocumentUploadId != null) {
                        await DatabaseHelper.db.updateExternalAttachmentRecord(
                            1, externalDocumentUploadId, record?.id);
                        Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
                        appToast.showToast('Uploaded successfully!!!');
                        await RouteGenerator.navigatorKey.currentState
                            .pushReplacementNamed(
                            ExternalAttachments.routeName);
                      } else {
                      //  print("error !!!!!!!!!!!!!!!!!!!!!!!!!! ${saveDictationAttachments?.header?.statusMessage}");
                      }
                    } catch (e) {
                      print('SaveAttachmentDictation exception ${e.toString()}');
                    }
                  }}}else{
                    appToast.showToast('no offline records found!!!');
                  }
                })
          ],
          ),
          body: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 65,
                  child: Container(
                    //elevation: 5,
                    //color: CustomizedColors.tabColor,
                    child: TabBar(
                      tabs: [
                        Tab(
                            child: Text(
                          AppStrings
                              .submitnew, //here we called the text for SubmitNew
                          style: TextStyle( fontFamily: AppFonts.regular,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CustomizedColors.submitnew_textColor,
                          ),
                        )),
                        Tab(
                          child: Text(
                            AppStrings
                                .allattachment, //here we called the text for AllAttachment
                            style: TextStyle( fontFamily: AppFonts.regular,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CustomizedColors.allattachment_textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(boxShadow: [
                      new BoxShadow(
                        color: Colors.white,
                      ),
                    ]),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                     //
                       SubmitNew(),
                      GetMyAttachments(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

    );
  }
}
