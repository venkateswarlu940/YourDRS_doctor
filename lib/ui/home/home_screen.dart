import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:YOURDRS_FlutterAPP/blocs/home/patient_bloc.dart';
import 'package:YOURDRS_FlutterAPP/blocs/home/patient_bloc_event.dart';
import 'package:YOURDRS_FlutterAPP/blocs/home/patient_bloc_state.dart';
import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_constants.dart';
import 'package:YOURDRS_FlutterAPP/common/app_loader.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/common/app_toast_message.dart';
import 'package:YOURDRS_FlutterAPP/network/models/home/dictation.dart';
import 'package:YOURDRS_FlutterAPP/network/models/home/provider.dart';
import 'package:YOURDRS_FlutterAPP/network/models/home/schedule.dart';
import 'package:YOURDRS_FlutterAPP/network/repo/local/preference/local_storage.dart';
import 'package:YOURDRS_FlutterAPP/ui/home/home_screen_appbar.dart';
import 'package:YOURDRS_FlutterAPP/ui/home/drawer.dart';
import 'package:YOURDRS_FlutterAPP/ui/home/grouping_seperator.dart';
import 'package:YOURDRS_FlutterAPP/widget/date_range_picker.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/dictation.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/location.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/provider.dart';
import 'package:YOURDRS_FlutterAPP/widget/input_fields/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:YOURDRS_FlutterAPP/ui/home/patient_details.dart';
import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grouped_list/grouped_list.dart';

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
      throw Exception("Error");
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class _PatientAppointmentState extends State<PatientAppointment> {
final _debouncer = Debouncer(milliseconds: 500);
  var displayName = "";
  AppToast appToast=AppToast();
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
//booean property for visibility for search and clear filter
  bool visibleSearchFilter = false;
  bool visibleClearFilter = true;
//booean property for visibility for Date Picker
  bool datePicker = true;
  bool dateRange = false;
  String codeDialog;
  String valueText;
  var selectedDate;
  ///counting for each practice location using hashmap
  HashMap<String, int> practiceCountMap = HashMap();
  HashMap<String, String> locationName = HashMap();
  bool isLoadingVertical = false;
  TextEditingController _textFieldController = TextEditingController();
//Infinite Scroll Pagination related code//
  var _scrollController = ScrollController();
  double maxScroll, currentScroll;
  int page;

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
    super.dispose();
  }
  DatePickerController _controller = DatePickerController();
  DateTime _selectedValue = DateTime.now();
  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      displayName = (prefs.getString(Keys.displayName) ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: DrawerScreen(),
      appBar: AppBar(
        elevation: 0.2,
        backgroundColor: CustomizedColors.primaryColor,
        title: ListTile(
          title: Profile(),
          trailing: Column(
            children: [
              Offstage(
                offstage: visibleSearchFilter,
                key: _key,
                child: FlatButton(
                  minWidth: 2,
                  padding: EdgeInsets.only(right: 0),
                  child: Icon(visibleClearFilter != false ? Icons.segment : Icons.filter, color: CustomizedColors.iconColor,),
                  onPressed: () {
                    startDate = null;
                    endDate = null;
                    _currentSelectedProviderId = null;
                    _currentSelectedDictationId = null;
                    _currentSelectedLocationId = null;
                    _textFieldController.clear();
                    _filterDialog(context);
                  },
                ),
              ),
              Offstage(
                offstage: visibleClearFilter,
                child: FlatButton(
                  minWidth: 2,
                  padding: EdgeInsets.only(right: 0),
                  child: Icon(Icons.clear_all, color: CustomizedColors.iconColor,),
                  onPressed: () {
                    _currentSelectedProviderId = null;
                    _currentSelectedDictationId = null;
                    _currentSelectedLocationId = null;
                    _filterDialog(context);
                  },
                ),
              )
            ],
          ),
        ),
      ),
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.10,
                color: CustomizedColors.primaryColor,
              ),
              Positioned(
                top: 45,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.90,
                  child: Column(
                    children: <Widget>[
                   PatientSerach(
                              width: 250,
                              height: 60,
                              controller: _textFieldController,
                              onChanged: (string) {
                                _debouncer.run(() {
                                  BlocProvider.of<PatientBloc>(context).add(SearchPatientEvent(keyword: string));
                                });
                              },
                            ),
                      SizedBox(height: 10,),
                      Visibility(
                        visible: datePicker,
                        child: Container(
                            color: Colors.grey[100],
                            child: DatePicker(
                                DateTime.now().subtract(Duration(days: 365)),
                                width: 45.0,
                                height: 80,
                                controller: _controller,
                                initialSelectedDate: DateTime.now(),
                                selectionColor: CustomizedColors.primaryColor,
                                selectedTextColor: CustomizedColors.textColor,
                                dayTextStyle: GoogleFonts.montserrat(fontSize: 10.0),
                                dateTextStyle: GoogleFonts.montserrat(fontSize: 10.0),
                                monthTextStyle:
                                GoogleFonts.montserrat(fontSize: 10.0),
                                onDateChange: (date) {
                                  setState(() {
                                    _selectedValue = date;
                                    selectedDate = AppConstants.parseDate(-1, AppConstants.MMDDYYYY, dateTime: _selectedValue);
                                    page = 1;
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
                                    Text( AppStrings.selecteddaterange,
                                        style: GoogleFonts.montserrat(color: CustomizedColors.buttonTitleColor,
                                            fontSize: 16.0, fontWeight: FontWeight.bold)),
                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                              padding:
                                              EdgeInsets.fromLTRB(5, 0, 0, 0)),
                                          Text('${AppConstants.parseDatePattern(startDate, AppConstants.MMMddyyyy)}' ??
                                                "", style: GoogleFonts.montserrat(
                                                color: CustomizedColors.buttonTitleColor,
                                                fontSize: 16.0, fontWeight: FontWeight.bold),
                                          ),
                                          Text('-', style: GoogleFonts.montserrat(
                                              color: CustomizedColors.buttonTitleColor, fontSize: 16.0, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                              '${AppConstants.parseDatePattern(endDate, AppConstants.MMMddyyyy)}' ??
                                                  "", style: GoogleFonts.montserrat(
                                                  color: CustomizedColors.buttonTitleColor,
                                                  fontSize: 16.0, fontWeight: FontWeight.bold))
                                        ]),
                                  ]))
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5),
                child: Container(
                  child: DraggableScrollableSheet(
                    maxChildSize: 0.7,
                    initialChildSize: 0.7,
                    minChildSize: 0.7,
                    builder: (context, scrollController) {
                      return Container(
                        height: 100,
                        padding: EdgeInsets.only(
                            left: 5, right: 5, top: 5),
                        decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                          color: CustomizedColors.textColor,),
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              BlocBuilder<PatientBloc,
                                  PatientAppointmentBlocState>(
                                  builder: (context, state) {
                                    try {
                                      if (state.isLoading && (state.patients == null || state.patients.isEmpty)) {
                                        //  showLoadingDialog(context, _keyLoader);
                                        return CustomizedCircularProgressBar();
                                      }
                                    } catch (e) {
                                      throw Exception("Error");
                                    }
                                    try {
                                      if (state.errorMsg != null && state.errorMsg.isNotEmpty) {
                                        return Center(
                                            child: Text(
                                              state.errorMsg,
                                              style: GoogleFonts.montserrat(
                                                  color: CustomizedColors.buttonTitleColor,
                                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                                            ));
                                      }
                                    } catch (e) {
                                      throw Exception(e.toString());
                                    }
                                    try {
                                      if (state.patients == null || state.patients.isEmpty) {
                                        return Text(AppStrings.nopatients,
                                          style: GoogleFonts.montserrat(
                                              fontSize: 18.0, fontWeight: FontWeight.bold,
                                              color: CustomizedColors.noAppointment),
                                        );
                                      }
                                    } catch (e) {
                                      throw Exception(e.toString());
                                    }
                                    patients = state.patients;
                                    try {
                                      if (state.keyword != null && state.keyword.isNotEmpty) {
                                        filteredPatients = patients
                                            .where((u) => (u.patient.displayName.toLowerCase().contains(state.keyword.toLowerCase()))).toList();
                                      } else {
                                        filteredPatients = patients;
                                      }
                                    } catch (e) {
                                      throw Exception(e.toString());
                                    }

                                    try {
                                      if (page > 1 &&
                                          state.hasReachedMax == true) {
                                        appToast.showToast(
                                            AppStrings.noData);

                                      }
                                    } catch (e) {
                                      throw Exception(e.toString());
                                    }
                                    /// display count of practice for loop
                                    practiceCountMap.clear();
                                    filteredPatients.forEach((element) {
                                      int practiceCount = practiceCountMap[
                                      element.practice];
                                      if (practiceCount == null) {
                                        practiceCount = 0;
                                      }
                                      ///count [patients]
                                      practiceCountMap[element.practice] =
                                          practiceCount + 1;
                                      locationName[element.practice] = element.location.locationName;
                                    });
                                    return filteredPatients != null && filteredPatients.isNotEmpty
                                        ? Card(
                                      child: GroupedListView<dynamic,
                                          String>(
                                        physics:
                                        NeverScrollableScrollPhysics(),
                                        elements: filteredPatients,
                                        shrinkWrap: true,
                                        groupBy: (filteredPatients) {
                                          return '${filteredPatients.practice}';
                                        },
                                        groupSeparatorBuilder: (String
                                        practice) =>
                                            TransactionGroupSeparator(
                                                practice: practice,
                                                appointmentsCount: practiceCountMap[practice],
                                                locationName: locationName[practice]),
                                        order: GroupedListOrder.ASC,
                                        separator: Container(
                                            height: 1.0,
                                            color: CustomizedColors.divider),
                                        itemBuilder: (context, element) =>
                                            InkWell(
                                              onTap: () {
                                                Navigator.push(context, MaterialPageRoute(
                                                    builder: (context) => PatientDetail(), settings: RouteSettings(arguments: element,),
                                                  ),
                                                );
                                              },
                                              child: Material(
                                                child: Container(
                                                  height: 90,
                                                  padding:
                                                  EdgeInsets.only(left: 10, right: 15, top: 5, bottom: 5),
                                                  color: CustomizedColors.iconColor,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Center(
                                                        child: Hero(
                                                          transitionOnUserGestures: true,
                                                          tag: element,
                                                          child: Transform.scale(
                                                            scale: 1.0,
                                                            child: element.isNewPatient == true
                                                                ? Icon(
                                                              Icons.bookmark,
                                                              color: CustomizedColors.bookMarkIconColour,
                                                            )
                                                                : Icon(Icons.person_add_alt_1_rounded),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 20),
                                                      Expanded(
                                                        child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(element.patient.displayName,
                                                                  style: GoogleFonts.montserrat(
                                                                      fontSize: 14.0, fontWeight: FontWeight.w600)),
                                                              Text("Dr." + "" + element.providerName ??
                                                                      "",
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: GoogleFonts.montserrat(fontSize: 12.0)),
                                                              Text(element.scheduleName ?? "", style: GoogleFonts.montserrat(fontSize: 12.0),
                                                                overflow: TextOverflow.ellipsis,),
                                                              Text(element.appointmentStatus ?? "",
                                                                overflow: TextOverflow.ellipsis,
                                                                style: GoogleFonts.montserrat(fontSize: 12.0),
                                                              ),
                                                            ]),
                                                      ),
                                                      // SizedBox(width: 10),
                                                      element.dictationStatus == "Pending"
                                                          ? Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        mainAxisSize: MainAxisSize.max,
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          AppConstants.parseDate(-1, AppConstants.yyyyMMdd, dateTime: DateTime.parse(element.appointmentStartDate)) == AppConstants.parseDate(-1, AppConstants.yyyyMMdd, dateTime: DateTime.now())
                                                              ? Text(AppConstants.parseDate(-1, AppConstants.hhmma,
                                                              dateTime: DateTime.parse(element.appointmentStartDate)))
                                                              : Text(AppConstants.parseDate(-1, AppConstants.MMMddyyyy,
                                                              dateTime: DateTime.parse(element.appointmentStartDate))),
                                                          SizedBox(height: 22),
                                                          RichText(
                                                            text:
                                                            TextSpan(text: '• ', style: GoogleFonts.montserrat(color: CustomizedColors.dictationPending,
                                                                  fontSize: 14, fontWeight: FontWeight.bold),
                                                              children: <
                                                                  TextSpan>[
                                                                TextSpan(text: 'Dictation' + " " + element.dictationStatus ?? "",
                                                                    style: GoogleFonts.montserrat(color: CustomizedColors.dictationStatusColor, fontSize: 12)),
                                                              ],
                                                            ),
                                                          )
                                                        ],
                                                      )
                                                          : element.dictationStatus == "Dictation Completed"
                                                          ? Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        mainAxisSize: MainAxisSize.max,
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [AppConstants.parseDate(-1, AppConstants.yyyyMMdd, dateTime: DateTime.parse(element.appointmentStartDate)) ==
                                                            AppConstants.parseDate(-1, AppConstants.yyyyMMdd, dateTime: DateTime.now())
                                                              ? Text(AppConstants.parseDate(-1, AppConstants.hhmma, dateTime: DateTime.parse(element.appointmentStartDate)))
                                                              : Text(AppConstants.parseDate(-1, AppConstants.MMMddyyyy, dateTime: DateTime.parse(element.appointmentStartDate))),
                                                          // SizedBox(height: 20),
                                                          RichText(text: TextSpan(text: '• ',
                                                              style: GoogleFonts.montserrat(color: CustomizedColors.dictationCompleted, fontSize: 14, fontWeight: FontWeight.bold),
                                                              children: <TextSpan>[
                                                                TextSpan(text: element.dictationStatus ?? "", style: GoogleFonts.montserrat(color: CustomizedColors.dictationStatusColor, fontSize: 12, fontWeight: FontWeight.w500)),
                                                              ],
                                                            ),
                                                          )
                                                        ],
                                                      )
                                                          : element.dictationStatus == "Not Applicable"
                                                          ? AppConstants.parseDate(-1, AppConstants.yyyyMMdd, dateTime: DateTime.parse(element.appointmentStartDate)) ==
                                                          AppConstants.parseDate(-1, AppConstants.yyyyMMdd, dateTime: DateTime.now())
                                                          ? Text(AppConstants.parseDate(-1, AppConstants.hhmma, dateTime: DateTime.parse(element.appointmentStartDate)))
                                                          : Text(AppConstants.parseDate(-1, AppConstants.MMMddyyyy, dateTime: DateTime.parse(element.appointmentStartDate)))
                                                          : Container(),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                      ),
                                    ):Search_Fail ();
                                  }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Popupmenu()
            ],
          ),
        ),
    );
  }
  _filterDialog(BuildContext buildContext) {
    FocusScope.of(context).requestFocus(new FocusNode());
    _textFieldController.clear();
    return showDialog(
      context: buildContext,
      builder: (ctx) => ListView(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 75),
            child: AlertDialog(
              title: Text(AppStrings.selectfilter, style: GoogleFonts.montserrat(),
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 250,
                      child: ProviderDropDowns(onTapOfProviders: (newValue) {
                        setState(
                              () {
                            _currentSelectedProviderId =
                                (newValue as ProviderList).providerId;
                          },
                        );
                      }),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 250,
                      child: Dictation(onTapOfDictation: (newValue) {
                        setState(() {
                          _currentSelectedDictationId = (newValue as DictationStatus).dictationstatusid;
                        });
                      }),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 250,
                      child: LocationDropDown(onTapOfLocation: (newValue) {
                        _currentSelectedLocationId = newValue.locationId;
                      }),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 55,
                      width: 245,
                      margin: EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(color: CustomizedColors.homeSubtitleColor)),
                      child: RaisedButton.icon(
                          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                          onPressed: () async {
                            final List<String> result = await Navigator.push(context, MaterialPageRoute(builder: (context) => DateFilter()));
                            startDate = result.first;
                            endDate = result.last;
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(5.0))),
                          label: Text(AppStrings.datafiltertitle, style: GoogleFonts.montserrat(fontSize: 16.0, color: CustomizedColors.buttonTitleColor),),
                          icon: Icon(Icons.date_range),
                          splashColor: CustomizedColors.primaryColor,
                          color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 55,
                      width: 245,
                      margin: EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(color: CustomizedColors.homeSubtitleColor)),
                      child: RaisedButton.icon(
                          padding: EdgeInsets.only(left: 25),
                          onPressed: () {
                            return showDialog(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog(
                                    title: Text(AppStrings.searchpatienttitle),
                                    content: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          valueText = value;
                                        });
                                      },
                                      controller: this._textFieldController,
                                      decoration: InputDecoration(
                                          hintText: AppStrings.searchpatienttitle),
                                    ),
                                    actions: <Widget>[
                                      FlatButton(
                                        color: CustomizedColors.accentColor,
                                        textColor: Colors.white,
                                        child: Text(AppStrings.cancel),
                                        onPressed: () {
                                          setState(() {
                                            Navigator.pop(ctx);
                                          });
                                        },
                                      ),
                                      FlatButton(
                                        color: CustomizedColors.accentColor,
                                        textColor: Colors.white,
                                        child: Text(AppStrings.ok),
                                        onPressed: () {
                                          setState(() {
                                            codeDialog = valueText;
                                            Navigator.pop(ctx);
                                          });
                                        },
                                      ),
                                    ],
                                  );
                                });
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(5.0))),
                          label: Text(AppStrings.searchpatient ?? "${this._textFieldController.text}", style: GoogleFonts.montserrat(
                              fontSize: 16.0, color: CustomizedColors.buttonTitleColor,),),
                          icon: Icon(Icons.search),
                          splashColor: CustomizedColors.primaryColor,
                          color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 55,
                      width: 245,
                      margin: EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(color: CustomizedColors.homeSubtitleColor)),
                      child: RaisedButton.icon(
                          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                          onPressed: () {
                            FocusScope.of(context).requestFocus(new FocusNode());
                            _textFieldController.clear();
                            setState(() {
                              visibleSearchFilter = false;
                              visibleClearFilter = true;
                              datePicker = true;
                              dateRange = false;
                            });
                            Future.delayed(Duration(milliseconds: 500), () {
                              _controller?.animateToDate(DateTime.now().subtract(Duration(days: 3)));
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
                              borderRadius: BorderRadius.all(Radius.circular(5.0))),
                          label: Text(AppStrings.clearfiltertxt, style: GoogleFonts.montserrat(fontSize: 16.0, color: CustomizedColors.buttonTitleColor),
                          ),
                          icon: Icon(Icons.filter_alt_sharp),
                          splashColor: CustomizedColors.primaryColor,
                          color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FlatButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(AppStrings.cancel, style: TextStyle(color: CustomizedColors.primaryColor, fontSize: 12.0)),
                    ),
                    FlatButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          visibleSearchFilter = true;
                          visibleClearFilter = false;
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
                        BlocProvider.of<PatientBloc>(context).add(GetSchedulePatientsList(
                                keyword1: null,
                                providerId: _currentSelectedProviderId != null ? _currentSelectedProviderId : null,
                                locationId: _currentSelectedLocationId != null ? _currentSelectedLocationId : null,
                                dictationId: _currentSelectedDictationId != null ? int.tryParse(_currentSelectedDictationId) : null,
                                startDate: startDate != "" ? startDate : null,
                                endDate: endDate != "" ? endDate : null,
                                searchString: this._textFieldController.text != null ? this._textFieldController.text : null,
                                pageKey: page));
                        },
                      child: Text(AppStrings.ok, style: TextStyle(color: CustomizedColors.primaryColor, fontSize: 12.0)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

