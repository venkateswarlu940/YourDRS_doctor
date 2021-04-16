import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/network/models/dictations/play_dictations.dart';
import 'package:YOURDRS_FlutterAPP/network/models/external_dictations/get_all_manual_dictation_model.dart';
import 'package:YOURDRS_FlutterAPP/network/services/dictation/dictation_services.dart';
import 'package:YOURDRS_FlutterAPP/network/services/dictation/play_audio_services.dart';
import 'package:YOURDRS_FlutterAPP/ui/patient_dictation/play_audio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GetMyManualDictations extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return GetMyManualDictationsState();
  }
}

class GetMyManualDictationsState extends State<GetMyManualDictations> {
  /// Declaring variables
  bool _hasMore;
  int _pageNumber;
  bool _error;
  bool _loading;
  final int _defaultDataPerPageCount = 20;
  List<AudioDictations> _audioDictates;
  int thresholdValue = 0;
  var filePath;

  /// Creating an object for GetAllMyManualDictationApi
  AllMyManualDictations apiServices = AllMyManualDictations();

  /// initState
  @override
  void initState() {
    super.initState();
    _hasMore = true;
    _pageNumber = 1;
    _error = false;
    _loading = true;
    _audioDictates = [];
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    GetAllMyManualDictation allMyManualDictations =
    await apiServices.getMyManualDictations(_pageNumber);
    if (!mounted) return;
    setState(() {
      _hasMore = allMyManualDictations.audioDictations?.length ==
          _defaultDataPerPageCount;
      _loading = false;
      _pageNumber = _pageNumber + 1;
      _audioDictates.addAll(allMyManualDictations?.audioDictations);
    });
  }

