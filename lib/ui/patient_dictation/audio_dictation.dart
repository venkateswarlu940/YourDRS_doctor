// import 'dart:html';

import 'package:YOURDRS_FlutterAPP/blocs/dictation_screen/audio_dictation_bloc.dart';
import 'package:YOURDRS_FlutterAPP/blocs/dictation_screen/audio_dictation_event.dart';
import 'package:YOURDRS_FlutterAPP/blocs/dictation_screen/audio_dictation_state.dart';
import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_constants.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/common/app_toast_message.dart';
import 'package:YOURDRS_FlutterAPP/helper/db_helper.dart';
import 'package:YOURDRS_FlutterAPP/network/models/dictations/post_dictations_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/dictation.dart';
import 'package:YOURDRS_FlutterAPP/network/repo/local/preference/local_storage.dart';
import 'package:YOURDRS_FlutterAPP/network/services/dictation/post_dictations_service.dart';
import 'package:YOURDRS_FlutterAPP/ui/audio_dictations/random_waves.dart';
import 'package:YOURDRS_FlutterAPP/widget/save_dictations_alert.dart';
import 'package:connectivity/connectivity.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<State> _keyLoader = GlobalKey<State>();

class AudioDictationForPatientDetails extends StatefulWidget {
  final String patientFName,
      patientLName,
      patientDob,
      dictationTypeId,
      caseNum,
      dictationTypeName,
      appointmentType;
  final int onlineStatusId;
  final int offlineStatusId = 107;
  final episodeAppointmentRequestId, episodeId;
  final int offlineUploadedToServer = 0, onlineUploadToServer = 1;
  final int statusId = 17;
  const AudioDictationForPatientDetails(
      {Key key,
      this.patientFName,
      this.patientLName,
      this.patientDob,
      this.dictationTypeId,
      this.caseNum,
      this.appointmentType,
      this.dictationTypeName,
      this.episodeId,
      this.onlineStatusId,
      this.episodeAppointmentRequestId})
      : super(key: key);
  @override
  _AudioDictationState createState() => _AudioDictationState();
}
class _AudioDictationState extends State<AudioDictationForPatientDetails> {
  var data, dictId;
  String memberId;
  var dob;
  var memeberRoleId;
  String attachmentContent;
  String fName;
  String lName;
  bool isInternetAvailable = true;
  bool isStarted = false;
  bool isStartedUploadBtn = true;
  String audioSize;
  bool isUpload = false;
  bool saveforlater = false;

