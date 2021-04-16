import 'dart:convert';
import 'dart:io';
import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_constants.dart';
import 'package:YOURDRS_FlutterAPP/common/app_log_helper.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/external_dictation_attacment_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/practice.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/appointment_type.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/dictation.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/document_type.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/location_field_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/provider_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/photo_list.dart';
import 'package:YOURDRS_FlutterAPP/network/repo/local/preference/local_storage.dart';
import 'package:YOURDRS_FlutterAPP/network/services/dictation/external_attachment_dictation.dart';
import 'package:YOURDRS_FlutterAPP/ui/manual_dictaions/date_Valid.dart';
import 'package:YOURDRS_FlutterAPP/ui/manual_dictaions/manual_dictations.dart';
import 'package:YOURDRS_FlutterAPP/utils/route_generator.dart';
import 'package:YOURDRS_FlutterAPP/widget/buttons/mic_button.dart';
import 'package:YOURDRS_FlutterAPP/widget/buttons/raised_buttons.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/appointmenttype.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/documenttype.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/location_field.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/practice_field.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/provider_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:YOURDRS_FlutterAPP/helper/db_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubmitNewDictation extends StatefulWidget {
  @override
  _SubmitNewDictationState createState() => _SubmitNewDictationState();
}

class _SubmitNewDictationState extends State<SubmitNewDictation>
    with AutomaticKeepAliveClientMixin {
  final DateTime now = DateTime.now();
  final validationKey = GlobalKey<FormState>();
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _descreiption = TextEditingController();
  final _dateOfServiceController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  var statusCode;
  String _selectedLocationName,
      _selectedPracticeName,
      _selectedProviderName,
      _selectedPracticeId,
      _selectedLocationId,
      _selectedProvider,
      _selectedDocName,
      _selectedAppointmentName,
      currentDOB,
      currentDOS,
      path,
      fileName,
      filepath,
      resultInternet,
      memberId,
      id,
      idGallery,
      memeberRoleId,
      dictationId,
      episodeAppointmentRequestId,
      episodId,
      dateOfBirth,
      dateOfService,
      content,
      name,
      dicId;
  int _selectedDoc,
      _selectedAppointment,
      toggleVal,
      uploadedToServerTrue = 1,
      uploadedToServerFalse = 0,
      gIndex;
  File image, newImage;
  bool widgetVisible = false;
  bool visible = false;
  Directory directory;
  bool isSwitched = false;
  Map<String, String> paths;
  List<String> extensions;
  bool isLoadingPath = false;
  bool isMultiPick = false;
  FileType fileType;
  bool imageVisible = true;
  int imageIndex = 0;
  var imageName;
  String attachmentType = "jpg";
  bool isInternetAvailable = false;
  bool submitVisible = true;
  bool submitGVisible = false;
  final DateFormat formatter = DateFormat(AppStrings.dateFormat);
  List arrayOfImages = [];
  List memberPhotos = [];
  bool emergencyAddOn = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    check();
  }

  void check() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      setState(() {
        isInternetAvailable = true;
      });
    } else {
      setState(() {
        isInternetAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
//-----------------GestureDetector for shifting focus from input feilds (for dismissing keyboard after clicking outside the textinput feilds)
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Form(
            key: validationKey,
//------------------Scrollview for entire body
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
//------------------text for Practise
                  Text(
                    AppStrings.practice,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: CustomizedColors.accentColor,
                    ),
                  ),
                  SizedBox(height: 15),
//-------------Practise drop down
                  PracticeDropDown(
                    onTapOfPractice: (PracticeList pValue) {
                      setState(() {
                        _selectedPracticeId = '${pValue?.id}';
                        _selectedPracticeName = pValue.name;
                      });
                    },
                  ),
                  SizedBox(height: 15),
//-----------------text for provider
                  Text(
                    AppStrings.location,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: CustomizedColors.accentColor,
                    ),
                  ),
                  SizedBox(height: 15),

//--------------Location drop down
                  Locations(
                    onTapOfLocation: (LocationList value) async {
                      setState(() {
                        _selectedLocationId = '${value?.id}';
                      });
                      _selectedLocationName = value.name;
                    },
                    PracticeIdList: _selectedPracticeId,
                  ),

                  SizedBox(height: 15),
//------------------text for provider
                  Text(
                    AppStrings.treatingProvider,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: CustomizedColors.accentColor,
                    ),
                  ),
                  SizedBox(height: 15),

//-------------Provider drop down
                  ExternalProviderDropDown(
                    onTapOfProvider: (ProviderList value) async {
                      _selectedProvider = '${value?.providerId}';
                      _selectedProviderName = value.displayname;
                    },
                    PracticeLocationId: _selectedLocationId,
                  ),
                  SizedBox(height: 15),
//-------------------label text first name
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      AppStrings.fName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CustomizedColors.accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

//----------------TextFeild for First Name
                  Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: TextFormField(
                      inputFormatters: [
                        WhitelistingTextInputFormatter(
                            RegExp(AppConstants.nameRegExp))
                      ],
                      validator: validateInput,
                      controller: _fName,
                      decoration: InputDecoration(
                        hintText: AppStrings.fName,
                        contentPadding: EdgeInsets.all(20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0)),
                      ),
                    ),
                  ),
