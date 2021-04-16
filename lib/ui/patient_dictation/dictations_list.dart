import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/common/app_toast_message.dart';
import 'package:YOURDRS_FlutterAPP/network/models/dictations/dictations_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/dictations/play_dictations.dart';
import 'package:YOURDRS_FlutterAPP/network/models/home/schedule.dart';
import 'package:YOURDRS_FlutterAPP/network/services/dictation/play_audio_services.dart';
import 'package:YOURDRS_FlutterAPP/ui/patient_dictation/play_audio.dart';
import 'package:YOURDRS_FlutterAPP/widget/buttons/mic_button.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DictationsList extends StatefulWidget {
  static const String routeName = '/DictationsList';
  @override
  _DictationsListState createState() => _DictationsListState();
}

class _DictationsListState extends State<DictationsList> {
  // PDFDocument document ;
  @override
  void initState() {
    super.initState();
    //   loadDocument();
  }
  bool isNetAvailable;
  var filePath;
  @override
  Widget build(BuildContext context) {
    //.......progressing bar
    Future<void> showLoadingDialog(BuildContext context, String msg) async {
      return showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
                onWillPop: () async => false,
                child: SimpleDialog(
                    // backgroundColor: Colors.black54,
                    backgroundColor: Colors.white,
                    children: <Widget>[
                      Center(
                        child: Row(children: [
                          SizedBox(
                            width: 25,
                          ),
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                                CustomizedColors.primaryColor),
                          ),
                          SizedBox(
                            width: 35,
                          ),
                          Text(
                            msg,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          )
                        ]),
                      )
                    ]));
          });
    }
    final Map args = ModalRoute.of(context).settings.arguments;
    List<DictationItem> list = args['list'];
    final Map args3 = ModalRoute.of(context).settings.arguments;
    ScheduleList item = args3['item'];
    /// used to get the recording from the server
    getRecordings(String fileName, String displayFileName) async {
      Directory appDocDirectory;
      //platform checking conditions
      if (Platform.isIOS) {
        appDocDirectory = await getApplicationDocumentsDirectory();
      } else {
        appDocDirectory = await getExternalStorageDirectory();
      }
      String dir = appDocDirectory.path;
      String fileExists = "$dir/" + "$fileName";
      /// check whether the file is there or no in device storage
      if (File(fileExists).existsSync()){
        filePath = fileExists;
        setState(() {
          isNetAvailable = true;
        });
      }else{
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.mobile ||
            connectivityResult == ConnectivityResult.wifi) {
          setState(() {
            isNetAvailable = true;
          });
          PlayAllAudioDictations apiServices1 = PlayAllAudioDictations();
          PlayDictations playDictations =
          await apiServices1.getDictationsPlayAudio(fileName);
          var getRecordings = playDictations.fileName;
          http.Response response = await http.get('$getRecordings');
          var _base64 = base64Encode(response.bodyBytes);
          Uint8List bytes = base64.decode(_base64);
          File file = File("$dir/" + '$displayFileName' + ".mp4");
          await file.writeAsBytes(bytes);
          filePath = file.path;
        } else {
          setState(() {
            isNetAvailable = false;
          });
        }
      }
    }
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppStrings.allDictations),
        backgroundColor: CustomizedColors.appBarColor,
      ),
      body: Container(
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 20,
          vertical: MediaQuery.of(context).size.height / 50,
        ),
        child: ListView(
          children: [
            ListView.builder(
              physics: ScrollPhysics(),
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            AppStrings.textUploaded,
                            style: TextStyle(
                                color: CustomizedColors.uploadedTextColor,
                                fontSize: 16),
                          ),
                          SizedBox(
                            width: width * 0.045,
                          ),
                          Icon(
                            Icons.cloud_done,
                            size: 30,
                            color: CustomizedColors.dictationListIconColor,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: height * 0.020,
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                            list[index].displayFileName ?? "",
                            style: TextStyle(fontSize: 16),
                          )),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            padding: EdgeInsets.all(0),
                            onPressed: () async {
                              showLoadingDialog(context, AppStrings.loading);
                              await getRecordings(list[index].fileName,
                                  list[index].displayFileName);
                              Navigator.of(this.context, rootNavigator: true)
                                  .pop();
                              if(isNetAvailable == true){
                              await showModalBottomSheet<void>(
                                context: context,
                                builder: (BuildContext context) {
                                  return Container(
                                    height: height * 0.55,
                                    child: Center(
                                      child: Container(
                                        height: height * 0.50,
                                        width: width * 0.90,
                                        child: ListView(
                                          children: [
                                            Column(
                                              children: [
                                                PlayAudio(
                                                  displayFileName:
                                                      list[index].displayFileName,
                                                  filePath: filePath,
                                                ),
                                                MaterialButton(
                                                  child: Text(
                                                    AppStrings.cancel,
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        color: CustomizedColors
                                                            .textColor),
                                                  ),
                                                  color: CustomizedColors
                                                      .raisedButtonColor,
                                                  shape: StadiumBorder(),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );}else{
                                AppToast().showToast(AppStrings.networkNotConnected);
                              }
                            },
                            icon: Icon(
                              Icons.play_circle_fill,
                              size: 30,
                            ),
                            color: CustomizedColors.dictationListIconColor,
                          ),
                        ],
                      ),
                      Divider(
                        thickness: 1,
                      )
                    ],
                  ),
                );
              },
            ),
            Container(height: 65,)
          ],
        ),
      ),
      /// calling the mic button widget from widget folder
      floatingActionButton: AudioMicButtons(
          patientFName: item.patient.firstName,
          patientLName: item.patient.lastName,
          caseId: item.patient.accountNumber,
          patientDob: item.patient.dob,
          practiceId: item.practiceId,
          statusId: item.dictationStatusId,
          episodeId: item.episodeId,
          episodeAppointmentRequestId: item.episodeAppointmentRequestId,
          appointment_type: item.appointmentType),
    );
  }
}
