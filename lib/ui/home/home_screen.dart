import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:YOURDRS_FlutterAPP/blocs/home/patient_bloc.dart';
import 'package:YOURDRS_FlutterAPP/blocs/home/patient_bloc_event.dart';
import 'package:YOURDRS_FlutterAPP/blocs/home/patient_bloc_state.dart';
import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_constants.dart';
import 'package:YOURDRS_FlutterAPP/common/app_icons.dart';
import 'package:YOURDRS_FlutterAPP/common/app_loader.dart';
import 'package:YOURDRS_FlutterAPP/common/app_pop_menu.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/common/app_text.dart';
import 'package:YOURDRS_FlutterAPP/common/app_toast_message.dart';
import 'package:YOURDRS_FlutterAPP/network/models/home/dictation.dart';
import 'package:YOURDRS_FlutterAPP/network/models/home/provider.dart';
import 'package:YOURDRS_FlutterAPP/network/models/home/schedule.dart';
import 'package:YOURDRS_FlutterAPP/network/repo/local/preference/local_storage.dart';
import 'package:YOURDRS_FlutterAPP/ui/home/drawer.dart';
import 'package:YOURDRS_FlutterAPP/ui/home/grouping_seperator.dart';
import 'package:YOURDRS_FlutterAPP/utils/cached_image.dart';
import 'package:YOURDRS_FlutterAPP/widget/date_range_picker.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/dictation.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/location.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/provider.dart';
import 'package:dio/dio.dart';
import 'package:YOURDRS_FlutterAPP/widget/input_fields/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:YOURDRS_FlutterAPP/ui/home/patient_details.dart';
import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grouped_list/grouped_list.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class PatientAppointment extends StatefulWidget {
  static const String routeName = '/HomeScreen';
  @override
  _PatientAppointmentState createState() => _PatientAppointmentState();
}

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer _timer;

  Debouncer({this.milliseconds});
  run(VoidCallback action) {
    try {
      if (null != _timer) {
        _timer.cancel();
      }
    } catch (e) {
      throw Exception(AppStrings.errortext);
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class _PatientAppointmentState extends State<PatientAppointment> {
  final _debouncer = Debouncer(milliseconds: 500);
  var displayName = "";
  AppToast appToast = AppToast();
  GlobalKey _key = GlobalKey();
  Map<String, dynamic> appointment;
//var for selected Provider Id ,Dictation Id,Location Id
  var _currentSelectedProviderId;
  var _currentSelectedLocationId;
  var _currentSelectedDictationId;
// list of Patients
  List<ScheduleList> patients = List();
  List<ScheduleList> filteredPatients = List();
// Declared Variables for start Date and end Date
  String startDate;
  String endDate;
//booean property for visibility for Date Picker
  bool datePicker = true;
  bool dateRange = false;
  bool isShowToast = false;
  String codeDialog;
  String valueText;
  var selectedDate;

  ///counting for each practice location using hashmap
  HashMap<String, int> practiceCountMap = HashMap();
  HashMap<String, String> locationName = HashMap();
  bool isLoadingVertical = false;
  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _searchFilterController = TextEditingController();
//Infinite Scroll Pagination related code//
  var _scrollController = ScrollController();
  double maxScroll, currentScroll;
  int page;
  CancelToken cancelToken = CancelToken();
  var profilePic = "";
  int initialValue = 1;
  @override
  void initState() {
    super.initState();
    page = 1;
    BlocProvider.of<PatientBloc>(context).add(GetSchedulePatientsList(
        keyword1: null,
        providerId: null,
        locationId: null,
        dictationId: null,
        startDate: null,
        endDate: null,
        pageKey: page));
    _loadData();
    Future.delayed(Duration(milliseconds: 500), () {
      _controller?.animateToDate(DateTime.now().subtract(Duration(days: 3)));
    });
  }

  bool init = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    try {
      if (maxScroll > 0 && currentScroll > 0 && maxScroll == currentScroll) {
        page = page + 1;
        BlocProvider.of<PatientBloc>(context).add(GetSchedulePatientsList(
            keyword1: selectedDate,
            providerId: _currentSelectedProviderId,
            locationId: _currentSelectedLocationId,
            dictationId: _currentSelectedDictationId,
            startDate: startDate,
            endDate: endDate,
            pageKey: page));
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

//dispose methods//
  @override
  void dispose() {
    _scrollController.dispose();
    cancelToken.cancel(AppStrings.canceltxt);
    super.dispose();
  }

  DatePickerController _controller = DatePickerController();
  DateTime _selectedValue = DateTime.now();
  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      displayName = (prefs.getString(Keys.displayName) ?? '');
      profilePic = (prefs.getString(Keys.displayPic) ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: CustomizedColors.primaryBgColor,
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      appBar: AppBar(
          elevation: 0,
          backgroundColor: CustomizedColors
              .primaryBgColor, //CustomizedColors.blueAppBarColor,
         // foregroundColor: Colors.black87,
          iconTheme: IconThemeData(color: Colors.black87),
          title: Row(
            children: [
              profilePic != null && profilePic != ""
                  ? CachedImage(
                      profilePic,
                      isRound: true,
                      radius: 40.0,
                    )
                  : Image.asset(AppImages.defaultImg),
              SizedBox(
                width: 10,
              ),
              Text(
                displayName ?? "",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14.0,fontFamily: AppFonts.regular,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: <Widget>[
            // action button
            IconButton(
              icon: Icon(
                Icons.filter_alt,
                color: Colors.black87,
              ),
              iconSize: 30.0,
              onPressed: () {
                _currentSelectedProviderId = null;
                _currentSelectedDictationId = null;
                _currentSelectedLocationId = null;
                _textFieldController.clear();
                _filterDialog(context);
              },
            ),
            // action button
          ]),
      drawer: DrawerScreen(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 40,
                color: CustomizedColors
                    .primaryBgColor, //CustomizedColors.blueAppBarColor,
              ),
              Padding(
                padding: EdgeInsets.all(15),
                child: PatientSerach(
                  width: 250,
                  height: 60,
                  controller: _textFieldController,
                  onChanged: (string) {
                    _debouncer.run(() {
                      BlocProvider.of<PatientBloc>(context)
                          .add(SearchPatientEvent(keyword: string));
                    });
                  },
                ),
              ),
            ],
          ),
          Visibility(
            visible: datePicker,
            child: Container(
              child: DatePicker(
                DateTime.now().subtract(Duration(days: 365)),
                width: width < 600 ? 50.0 : 120.0,
                height: 80,
                controller: _controller,
                initialSelectedDate: DateTime.now(),
                selectionColor: CustomizedColors.primaryColor,
                selectedTextColor: CustomizedColors.textColor,
                dayTextStyle:
                    TextStyle(fontSize: 12.0, fontFamily: AppFonts.regular),
                dateTextStyle:
                    TextStyle(fontSize: 12.0, fontFamily: AppFonts.regular),
                monthTextStyle:
                    TextStyle(fontSize: 12.0, fontFamily: AppFonts.regular),
                onDateChange: (date) {
                  // New date selected
                  setState(() {
                    _selectedValue = date;
                    selectedDate = AppConstants.parseDate(
                        -1, AppConstants.MMDDYYYY,
                        dateTime: _selectedValue);
                    page = 1;
                    // getSelectedDateAppointments();
                    BlocProvider.of<PatientBloc>(context).add(
                        GetSchedulePatientsList(
                            keyword1: selectedDate,
                            providerId: null,
                            locationId: null,
                            dictationId: null,
                            pageKey: page));
                  });
                },
              ),
            ),
          ),
          Visibility(
            visible: dateRange,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.daterange,
                      style: TextStyle(
                        color: CustomizedColors.buttonTitleColor,fontFamily: AppFonts.regular,
                        fontSize: 14.0,
                      )),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
                    Text(
                      '${AppConstants.parseDatePattern(startDate, AppConstants.MMMddyyyy)}' ??
                          "", style: TextStyle(color: CustomizedColors.buttonTitleColor,
                        fontSize: 14.0,fontFamily: AppFonts.regular
                      ),
                    ),
                    Text('-', style: TextStyle(color: CustomizedColors.buttonTitleColor,
                        fontSize: 14.0,fontFamily: AppFonts.regular
                      ),
                    ),
                    Text('${AppConstants.parseDatePattern(endDate, AppConstants.MMMddyyyy)}' ??
                            "", style: TextStyle(color: CustomizedColors.buttonTitleColor,
                          fontSize: 14.0,fontFamily: AppFonts.regular
                        )
                    )
                  ]),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Expanded(child: patientAppointmentCard())
        ],
      ),
      floatingActionButton: Container(
        padding: EdgeInsets.only(right: 10.0),
        child: Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
              backgroundColor: CustomizedColors.blueAppBarColor,
              onPressed: () {},
              tooltip: AppStrings.actiontxt,
              child: Pop(
                initialValue: 1,
              )),
        ),
      ),
    );
  }