//-----------------label text last name
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      AppStrings.lName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CustomizedColors.accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

//--------------TextFeild last name
                  Container(
                    width: MediaQuery.of(context).size.width * 95,
                    child: TextFormField(
                      inputFormatters: [
                        WhitelistingTextInputFormatter(
                            RegExp(AppConstants.nameRegExp))
                      ],
                      validator: validateInput,
                      controller: _lName,
                      decoration: InputDecoration(
                        hintText: AppStrings.lName,
                        contentPadding: EdgeInsets.all(20),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: CustomizedColors.accentColor),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),
//----------------lable text date of birth
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      AppStrings.dobDropDownText,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CustomizedColors.accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
//-----------------------date of Birth Picker
                  Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(AppConstants.dateNumRegExp)),
                        LengthLimitingTextInputFormatter(10),
                        DateValidFormatter(),
                      ],
                      validator: validateInput,
                      controller: _dateOfBirthController,
                      minLines: 2,
                      maxLines: 10,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: AppStrings.dateFormatLableHintText,
                        labelText: AppStrings.dateFormatLableHintText,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: Icon(
                              Icons.calendar_today_sharp,
                              color: CustomizedColors.accentColor,
                            ),
                            onPressed: () async {
                              DateTime dd = DateTime(1900);
                              dd = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now());
                              final DateFormat formats = DateFormat(
                                  AppStrings.dateFormatForDatePicker);
                              dateOfBirth = formats.format(dd);
                              _dateOfBirthController.text =
                                  dateOfBirth.toString();
                            },
                          ),
                        ),
                        contentPadding: EdgeInsets.all(20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0)),
                      ),
                    ),
                  ),
//------------------lable text date of service
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      AppStrings.dosDropDownText,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CustomizedColors.accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
//---------------date of Service Picker
                  Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(AppConstants.dateNumRegExp)),
                        LengthLimitingTextInputFormatter(10),
                        DateValidFormatter(),
                      ],
                      validator: validateInput,
                      controller: _dateOfServiceController,
                      minLines: 2,
                      maxLines: 10,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: AppStrings.dateFormatLableHintText,
                        labelText: AppStrings.dateFormatLableHintText,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: Icon(
                              Icons.calendar_today_sharp,
                              color: CustomizedColors.accentColor,
                            ),
                            onPressed: () async {
                              DateTime d = DateTime(1900);

                              d = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(2100));
                              final DateFormat formats = DateFormat(
                                  AppStrings.dateFormatForDatePicker);
                              dateOfService = formats.format(d);
                              _dateOfServiceController.text =
                                  dateOfService.toString();
                            },
                          ),
                        ),
                        contentPadding: EdgeInsets.all(20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0)),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),
                  Text(
                    AppStrings.documentType,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: CustomizedColors.accentColor,
                    ),
                  ),
                  SizedBox(height: 15),
                  DocumentDropDown(
                    onTapDocument: (ExternalDocumentTypesList value) async {
                      _selectedDoc = value.id;

                      _selectedDocName = value.externalDocumentTypeName;
                    },
                  ),

                  SizedBox(height: 15),
//----------------lable text for appointment type
                  Text(
                    AppStrings.appointmentType,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: CustomizedColors.accentColor,
                    ),
                  ),
                  SizedBox(height: 15),
