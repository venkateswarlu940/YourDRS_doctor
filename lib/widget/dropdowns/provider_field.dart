import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
// import 'package:YOURDRS_FlutterAPP/network/models/home/provider.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/provider_model.dart';
import 'package:YOURDRS_FlutterAPP/network/services/schedules/appointment_service.dart';
import 'package:YOURDRS_FlutterAPP/widget/dropdowns/searchable_dropdown.dart';
import 'package:flutter/material.dart';

class ExternalProviderDropDown extends StatefulWidget {
  final String PracticeLocationId;
  final onTapOfProvider;
  const ExternalProviderDropDown(
      {@required this.onTapOfProvider, @required this.PracticeLocationId});
  @override
  _ExternalProviderDropDownState createState() =>
      _ExternalProviderDropDownState();
}

class _ExternalProviderDropDownState extends State<ExternalProviderDropDown>
    with AutomaticKeepAliveClientMixin {
  var _currentSelectedValue;
  bool asTabs = false;
  Services apiServices = Services();
  ProviderList providerList;
  //List<LocationList> _list=[];
  List data = List();
  String locationId;

  void initState() {
    super.initState();
    _currentSelectedValue = widget.PracticeLocationId;
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    // print(
    //     'didChangeDependencies PracticeLocationId ${widget.PracticeLocationId}');
    // ExternalProvider externalProvider = await apiServices.getExternalProvider();
    // data = externalProvider.providerList;

//_currentSelectedValue=data;
//     setState(() {});
  }

  List<Widget> get appBarActions {
    return ([
      Center(child: Text("Tabs:")),
      Switch(
        activeColor: Colors.white,
        value: asTabs,
        onChanged: (value) {
          setState(() {
            asTabs = value;
          });
        },
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (locationId == null ||
        (widget.PracticeLocationId != null &&
            locationId != widget.PracticeLocationId)) {
      locationId = widget.PracticeLocationId;
      apiServices.getExternalProvider(locationId).then((value) {
        if (value != null) {
          data = value.providerList;
          setState(() {});
        }
      });
    }
    // print('build PracticeLocationId ${widget.PracticeLocationId}');

    return Container(
      //height: 100,
      width: MediaQuery.of(context).size.width * 0.95,

      child: SearchableDropdown.single(
        closeButton: Text(
          "",
          style: TextStyle(fontSize: 0.1),
        ),
        underline: Padding(padding: EdgeInsets.all(1)),
        displayClearIcon: false,
        hint: Text(AppStrings.selectpractice_text),
        items: data.map((item) {
          return DropdownMenuItem<ProviderList>(
              child: Text(
                item.displayname ?? "",
                overflow: TextOverflow.ellipsis,
              ),
              value: item);
        }).toList(),
        isExpanded: true,
        value: providerList,
        isCaseSensitiveSearch: true,
        searchHint: new Text('Select ', style: new TextStyle(fontSize: 20)),
        onChanged: (value) {
          setState(() {
            _currentSelectedValue = value;
            widget.onTapOfProvider(value);
          });
        },
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: CustomizedColors.accentColor,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