// patient Appointment card related code//
  Widget patientAppointmentCard() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BlocBuilder<PatientBloc, PatientAppointmentBlocState>(
                builder: (context, state) {
              try {
                if (state.isLoading &&
                    (state.patients == null || state.patients.isEmpty)) {
                  // showLoadingDialog(context, text: 'Getting appointments');
                  return CustomizedCircularProgressBar();
                }
              } catch (e) {
                throw Exception(AppStrings.errortext);
              }
              try {
                if (state.errorMsg != null && state.errorMsg.isNotEmpty) {
                  return Container(
                    padding: EdgeInsets.only(top: 175),
                    child: Center(
                        child: Text(
                      state.errorMsg,
                      style: TextStyle(
                        color: CustomizedColors.buttonTitleColor,
                        fontSize: 20.0,fontFamily: AppFonts.regular
                      ),
                    )),
                  );
                }
              } catch (e) {
                throw Exception(e.toString());
              }
              try {
                if (state.patients == null || state.patients.isEmpty) {
                  return Text(
                    AppStrings.nopatients,
                    style: TextStyle( fontFamily: AppFonts.regular,
                        fontSize: 18.0, color: CustomizedColors.noAppointment),
                  );
                }
              } catch (e) {
                throw Exception(e.toString());
              }
              patients = state.patients;
              try {
                if (state.keyword != null && state.keyword.isNotEmpty) {
                  filteredPatients = patients
                      .where((u) => (u.patient.displayName
                          .toLowerCase()
                          .contains(state.keyword.toLowerCase())))
                      .toList();
                } else {
                  filteredPatients = patients;
                }
              } catch (e) {
                throw Exception(e.toString());
              }

              try {
                if (page > 1 && state.hasReachedMax == true) {
                  String value1 = AppStrings.noData;

                  if (!isShowToast) {
                    isShowToast = true;
                    Fluttertoast.showToast(msg: value1).then((value1) {
                      Fluttertoast.cancel();
                    });
                  }
                }
              } catch (e) {
                throw Exception(e.toString());
              }

              /// display count of practice for loop
              practiceCountMap.clear();
              filteredPatients.forEach((element) {
                int practiceCount = practiceCountMap[element.practice];
                if (practiceCount == null) {
                  practiceCount = 0;
                }

                ///count [patients]
                practiceCountMap[element.practice] = practiceCount + 1;
                locationName[element.practice] = element.location.locationName;
              });
              return filteredPatients != null && filteredPatients.isNotEmpty
                  ? Card(
                      elevation: 0,
                      color: CustomizedColors.primaryBgColor,
                      child: GroupedListView<dynamic, String>(
                        physics: NeverScrollableScrollPhysics(),
                        elements: filteredPatients,
                        shrinkWrap: true,
                        groupBy: (filteredPatients) {
                          return '${filteredPatients.practice}';
                        },
                        groupSeparatorBuilder: (String practice) =>
                            TransactionGroupSeparator(
                                practice: practice,
                                appointmentsCount: practiceCountMap[practice],
                                locationName: locationName[practice]),
                        order: GroupedListOrder.ASC,
                        itemBuilder: (context, element) => InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientDetail(),
                                settings: RouteSettings(
                                  arguments: element,
                                ),
                              ),
                            );
                          },
                          child: Material(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                      color: Colors.grey[400],
                                      blurRadius: 5.0,
                                      offset: Offset(0.0, 1.0))
                                ],
                              ),
                              height: 120,
                              padding: EdgeInsets.only(
                                  left: 10, right: 15, top: 5, bottom: 5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Column(
                                            children: [
                                              profilePic != null &&
                                                      profilePic != ""
                                                  ? CachedImage(
                                                      null,
                                                      isRound: true,
                                                      radius: 50.0,
                                                    )
                                                  : Image.asset(
                                                      AppImages.defaultImg),
                                            ],
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      element.patient.displayName,
                                                      style: TextStyle(height: 1.5, fontSize: 15.0,fontFamily: AppFonts.regular,
                                                          fontWeight: FontWeight.w600),
                                                    ),
                                                    element.isNewPatient == true
                                                        ? Icon(Icons.bookmark,
                                                            color: CustomizedColors.blueAppBarColor,
                                                          )
                                                        : Container()
                                                  ],
                                                ),
                                                Text(
                                                    AppStrings.dr_txt + "" + element.providerName ??
                                                        "",overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(height: 1.5, fontSize: 14.0,fontFamily: AppFonts.regular)),
                                                Text(
                                                  element.appointmentType ?? "",
                                                  style: TextStyle(height: 1.5, fontSize: 14.0,fontFamily:AppFonts.regular),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(element.appointmentStatus ??
                                                      "", overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(height: 1.4, fontSize: 14.0,fontFamily:AppFonts.regular),
                                                ),
                                              ]),
                                        ],
                                      )
                                    ],
                                  ),
                                  element.dictationStatus == AppStrings.pendding
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            AppConstants.parseDate(-1, AppConstants.yyyyMMdd, dateTime: DateTime.parse(element.appointmentStartDate)) ==
                                                    AppConstants.parseDate(-1, AppConstants.yyyyMMdd, dateTime: DateTime.now())
                                                ? Text(AppConstants.parseDate(-1, AppConstants.hhmma,
                                                        dateTime: DateTime.parse(element
                                                                .appointmentStartDate)), style: TextStyle(fontFamily: AppFonts.regular),)
                                                : Text(AppConstants.parseDate(-1, AppConstants.MMMddyyyy,
                                                        dateTime: DateTime.parse(element.appointmentStartDate)), style: TextStyle(fontFamily: AppFonts.regular),),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.red,
                                                  size: 12,
                                                ),
                                                SizedBox(width: 5),
                                                RichText(
                                                  text: TextSpan(
                                                    //text: '• ',
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: AppFonts.regular),
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                          text: AppStrings.dictation + " " + element.dictationStatus ?? "",
                                                          style: TextStyle(fontSize: 12, color: Colors.black87,fontFamily: AppFonts.regular)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        )
                                      : element.dictationStatus ==AppStrings.statuscompleted
                                      ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                AppConstants.parseDate(-1,
                                                    AppConstants.yyyyMMdd,
                                                            dateTime: DateTime.parse(element.appointmentStartDate)) ==
                                                        AppConstants.parseDate(-1, AppConstants.yyyyMMdd,
                                                            dateTime: DateTime.now())
                                                    ? Text(AppConstants.parseDate(-1, AppConstants.hhmma,
                                                    dateTime: DateTime.parse(element.appointmentStartDate)),style: TextStyle(fontFamily: AppFonts.regular),)
                                                    : Text(
                                                        AppConstants.parseDate(-1,
                                                            AppConstants.MMMddyyyy, dateTime: DateTime.parse(element.appointmentStartDate)),
                                                    style: TextStyle(fontFamily: AppFonts.regular) ),
                                                // SizedBox(height: 20),
                                                RichText(
                                                  text: TextSpan(
                                                    text: '• ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontFamily: AppFonts.regular
                                                    ),
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                          text: element
                                                                  .dictationStatus ??
                                                              "", style: TextStyle(
                                                            fontSize: 12,fontFamily: AppFonts.regular, color: Colors.black87, )),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            )
                                          : element.dictationStatus == AppStrings.notapplicable
                                ? AppConstants.parseDate(-1, AppConstants.yyyyMMdd, dateTime: DateTime.parse(element.appointmentStartDate)) ==
                                                      AppConstants.parseDate(-1,AppConstants.yyyyMMdd, dateTime: DateTime.now())
                                                  ? Text(AppConstants.parseDate(-1, AppConstants.hhmma,
                                                          dateTime: DateTime.parse(element.appointmentStartDate)), style: TextStyle(fontFamily: AppFonts.regular),)
                                                  : Text(AppConstants.parseDate(-1, AppConstants.MMMddyyyy,
                                                          dateTime: DateTime.parse(element.appointmentStartDate)), style: TextStyle(fontFamily: AppFonts.regular,fontSize: 12),)
                                              : Container(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(padding: EdgeInsets.only(top: 175)),
                          Center(
                            child: Text(
                              AppStrings.noresultsfoundrelatedsearch,
                              style: TextStyle(
                                  fontFamily: AppFonts.regular,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: CustomizedColors.buttonTitleColor),
                            ),
                          )
                        ],
                      ),
                    );
            }),
          ],
        ),
      ),
    );
  }
  //filterDialog related code//
  _filterDialog(BuildContext buildContext) {
    double width = MediaQuery.of(context).size.width;
    FocusScope.of(context).requestFocus(new FocusNode());
    _searchFilterController.clear();
    return showModalBottomSheet(
      isScrollControlled: true,
        backgroundColor: CustomizedColors.blueAppBarColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40.0),
          topRight: Radius.circular(40.0),
        )),
        context: context,
        builder: (BuildContext bc) {
          return Container(
            height: 400,
            child: new Wrap(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                        padding: width > 600
                            ? EdgeInsets.only(top: 25, left: 350)
                            : EdgeInsets.only(top: 25, left: 100),
                        child:
                        Text(AppStrings.selectfilter,
                            style: TextStyle(
                                fontFamily: AppFonts.regular,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: CustomizedColors.textColor))
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30),
                  child: Divider(color: CustomizedColors.divider),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 150,
                      child: ProviderDropDowns(onTapOfProviders: (newValue) {
                        setState(
                          () {
                            _currentSelectedProviderId =
                                (newValue as ProviderList).providerId;
                          },
                        );
                      }),
                    ),
                    Container(
                      width: 150,
                      child:
                      Dictation(onTapOfDictation: (newValue) {
                        setState(() {
                          _currentSelectedDictationId =
                              (newValue as DictationStatus).dictationstatusid;
                        });
                      }),
                    )
                  ],
                ),
                // SizedBox(width: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 150,
                      child: LocationDropDown(onTapOfLocation: (newValue) {
                        _currentSelectedLocationId = newValue.locationId;
                      }),
                    ),
                    Container(
                      height: 55,
                      width: 150,
                      //margin: EdgeInsets.only(top: 5),
                      child: FlatButton(
                          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                          onPressed: () async {
                            final List<String> result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DateFilter()));
                            startDate = result.first;
                            endDate = result.last;
                          },
                          child: Text(
                            AppStrings.datafiltertitle,
                            style: TextStyle(
                                fontFamily: AppFonts.regular,
                                fontSize: 16.0,
                                color: CustomizedColors.textColor),
                          ),
                          splashColor: CustomizedColors.blueAppBarColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 60,
                      width: width > 600 ? 600 : 300,
                      child: PatientSerach(
                        width: 250,
                        height: 70,
                        controller: _searchFilterController,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 40,
                      width: 100,
                      margin: width > 600
                          ? EdgeInsets.only(top: 5, left: 50)
                          : EdgeInsets.only(top: 5, left: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: CustomizedColors.textColor,
                      ),
                      child: FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(AppStrings.cancel,
                            style: TextStyle(
                                fontFamily: AppFonts.regular,
                                color: CustomizedColors.buttonTitleColor,
                                fontSize: 14.0)),
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 100,
                      margin: EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: CustomizedColors.homeSubtitleColor)),
                      child: FlatButton(
                          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                          onPressed: () {
                            FocusScope.of(context)
                                .requestFocus(new FocusNode());
                            _textFieldController.clear();
                            _searchFilterController.clear();
                            setState(() {
                              datePicker = true;
                              dateRange = false;
                            });
                            Future.delayed(Duration(milliseconds: 500), () {
                              _controller?.animateToDate(
                                  DateTime.now().subtract(Duration(days: 3)));
                            });
                            Navigator.pop(context);
                            page = 1;
                            BlocProvider.of<PatientBloc>(context).add(
                                GetSchedulePatientsList(
                                    keyword1: null,
                                    providerId: null,
                                    locationId: null,
                                    dictationId: null,
                                    startDate: null,
                                    endDate: null,
                                    searchString: null,
                                    pageKey: page));
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0))),
                          child: Text(
                            AppStrings.clearfiltertxt,
                            style: TextStyle(
                                fontFamily: AppFonts.regular,
                                fontSize: 16.0,
                                color: CustomizedColors.buttonTitleColor),
                          ),
                          splashColor: CustomizedColors.primaryColor,
                          color: Colors.white),
                    ),
                    Container(
                      height: 40,
                      width: 100,
                      margin: width > 600
                          ? EdgeInsets.only(top: 5, right: 50)
                          : EdgeInsets.only(top: 5, right: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: CustomizedColors.textColor,
                      ),
                      child: FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            try {
                              if (startDate != null && endDate != null) {
                                dateRange = true;
                                datePicker = false;
                              } else {
                                dateRange = false;
                                datePicker = true;
                              }
                            } catch (e) {
                              throw Exception(e.toString());
                            }
                          });
                          page = 1;
                          BlocProvider.of<PatientBloc>(context).add(
                              GetSchedulePatientsList(
                                  keyword1: null,
                                  providerId:
                                      _currentSelectedProviderId !=
                                              null
                                          ? _currentSelectedProviderId
                                          : null,
                                  locationId: _currentSelectedLocationId != null
                                      ? _currentSelectedLocationId
                                      : null,
                                  dictationId:
                                      _currentSelectedDictationId != null
                                          ? int.tryParse(
                                              _currentSelectedDictationId)
                                          : null,
                                  startDate: startDate != "" ? startDate : null,
                                  endDate: endDate != "" ? endDate : null,
                                  searchString:
                                      this._searchFilterController.text != null
                                          ? this._searchFilterController.text
                                          : null,
                                  pageKey: page));
                          isShowToast = false;
                        },
                        child: Text(AppStrings.ok, style: TextStyle(fontFamily: AppFonts.regular, color: CustomizedColors.buttonTitleColor, fontSize: 14.0)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }
}