//-----------------Appointment type Dropdown
                  AppointmentDropDown(
                    onTapOfAppointment: (AppointmentTypeList value) async {
                      _selectedAppointment = value.id;
                      _selectedAppointmentName = value.name;
                    },
                  ),
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      AppStrings.emergencyText,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CustomizedColors.accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
//-----------------Toggle button

                  Center(
                    child: ToggleSwitch(
                      minWidth: 160.0,
                      minHeight: 55,
                      cornerRadius: 10.0,
                      activeBgColor: CustomizedColors.accentColor,
                      activeFgColor: CustomizedColors.whiteColor,
                      inactiveBgColor: Colors.grey[300],
                      inactiveFgColor: Colors.grey[700],
                      labels: [AppStrings.toggleYES, AppStrings.toggleNO],
                      icons: [Icons.check_circle, Icons.cancel_rounded],
                      onToggle: (toggleIndex) {
                        if (toggleIndex == 0) {
                          toggleVal = 1;
                        } else if (toggleIndex == 1) {
                          toggleVal = 0;
                        } else {
                          return null;
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      AppStrings.descp,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CustomizedColors.accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

//----------------TextFeild for description
                  Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: TextFormField(
                      validator: validateInput,
                      controller: _descreiption,
                      minLines: 2,
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: AppStrings.descp,
                        contentPadding: EdgeInsets.all(20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0)),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
//----------------visibility when selecting images
                  Visibility(
                    visible: widgetVisible,
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Wrap(children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: CustomizedColors.homeSubtitleColor,
                                ),
                              ),
                              height: 100,
                              width: MediaQuery.of(context).size.width * 0.95,
                              child: Center(
                                  child: Stack(children: [
                                image == null
                                    ? Text(AppStrings.noImageSelected)
                                    : Image.file(
                                        image,
                                        fit: BoxFit.contain,
                                      ),
                                Positioned(
                                  right: -10,
                                  top: -5,
                                  child: Visibility(
                                    visible: imageVisible,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: CustomizedColors
                                            .signInButtonTextColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          image = null;
                                          imageVisible = false;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ])),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
//-----------------visibility
                  Visibility(
                    visible: visible,
                    child: Column(
                      children: [
                        Builder(
                          builder: (BuildContext context) => isLoadingPath
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: const CircularProgressIndicator())
                              : filepath != null ||
                                      (paths != null &&
                                          paths.values != null &&
                                          paths.values.isNotEmpty)
                                  ? Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: CustomizedColors
                                              .homeSubtitleColor,
                                        ),
                                      ),
                                      height: 100,
                                      width: MediaQuery.of(context).size.width *
                                          0.95,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            paths != null && paths.isNotEmpty
                                                ? paths.length
                                                : 1,
                                        itemBuilder:
                                            (BuildContext context, index) {
                                          final bool isMultiPath =
                                              paths != null && paths.isNotEmpty;
                                          final filePath1 = isMultiPath
                                              ? paths.values
                                                  .toList()[index]
                                                  .toString()
                                              : filepath;

                                          return Container(
                                            color: CustomizedColors
                                                .homeSubtitleColor,
                                            margin: const EdgeInsets.all(8),
                                            child: Stack(children: [
                                              filePath1 != null
                                                  ? Image.file(
                                                      File(filePath1),
                                                      fit: BoxFit.contain,
                                                    )
                                                  : Container(),
                                              Positioned(
                                                right: -10,
                                                top: -5,
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.close,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      var filename = basename(
                                                          paths.values
                                                              .toList()[index]);

                                                      paths.remove(filename);
                                                    });
                                                  },
                                                ),
                                              ),
                                            ]),
                                          );
                                        },
                                        separatorBuilder:
                                            (BuildContext context, int index) =>
                                                Divider(),
                                      ),
                                    )
                                  : Container(),
                        ),
                      ],
                    ),
                  ),

//---------------cupertino Action sheet
                  RaisedButton(
                    color: CustomizedColors.whiteColor,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: CustomizedColors.accentColor,
                            size: 45,
                          ),
                          Text(
                            AppStrings.addImgandtakePic,
                            style:
                                TextStyle(color: CustomizedColors.accentColor),
                          ),
                        ],
                      ),
                    ),
                    onPressed: () => _show(context),
                  ),
                  SizedBox(height: 15),