  /// build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(),
    );
  }

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
    if (File(fileExists).existsSync()) {
      filePath = fileExists;
    } else {
      PlayAllAudioDictations apiServices1 = PlayAllAudioDictations();
      PlayDictations playDictations =
          await apiServices1.getDictationsPlayAudio(fileName);
      var getRecordings = playDictations.fileName;
      http.Response response = await http.get('$getRecordings');
      var _base64 = base64Encode(response.bodyBytes);
      Uint8List bytes = base64.decode(_base64);
      File file = File("$dir/" + '$fileName' + ".mp4");
      await file.writeAsBytes(bytes);
      filePath = file.path;
    }
    print('*****************************************');
    print(filePath);
  }

  /// body Widget
  Widget getBody() {
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
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          )
                        ]),
                      )
                    ]));
          });
    }

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    if (_audioDictates?.isEmpty ?? false) {
      if (_loading) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(CustomizedColors.primaryColor),
            ),
          ),
        );
      } else if (_error) {
        return Center(
            child: InkWell(
          onTap: () {
            setState(
              () {
                _loading = true;
                _error = false;
                didChangeDependencies();
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
                "Error while loading photos, tap to try again after sometime"),
          ),
        ));
      }
    } else {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 20,
          vertical: MediaQuery.of(context).size.height / 50,
        ),
        child: ListView.builder(
            itemCount: _audioDictates.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _audioDictates.length - thresholdValue) {
                didChangeDependencies();
              }
              if (index == _audioDictates.length) {
                if (_error) {
                  return Center(
                      child: InkWell(
                    onTap: () {
                      setState(() {
                        _loading = true;
                        _error = false;
                        didChangeDependencies();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                          Text("Error while loading photos, tap to try again"),
                    ),
                  ));
                } else {
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(CustomizedColors.primaryColor),
                    ),
                  ));
                }
              }
              final AudioDictations audioDictations = _audioDictates[index];
              // print("all data loaded successfully 7");
              return Container(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          AppStrings.textUploaded,
                          style: TextStyle(
                              color: CustomizedColors.uploadToServerTextColor,
                              fontSize: 14.5),
                        ),
                        SizedBox(
                          width: width * 0.045,
                        ),
                        Icon(
                          Icons.cloud_done_outlined,
                          size: 30,
                          color: CustomizedColors.accentColor,
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
                          audioDictations.displayFileName,
                          style: TextStyle(fontSize: 16),
                        )),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          padding: EdgeInsets.all(0),
                          icon: Icon(
                            Icons.remove_red_eye,
                            size: 30,
                          ),
                          onPressed: () {
                            // showDialog(
                            //     context: context,
                            //     builder: (ctx) => AlertDialog(
                            //           insetPadding:
                            //               EdgeInsets.symmetric(vertical: 70),
                            //           contentPadding: EdgeInsets.zero,
                            //           content: PDFViewer(
                            //             showNavigation: false,
                            //             showPicker: false,
                            //             scrollDirection: Axis.vertical,
                            //             document: document,
                            //             zoomSteps: 1,
                            //           ),
                            //           actions: [
                            //             FlatButton(
                            //               child: Text('Close'),
                            //               onPressed: () {
                            //                 Navigator.of(context,
                            //                         rootNavigator: true)
                            //                     .pop();
                            //               },
                            //             ),
                            //           ],
                            //         ));
                          },
                          color: CustomizedColors.accentColor,
                        ),
                        IconButton(
                          padding: EdgeInsets.all(0),
                          icon: IconButton(
                            padding: EdgeInsets.all(0),
                            onPressed: () async {
                              if (audioDictations.fileName.isEmpty ||
                                  audioDictations.fileName == null ||
                                  audioDictations.displayFileName == null ||
                                  audioDictations.displayFileName.isEmpty) {
                                // Navigator.of(this.context, rootNavigator: true)
                                //     .pop();
                                showDialog(
                                  context: context,
                                  builder: (ctxx) => AlertDialog(
                                    // insetPadding: EdgeInsets.symmetric(
                                    //     vertical: 70),
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(AppStrings.noAudioRecordings),
                                    actions: [
                                      FlatButton(
                                        child: Text(AppStrings.closeDialog),
                                        onPressed: () {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                        },
                                      ),
                                    ],
                                  ),
                                  barrierDismissible: false,
                                );
                              } else {
                                showLoadingDialog(context, AppStrings.loading);
                                await getRecordings(audioDictations.fileName,
                                    audioDictations.displayFileName);
                                Navigator.of(this.context, rootNavigator: true)
                                    .pop();
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
                                                        audioDictations
                                                            .displayFileName,
                                                    filePath: filePath,
                                                  ),
                                                  MaterialButton(
                                                    child: Text(
                                                      AppStrings.cancel,
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          color:
                                                              CustomizedColors
                                                                  .textColor),
                                                    ),
                                                    color: CustomizedColors
                                                        .raisedButtonColor,
                                                    shape: StadiumBorder(),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
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
                                );
                              }
                            },
                            icon: Icon(
                              Icons.play_circle_fill,
                              size: 30,
                            ),
                            color: CustomizedColors.dictationListIconColor,
                          ),
                          onPressed: () {
                            showModalBottomSheet<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  height: 370,
                                  child: Center(
                                    child: Container(
                                      height: 320,
                                      width: MediaQuery.of(context).size.width *
                                          0.90,
                                      child: Column(
                                        children: [
                                          PlayAudio(
                                            displayFileName:
                                                audioDictations.displayFileName,
                                            filePath: null,
                                          ),
                                          MaterialButton(
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(fontSize: 18),
                                            ),
                                            color: CustomizedColors
                                                .cameraIconcolor,
                                            shape: StadiumBorder(),
                                            onPressed: () {
                                              Navigator.of(context,
                                                      rootNavigator: true)
                                                  .pop();
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          color: CustomizedColors.accentColor,
                        ),
                      ],
                    ),
                    Divider(
                      thickness: 1,
                    ),
                  ],
                ),
              );
            }),
      );
    }
    return Container();
  }
}