  @override
  void initState() {
    super.initState();
    // var data = DatabaseHelper.db.getAllDictations();
    _loadData();
    DeleteFiles();
  }
  ///delete 90 days older records
  void DeleteFiles() async {
    await DatabaseHelper.db.deleteAllOlderRecords();
  }
  ///checking internet connectivity to upload files to server.
  checkNetwork() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      //  connected to a mobile network.
      setState(() {
        isInternetAvailable = true;
      });
    } else {
      //  connected to a wifi network.
      setState(() {
        isInternetAvailable = false;
        AppToast().showToast(AppStrings.networkNotConnected);
      });
    }
  }
  ///customized loading indicator.
  Future<void> showLoadingDialog(BuildContext context, GlobalKey key) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
              onWillPop: () async => false,
              child: SimpleDialog(
                  key: key,
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
                          AppStrings.uploading,
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
  ///Loading data from shared preferences.
  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      memberId = (prefs.getString(Keys.memberId) ?? '');
      dob = (prefs.getString(Keys.dob) ?? '');

      memeberRoleId = (prefs.getString(Keys.memberRoleId) ?? '');
    });
  }
  /// parsing parameters to service class
  SaveDictations(String attachmentContentType) async {
    String lastAudioFilePath =
        BlocProvider.of<AudioDictationBloc>(context).finalPath;
    String audioFileName = path.basename(lastAudioFilePath);
    fName = widget.patientFName;
    lName = widget.patientLName;
    try {
      PostDictationsService apiPostServices = PostDictationsService();
      PostDictationsModel saveDictations = await apiPostServices.postApiMethod(
          int.tryParse(memberId),
          dob,
          widget.episodeId,
          widget.episodeAppointmentRequestId,
          int.parse(memeberRoleId),
          int.parse(widget.dictationTypeId),
          fName,
          lName,
          widget.caseNum,
          widget.patientDob,
          attachmentContent,
          audioFileName,
          widget.dictationTypeName);
      dictId = saveDictations.dictationId;
      data = saveDictations.header.statusCode;
    } catch (e) {
      print('${e.toString()}');
    }
  }
  ///Alert dialouge box to show success and Fail status.
  _dialogBox(int i) {
    if (data == "200") {
      return showDialog(
          barrierDismissible: false,
          context: context,
          builder: (ctx) => SaveDictationsAlert(
                title: AppStrings.uploadToServer,
                clr: CustomizedColors.uploadToServerTextColor,
                count: i,
              ));
    } else {
      return showDialog(
          barrierDismissible: false,
          context: context,
          builder: (ctx) => SaveDictationsAlert(
                title: AppStrings.uploadFailed,
                clr: CustomizedColors.uploadFailTextColor,
                count: i,
              ));
    }
  }
  LocalFileSystem localFileSystem;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  bool viewVisible = true;
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat(AppConstants.dateFormat);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    this.localFileSystem = localFileSystem ?? LocalFileSystem();
    if (mounted) {
      /// bloc provider for init event
      BlocProvider.of<AudioDictationBloc>(context).add(InitRecord());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: _body(),
      ),
    );
  }
  _body() {
    final height = MediaQuery.of(context).size.height;
    return BlocListener<AudioDictationBloc, AudioDictationState>(
      listener: (context, state) async {
        attachmentContent = state.attachmentContent;
        if (isUpload || saveforlater) {
          if (attachmentContent != null && attachmentContent.isNotEmpty) {
            await SaveDictations(state.attachmentContentType);
            if (saveforlater) {
              _InsertRecordsToDataBase(
                  widget.statusId, widget.onlineUploadToServer,
                  dictationId: dictId.toString());
              saveforlater = false;
              await _dialogBox(3);
            } else {
              isUpload = false;
              _InsertRecordsToDataBase(
                  widget.onlineStatusId, widget.onlineUploadToServer,
                  dictationId: dictId.toString());
              await _dialogBox(4);
            }
        }
        }
        _currentStatus = state.currentStatus;
        _current = state.current;
        viewVisible = state.viewVisible;
        isStarted = (_currentStatus == RecordingStatus.Recording ||
            _currentStatus == RecordingStatus.Paused);

        if (state.errorMsg != null && state.errorMsg.isNotEmpty) {
          Scaffold.of(context).showSnackBar(SnackBar(
              content: Text(state.errorMsg ?? AppStrings.someThingWentWrong)));
        }
      },
      child: BlocBuilder<AudioDictationBloc, AudioDictationState>(
        builder: (context, state) {
          return Center(
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width / 30,
                      vertical: MediaQuery.of(context).size.height / 150),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${_printDuration(_current?.duration)}"),
                            /////Save for later flat button
                            FlatButton(
                                onPressed: isStarted
                                    ? () async {
                                        ///calling post api to upload audio file
                                        BlocProvider.of<AudioDictationBloc>(
                                                context)
                                            .add(StopRecord());

                                        //checking internet connection
                                        await checkNetwork();
                                        if (isInternetAvailable == true) {
                                          saveforlater = true;
                                          ///progress bar
                                          showLoadingDialog(
                                              context, _keyLoader);
                                        } else {
                                          ///save dictations offline
                                          _InsertRecordsToDataBase(
                                              widget.statusId,
                                              widget.offlineUploadedToServer);
                                          await _dialogBox(4);
                                        }
                                      }
                                    : null,
                                child: Text(
                                  AppStrings.saveForLater,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isStarted
                                          ? CustomizedColors.saveLaterColor
                                          : null,
                                      fontSize: 18),
                                ))
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              color: CustomizedColors.waveBGColor,
                              child: Visibility(
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  visible: viewVisible,
                                  /// calling random wave class
                                  child: RandomWaves()),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width / 30,
                                  vertical:
                                      MediaQuery.of(context).size.height / 150),
                              child: FlatButton(
                                  padding: EdgeInsets.all(0),

                                  ///on press for start and resume.
                                  onPressed: isStartedUploadBtn
                                      ? () {
                                          switch (_currentStatus) {
                                            case RecordingStatus.Initialized:
                                              {
                                                /// bloc provider for start record event
                                                BlocProvider.of<
                                                            AudioDictationBloc>(
                                                        context)
                                                    .add(StartRecord());
                                                //Toast for recording started

                                                AppToast().showToast(AppStrings
                                                    .recordingStarted);
                                                break;
                                              }
                                            case RecordingStatus.Recording:
                                              {
                                                /// bloc provider for pause record event
                                                BlocProvider.of<
                                                            AudioDictationBloc>(
                                                        context)
                                                    .add(PauseRecord());
                                                //Toast for recording paused

                                                AppToast().showToast(
                                                    AppStrings.recordingPaused);
                                                break;
                                              }
                                            case RecordingStatus.Paused:
                                              {
                                                /// bloc provider for resume record event
                                                BlocProvider.of<
                                                            AudioDictationBloc>(
                                                        context)
                                                    .add(ResumeRecord());
                                                //Toast for recording resumed

                                                AppToast().showToast(AppStrings
                                                    .recordingResumed);
                                                break;
                                              }
                                            case RecordingStatus.Stopped:
                                              {
                                                /// bloc provider for init event
                                                BlocProvider.of<
                                                            AudioDictationBloc>(
                                                        context)
                                                    .add(InitRecord());
                                                break;
                                              }
                                            default:
                                              break;
                                          }
                                        }
                                      : null,
                                  child: _buildText(_currentStatus)),
                            ),

                            ////upload icon
                            FlatButton(
                                padding: EdgeInsets.all(0),
                                onPressed: isStarted
                                    ? () async {
                                        await BlocProvider.of<
                                                AudioDictationBloc>(context)
                                            .add(PauseRecord());
                                        /// Upload audio popup screen
                                        await showModalBottomSheet(
                                          isDismissible: false,
                                          context: context,
                                          builder: (BuildContext sheetContext) {
                                            return ListView(
                                              children: [
                                                Container(
                                                  height: height * 0.40,
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        Icons.cloud_upload,
                                                        size: 75,
                                                        color: CustomizedColors
                                                            .waveColor,
                                                      ),
                                                      SizedBox(
                                                        height: height * 0.01,
                                                      ),
                                                      Text(
                                                        AppStrings.dict,
                                                        style: TextStyle(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: height * 0.025,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          /// cancel button in upload dictation dialouge
                                                          Container(
                                                            child: RaisedButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: Text(
                                                                AppStrings
                                                                    .cancel,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: CustomizedColors
                                                                        .alertCancelColor),
                                                              ),
                                                            ),
                                                          ),

                                                          ///upload button with functionalities.
                                                          Container(
                                                            child: RaisedButton(
                                                              onPressed:
                                                                  () async {
                                                                setState(() {
                                                                  isStartedUploadBtn =
                                                                      false;
                                                                });

                                                                ///calling post api to upload audio file
                                                                BlocProvider.of<
                                                                            AudioDictationBloc>(
                                                                        context)
                                                                    .add(
                                                                        StopRecord());
                                                                //checking internet connection
                                                                await checkNetwork();
                                                                if (isInternetAvailable ==
                                                                    true) {
                                                                  isUpload =
                                                                      true;

                                                                  showLoadingDialog(
                                                                      context,
                                                                      _keyLoader);

                                                                } else {
                                                                  setState(() {
                                                                    isStarted =
                                                                        false;
                                                                  });
                                                                  AppToast().showToast(
                                                                      AppStrings
                                                                          .networkNotConnected);
                                                                  _dialogBox(5);

                                                                  //   int count = 0;
                                                                  // Navigator.of(context).popUntil((_) => count++ >= 2);
                                                                  ///If no internet(offline) records would be saved in db.
                                                                  _InsertRecordsToDataBase(
                                                                      widget
                                                                          .offlineStatusId,
                                                                      widget
                                                                          .offlineUploadedToServer);
                                                                  _dialogBox(6);
                                                                }
                                                              },
                                                              child: Text(
                                                                AppStrings
                                                                    .upload,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: CustomizedColors
                                                                        .textColor),
                                                              ),
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        /// bloc provider for save record event
                                      }
                                    : null,
                                //cloud icon to upload file.
                                child: Icon(
                                  Icons.cloud_upload,
                                  size: 60,
                                  color: isStarted
                                      ? CustomizedColors.waveColor
                                      : null,
                                )),

                            FlatButton(
                              child: Icon(
                                Icons.delete,
                                color: isStarted
                                    ? CustomizedColors.deleteIconColor
                                    : null,
                                size: 50,
                              ),
                              onPressed: isStarted
                                  ? () {
                                      /// bloc provider for delete record event
                                      BlocProvider.of<AudioDictationBloc>(
                                              context)
                                          .add(DeleteRecord());
                                      //Toast for recording deleted.

                                      AppToast().showToast(
                                          AppStrings.recordingDeleted);
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RaisedButton(
                              onPressed: () {
                                if (isStarted == false) {
                                  Navigator.pop(context);
                                } else {
                                  /// bloc provider for delete record event
                                  BlocProvider.of<AudioDictationBloc>(context)
                                      .add(DeleteRecord());
                                  Navigator.pop(context);
                                }
                              },
                              child: Text(
                                AppStrings.cancel,
                                style: TextStyle(
                              fontSize:
                                    20,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                    color: CustomizedColors
                                        . cancelDictationTextColor),

                              ),
                            ),
                          ],
                        )
                      ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  /// setting timer format
  String _printDuration(Duration duration) {
    if (duration != null) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return '';
  }
  ///play pause button icons
  Widget _buildText(RecordingStatus status) {
    var icon;
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        {
          icon = Icons.not_started;
          break;
        }
      case RecordingStatus.Recording:
        {
          icon = Icons.pause;
          break;
        }
      case RecordingStatus.Paused:
        {
          icon = Icons.play_arrow;
          break;
        }
      case RecordingStatus.Stopped:
        {
          icon = Icons.stop_outlined;
          break;
        }
      default:
        break;
    }
    return Icon(
      icon,
      color: isStartedUploadBtn ? CustomizedColors.waveColor : null,
      size: 60,
    );
  }
  ///insert online and offline Dictation Data
  _InsertRecordsToDataBase(int statusId, int uploadtoserver,
      {String dictationId}) async {
    try {
      final String formatted = formatter.format(now);
      int recordDbId = await DatabaseHelper.db.insertAudioRecords(
          PatientDictation(
              // dictationId: '$dictId',
              dictationId: dictationId,
              fileName:
                  '${widget.dictationTypeName}_${widget.patientFName}_${widget.caseNum}_${formatted}.mp4',
              patientFirstName: '${widget.patientFName ?? ''}',
              patientLastName: '${widget.patientLName ?? ''}',
              patientDOB: '${widget.patientDob ?? ''}',
              attachmentName:
                  '${widget.dictationTypeName}_${widget.patientFName ?? ''}_${widget.caseNum ?? ''}_${formatted ?? ''}.mp4',
              createdDate: '${DateTime.now() ?? ''}',
              memberId: int.parse(memberId),
              episodeId: widget.episodeId ?? '',
              appointmentId: widget.episodeAppointmentRequestId ?? '',
              dictationTypeId: widget.dictationTypeId,
              physicalFileName: _current?.path ?? '',
              statusId: statusId ?? '',
              displayFileName:
                  '${widget.dictationTypeName}_${widget.patientFName}_${widget.caseNum}_${formatted}',
              uploadedToServer: uploadtoserver ?? '',
              attachmentType: '.mp4'));
    } catch (e) {
      print(e.toString());
    }
  }
}