//-----------------raised Button for Submit with Dictation
                  RaisedButtonCustom(
                    textColor: CustomizedColors.whiteColor,
                    onPressed: () {
//------------------If an of the feilds are null then recording is not possible
                      if (_selectedPracticeName == null ||
                          _selectedPracticeId == null ||
                          _selectedLocationName == null ||
                          _selectedLocationId == null ||
                          _selectedProvider == null ||
                          _fName.text == null ||
                          _lName.text == null ||
                          _dateOfBirthController.text == null ||
                          _dateOfServiceController.text == null ||
                          _selectedDoc == null ||
                          _selectedAppointment == null ||
                          _descreiption.text == null) {
                        Fluttertoast.showToast(
                            msg: AppStrings.feildsCannotBeEmpty,
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: CustomizedColors.activeRedColor,
                            textColor: CustomizedColors.textColor,
                            fontSize: 16.0);
                      } else {
//---------Dialog box for Recorder
                        showDialog(
                          context: context,
                          builder: (ctxt) => AlertDialog(
                            title: Center(
                                child: Text(AppStrings.alertDialogDictation)),
                            content: Container(
                              height: 165,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
//-----------------material button for audio Recorder
                                  MicButtonForManualDictation(
                                    practiceName: _selectedPracticeName,
                                    practiceId: int.parse(_selectedPracticeId),
                                    locationName: _selectedLocationName,
                                    locationId: int.parse(_selectedLocationId),
                                    providerName: _selectedProviderName,
                                    providerId: int.parse(_selectedProvider),
                                    patientFName: _fName.text,
                                    patientLName: _lName.text,
                                    patientDob: _dateOfBirthController.text,
                                    patientDos: _dateOfServiceController.text,
                                    docType: _selectedDoc,
                                    appointmentType: _selectedAppointment,
                                    emergency: toggleVal,
                                    descp: _descreiption.text,
                                    attachmentname: _fName.text +
                                            '_' +
                                            basename('$image') ??
                                        null,
                                    physicalFileName: image?.path ?? null,
                                    fileName: _fName.text +
                                            '_' +
                                            basename('$image') ??
                                        null,
                                    arrayOfImages:
                                        paths?.values?.toList() ?? null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(11),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
//-----------------material button inside dialog box
                                        Container(
                                          height: 45,
                                          width: 98,
                                          child: MaterialButton(
                                            child: Text(
                                              AppStrings.dialogCancel,
                                              style: TextStyle(
                                                  color: CustomizedColors
                                                      .whiteColor),
                                            ),
                                            color: CustomizedColors
                                                .dialogCancelButton,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15)),
                                            elevation: 15,
                                            onPressed: () {
                                              Navigator.pop(ctxt);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    text: AppStrings.submitwithDictButtonText,
                    buttonColor: CustomizedColors.accentColor,
                  ),

//-------------submit with gallery images
                  Visibility(
                    visible: submitGVisible,
                    child: Column(
                      children: [
                        SizedBox(height: 15),
                        RaisedButtonCustom(
                          textColor: CustomizedColors.buttonTitleColor,
                          buttonColor: CustomizedColors.raisedBtnColor,
                          text: AppStrings.submitButtonText,
                          onPressed: () async {
                            try {
                              check();
                              if (isInternetAvailable == true) {
                                if (validationKey.currentState.validate()) {
                                  Scaffold.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            backgroundColor:
                                                CustomizedColors.whiteColor,
                                            valueColor: AlwaysStoppedAnimation(
                                                CustomizedColors.accentColor),
                                          ),
                                          SizedBox(
                                            width: 15,
                                          ),
                                          Text(AppStrings.submitingData),
                                        ],
                                      ),
                                    ),
                                  );
////-----------------------------post data to API the with internet

                                  await saveGalleryImageToServer();
                                  memberPhotos.clear();

////------------------------save data to the local table with response from API

                                  await RouteGenerator.navigatorKey.currentState
                                      .pushReplacementNamed(
                                          ManualDictations.routeName);
                                }
                              } else {
////------------------------save data to the local table when no internet
                                Scaffold.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          backgroundColor:
                                              CustomizedColors.whiteColor,
                                          valueColor: AlwaysStoppedAnimation(
                                              CustomizedColors.accentColor),
                                        ),
                                        SizedBox(
                                          width: 15,
                                        ),
                                        Text(AppStrings.submitingData),
                                      ],
                                    ),
                                  ),
                                );

                                await saveGalleryImagesToDBOffline();
                              }
                              setState(() {
                                widgetVisible = false;
                                visible = false;
                              });
                            } on Exception catch (e) {
                              print(e.toString());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
//------Submitting camera images
                  Visibility(
                    visible: submitVisible,
                    child: Column(
                      children: [
                        SizedBox(height: 15),
                        RaisedButtonCustom(
                          textColor: CustomizedColors.buttonTitleColor,
                          buttonColor: CustomizedColors.raisedBtnColor,
                          onPressed: () async {
                            try {
                              check();
                              if (isInternetAvailable == true) {
                                if (validationKey.currentState.validate()) {
                                  Scaffold.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            backgroundColor:
                                                CustomizedColors.whiteColor,
                                            valueColor: AlwaysStoppedAnimation(
                                                CustomizedColors.accentColor),
                                          ),
                                          SizedBox(
                                            width: 15,
                                          ),
                                          Text(AppStrings.submitingData),
                                        ],
                                      ),
                                    ),
                                  );
////-----------------------------post data to API the with internet

                                  await saveAttachmentDictation();

                                  print(
                                      '---------------------------->>>>>$statusCode<<<<<-----------------------------');

////------------------------save data to the local table with response from API
                                  await saveCameraImagesToDbOnline();
                                  memberPhotos.clear();

                                  await RouteGenerator.navigatorKey.currentState
                                      .pushReplacementNamed(
                                          ManualDictations.routeName);
                                }
                              } else {
////------------------------save data to the local table when no internet
                                Scaffold.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          backgroundColor:
                                              CustomizedColors.whiteColor,
                                          valueColor: AlwaysStoppedAnimation(
                                              CustomizedColors.accentColor),
                                        ),
                                        SizedBox(
                                          width: 15,
                                        ),
                                        Text(AppStrings.submitingData),
                                      ],
                                    ),
                                  ),
                                );

                                await saveCameraImagesToDbOffline();
                              }
                              setState(() {
                                widgetVisible = false;
                                visible = false;
                              });
                            } on Exception catch (e) {
                              print(e.toString());
                            }
                          },
                          text: AppStrings.submitButtonText,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
//----------------raised Button for clearing all the textediting controllers
                  RaisedButtonCustom(
                    textColor: CustomizedColors.buttonTitleColor,
                    buttonColor: CustomizedColors.raisedBtnColor,
                    onPressed: () {
                      RouteGenerator.navigatorKey.currentState
                          .pushReplacementNamed(ManualDictations.routeName);
                    },
                    text: AppStrings.clearAll,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
//------------------->>>>various methods<<<<---------------------

// ignore: missing_return
  String validateInput(String value) {
    try {
      if (value.length == 0) {
        return 'This is required';
      } else {
        return null;
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  }

//---------------to open cupertino action sheet
  _show(BuildContext ctx) {
    showCupertinoModalPopup(
      context: ctx,
      builder: (ctctc) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
                onPressed: () {
                  openCamera();
                  Navigator.pop(ctctc);
                },
                child: Text(AppStrings.camera)),
            CupertinoActionSheetAction(
                onPressed: () {
                  openGallery();
                  Navigator.pop(ctctc);
                },
                child: Text(AppStrings.PhotoGallery)),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text(AppStrings.cancel),
            //isDefaultAction: true,
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctctc);
            },
          )),
    );
  }

//-----------------to open the camera in phone
  Future openCamera() async {
    image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 100);
    String path = image.path;
    createFileName(path);
    setState(() {
      image;
      widgetVisible = true;
      visible = false;
      submitVisible = true;
      submitGVisible = false;
    });
  }

//---------------------to open the gallery in phone
  Future openGallery() async {
    setState(() => isLoadingPath = true);
    try {
      if (!isMultiPick) {
        filepath = null;
        paths = await FilePicker.getMultiFilePath(
            type: fileType != null ? fileType : FileType.image,
            allowedExtensions: extensions,
            allowCompression: true);
        arrayOfImages.add(paths);

        ;
      } else {
        filepath = await FilePicker.getFilePath(
            type: fileType != null ? fileType : FileType.image,
            allowedExtensions: extensions,
            allowCompression: true);
        arrayOfImages.add(filepath);

        paths = null;
      }
    } on PlatformException catch (e) {
      print("file not found" + e.toString());
    }
    try {
      if (!mounted) return;
      setState(() {
        isLoadingPath = false;
        fileName = filepath != null
            ? filepath.split('/').last
            : paths != null
                ? paths.keys.toString()
                : '...';
        visible = true;
        widgetVisible = false;
        submitGVisible = true;
        submitVisible = false;
      });
    } on PlatformException catch (e) {
      print("file not found" + e.toString());
    }
  }

//-----------------saving gallery images to app image folder

  saveGalleryImageToFolder(String patientName, String dateFormat) async {
    for (int i = 0; i < paths.keys.toList().length; i++) {
      var galleryImage = paths.values.toList();

      final Directory directory = await getExternalStorageDirectory();
      String path = '${directory.path}/${AppStrings.folderName}';
      final myImgDir = await Directory(path).create(recursive: true);
      newImage = await File((galleryImage[i])).copy(
        '${myImgDir.path}/${patientName + dateFormat + basename((galleryImage[i]))}',
      );
    }
  }

//-----------file name for images
  Future<String> createFileName(String mockName) async {
    String fileName1;
    final DateFormat formatter = DateFormat(AppStrings.dateFormat);
    final String formatted = formatter.format(now);

    try {
      fileName1 = _fName.text + basename(mockName).replaceAll(".", "");
      if (fileName1.length > _fName.text.length) {
        fileName1 = fileName1.substring(0, _fName.text.length);
        final Directory directory = await getExternalStorageDirectory();
        path = '${directory.path}/${AppStrings.folderName}';
        final myImgDir = await Directory(path).create(recursive: true);
        newImage = await image.copy(
            '${myImgDir.path}/${basename(fileName1 + '${formatted}' + AppStrings.imageFormat)}');
        setState(() {
          newImage;
        });
      }
    } catch (e, s) {
      fileName1 = "";
      AppLogHelper.printLogs(e, s);
    }

    return "${formatted}" + fileName1 + ".jpeg";
  }

//---------function for posting the details to the api

  saveAttachmentDictation() async {
    try {
      if (toggleVal == 0) {
        emergencyAddOn = false;
      } else {
        emergencyAddOn = true;
      }
      final String formatted = formatter.format(now);
      final bytes = File(image.path).readAsBytesSync();
      String convertedImg = base64Encode(bytes);
      name = "${_fName.text}_${formatted}_${basename('${image.path}')}";

      memberPhotos.add({
        "header": {
          "status": "string",
          "statusCode": "string",
          "statusMessage": "string"
        },
        "content": convertedImg,
        "name": name,
        "attachmentType": "jpg"
      });

      ExternalDictationAttachment apiAttachmentPostServices =
          ExternalDictationAttachment();
      SaveExternalDictationOrAttachment saveDictationAttachments =
          await apiAttachmentPostServices.postApiServiceMethod(
              int.parse(_selectedPracticeId),
              int.parse(_selectedLocationId),
              int.parse(_selectedProvider),
              _fName.text,
              _lName.text,
              _dateOfBirthController.text,
              _dateOfServiceController.text,
              memberId,
              _selectedDoc,
              _selectedAppointment,
              emergencyAddOn,
              _descreiption.text,
              null, //attachmentTypeMp4
              null, //attachmentContentMp4
              null, //attachmentNameMp4
              memberPhotos);
      dicId = saveDictationAttachments.dictationId.toString();

      statusCode = saveDictationAttachments?.header?.statusCode;
    } catch (e) {
      print('SaveAttachmentDictation exception ${e.toString()}');
    }
  }

//--------------shared Prefarance load data
  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      memberId = (prefs.getString(Keys.memberId) ?? '');
      id = (prefs.getString(Keys.iD) ?? '');
      dictationId = (prefs.getString(Keys.dictationId) ?? '');
      episodId = (prefs.getString(Keys.episodeId) ?? '');
      episodeAppointmentRequestId =
          (prefs.getString(Keys.episodeAppointmentRequestId) ?? '');
      memeberRoleId = (prefs.getString(Keys.memberRoleId) ?? '');
    });
  }

//------------------------insert camera images to the db when internet is there
  saveCameraImagesToDbOnline() async {
    await DatabaseHelper.db.insertAudioRecords(
      PatientDictation(
          dictationId: dicId ?? null,
          attachmentType: null,
          locationName: _selectedLocationName ?? "",
          locationId: int.parse(_selectedLocationId) ?? "",
          practiceName: _selectedPracticeName ?? "",
          practiceId: int.parse(_selectedPracticeId) ?? "",
          providerName: _selectedProviderName ?? "",
          providerId: int.parse(_selectedProvider) ?? "",
          patientFirstName: _fName.text ?? "",
          patientLastName: _lName.text ?? "",
          patientDOB: _dateOfBirthController.text ?? "",
          dos: _dateOfServiceController.text ?? "",
          isEmergencyAddOn: toggleVal ?? "",
          externalDocumentTypeId: _selectedDoc ?? "",
          appointmentTypeId: _selectedAppointment ?? "",
          description: _descreiption.text ?? "",
          memberId: int.parse(memberId) ?? "",
          createdDate: '${DateTime.now()}',
          statusId: null,
          uploadedToServer: uploadedToServerTrue),
    );

    final String formatted = formatter.format(now);
    DatabaseHelper.db.insertPhotoList(PhotoList(
        dictationLocalId: int.parse(dicId) ?? null,
        attachmentname: '${_fName.text ?? ''}' +
            "_" +
            '${formatted}' +
            '_' +
            basename('${image}'),
        createddate: '${DateTime.now()}',
        fileName: '${_fName.text ?? ''}' +
            "_" +
            '${formatted}' +
            '_' +
            basenameWithoutExtension('${image}'),
        attachmenttype: AppStrings.imageFormat,
        physicalfilename: '${image.path}'));
  }

//--------------insert camera images to the db when internet is not there
  saveCameraImagesToDbOffline() async {
    await DatabaseHelper.db.insertAudioRecords(
      PatientDictation(
        dictationId: null,
        attachmentType: null,
        locationName: _selectedLocationName ?? "",
        locationId: int.parse(_selectedLocationId) ?? "",
        practiceName: _selectedPracticeName ?? "",
        practiceId: int.parse(_selectedPracticeId) ?? "",
        providerName: _selectedProviderName ?? "",
        providerId: int.parse(_selectedProvider) ?? "",
        patientFirstName: _fName.text ?? "",
        patientLastName: _lName.text ?? "",
        patientDOB: _dateOfBirthController.text ?? "",
        dos: _dateOfServiceController.text ?? "",
        isEmergencyAddOn: toggleVal ?? "",
        externalDocumentTypeId: _selectedDoc ?? "",
        appointmentTypeId: _selectedAppointment ?? "",
        description: _descreiption.text ?? "",
        memberId: int.parse(memberId) ?? "",
        createdDate: '${DateTime.now()}',
        statusId: null,
        uploadedToServer: uploadedToServerFalse,
      ),
    );

    List dictId = await DatabaseHelper.db.getDectionId();
    int id;
    id = dictId[dictId.length - 1].id;

    final String formatted = formatter.format(now);
    await DatabaseHelper.db.insertPhotoList(PhotoList(
        dictationLocalId: id ?? null,
        attachmentname: '${_fName.text ?? ''}' +
            "_" +
            '${formatted}' +
            '_' +
            basename('${image}'),
        createddate: '${DateTime.now()}',
        fileName: '${_fName.text ?? ''}' +
            "_" +
            '${formatted}' +
            '_' +
            basenameWithoutExtension('${image}'),
        attachmenttype: AppStrings.imageFormat,
        physicalfilename: '${image.path}'));
  }

//-------------------insert gallery images to the db when internet is there
  saveGalleryImagesToDbOnline() async {
    final String formatted = formatter.format(now);
    try {
      if (toggleVal == 0) {
        emergencyAddOn = false;
      } else {
        emergencyAddOn = true;
      }
      for (int i = 0; i < paths.keys.toList().length; i++) {
        await saveGalleryImageToFolder('${_fName.text ?? ''}', '${formatted}');

        await DatabaseHelper.db.insertPhotoList(PhotoList(
            dictationLocalId: int.parse(dicId),
            attachmentname: basename('${(paths.keys.toList()[i])}'),
            fileName: '${_fName.text ?? ''}_ ${formatted}',
            createddate: '${DateTime.now()}',
            attachmenttype: AppStrings.imageFormat,
            physicalfilename: '${paths.values.toList()[i]}'));
      }
      await DatabaseHelper.db.insertAudioRecords(
        PatientDictation(
          attachmentType: null,
          dictationId: dicId,
          locationName: _selectedLocationName ?? "",
          locationId: int.parse(_selectedLocationId) ?? "",
          practiceName: _selectedPracticeName ?? "",
          practiceId: int.parse(_selectedPracticeId) ?? "",
          providerName: _selectedProviderName ?? "",
          providerId: int.parse(_selectedProvider) ?? "",
          patientFirstName: _fName.text ?? "",
          patientLastName: _lName.text ?? "",
          patientDOB: _dateOfBirthController.text ?? "",
          dos: _dateOfServiceController.text ?? "",
          isEmergencyAddOn: emergencyAddOn ?? "",
          externalDocumentTypeId: _selectedDoc ?? "",
          appointmentTypeId: _selectedAppointment ?? "",
          description: _descreiption.text ?? "",
          memberId: int.parse(memberId) ?? "",
          createdDate: '${DateTime.now()}',
          uploadedToServer: uploadedToServerTrue,
          statusId: null,
        ),
      );
    }
    on PlatformException catch (e) {
      print("Exception handling" + e.toString());
    }
  }

//----------------insert gallery images to DB when internet is not there
  saveGalleryImagesToDBOffline() async {
    final String formatted = formatter.format(now);
    try {
      for (int i = 0; i < paths.keys.toList().length; i++) {
        await saveGalleryImageToFolder('${_fName.text ?? ''}', '${formatted}');
        List listId = await DatabaseHelper.db.getGalleryId();
        idGallery = listId[listId.length - 1].id;

        await DatabaseHelper.db.insertPhotoList(PhotoList(
            dictationLocalId: int.parse(idGallery),
            attachmentname: basename('${(paths.keys.toList()[i])}'),
            fileName: '${_fName.text ?? ''}_ ${formatted}',
            createddate: '${DateTime.now()}',
            attachmenttype: AppStrings.imageFormat,
            physicalfilename: '${paths.values.toList()[i]}'));
      }
      await DatabaseHelper.db.insertAudioRecords(
        PatientDictation(
          attachmentType: null,
          dictationId: null,
          locationName: _selectedLocationName ?? "",
          locationId: int.parse(_selectedLocationId) ?? "",
          practiceName: _selectedPracticeName ?? "",
          practiceId: int.parse(_selectedPracticeId) ?? "",
          providerName: _selectedProviderName ?? "",
          providerId: int.parse(_selectedProvider) ?? "",
          patientFirstName: _fName.text ?? "",
          patientLastName: _lName.text ?? "",
          patientDOB: _dateOfBirthController.text ?? "",
          dos: _dateOfServiceController.text ?? "",
          isEmergencyAddOn: toggleVal ?? "",
          externalDocumentTypeId: _selectedDoc ?? "",
          appointmentTypeId: _selectedAppointment ?? "",
          description: _descreiption.text ?? "",
          memberId: int.parse(memberId) ?? "",
          createdDate: '${DateTime.now()}',
          uploadedToServer: uploadedToServerTrue,
          statusId: null,
        ),
      );
    } on PlatformException catch (e) {
      print("Exception handling" + e.toString());
    }
  }

  saveGalleryImageToServer() async {
    final String formatted = formatter.format(now);

    for (var i = 0; i < paths.keys.toList().length; i++) {
      final bytes = File('${paths.values.toList()[i]}').readAsBytesSync();
      String images = base64Encode(bytes);
      name =
          '${_fName.text + '_' + _lName.text}_${formatted}_${basename(paths.keys.toList()[i])}';

      memberPhotos.add({
        "header": {
          "status": "string",
          "statusCode": "string",
          "statusMessage": "string"
        },
        "content": images,
        "name": name,
        "attachmentType": "jpg"
      });
    }

    try {
      if (toggleVal == 0) {
        emergencyAddOn = false;
      } else {
        emergencyAddOn = true;
      }

      ExternalDictationAttachment apiAttachmentPostServices =
          ExternalDictationAttachment();
      SaveExternalDictationOrAttachment saveDictationAttachments =
          await apiAttachmentPostServices.postApiServiceMethod(
              int.parse(_selectedPracticeId) ?? null,
              int.parse(_selectedLocationId) ?? null,
              int.parse(_selectedProvider) ?? null,
              _fName.text,
              _lName.text,
              _dateOfBirthController.text,
              _dateOfServiceController.text,
              memberId,
              _selectedDoc,
              _selectedAppointment,
              emergencyAddOn,
              _descreiption.text,
              null, //attachmentTypeMp4
              null, //attachmentContentMp4
              null, //attachmentNameMp4
              memberPhotos);
      dicId = saveDictationAttachments.dictationId.toString();

      statusCode = saveDictationAttachments?.header?.statusCode;
      print("status $statusCode");
    } catch (e) {}
// }
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
