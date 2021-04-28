import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/common/app_text.dart';
import 'package:YOURDRS_FlutterAPP/common/app_toast_message.dart';
import 'package:YOURDRS_FlutterAPP/network/models/external_dictations/get_all_external_attachments_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/external_dictations/get_external_document_details.dart';
import 'package:YOURDRS_FlutterAPP/network/services/external_attachment/all_external_attachment_service.dart';
import 'package:YOURDRS_FlutterAPP/ui/external_attachment/allattachment/attachment_details/local/allattachment_screen.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'externalattachment_server.dart';

class GetMyAttachments extends StatefulWidget {
  static const String routeName = '/Externalattachmnet_server';
  @override
  State<StatefulWidget> createState() {
    return GetMyAttachmentsState();
  }
}

class GetMyAttachmentsState extends State<GetMyAttachments> {
  /// Declaring variables
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  AppToast appToast = AppToast();
  bool _hasMore = true;
  int _pageNumber = 0;
  bool _error = false;
  bool _loading = false;
  List<ExternalDocumentList> _externalAttachments = [];
  int thresholdValue = 0;
  bool isInternetAvailable;
  int externalAttachmentId;
  String imageName;
  String attachmentName;
  bool hasData = false;
  List imageList = [];

  AllMyExternalAttachments apiServices = AllMyExternalAttachments();
  GetExternalDocumentDetailsService apiService2=GetExternalDocumentDetailsService();
  GetExternalPhotosService apiService3=GetExternalPhotosService();
  //Infinite Scroll Pagination related code//
  var _scrollController = ScrollController();
  double maxScroll, currentScroll;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    isInternetAvailable = await checkInternet();
    _getApiExternalAttachments();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    try {
      if (maxScroll > 0 && currentScroll > 0 && maxScroll == currentScroll) {
      //  print('maxScroll $maxScroll currentScroll $currentScroll');
        _getApiExternalAttachments();
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  //--------------------Show process indicator
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

//---------------------------Check if internet connected or not
  Future<bool> checkInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Allattachmentlocal(),
          getExternalDocsList(),
        ],
      ),
    );
  }

  Widget getExternalDocsList() {
    if (_loading && _pageNumber == 1) {
      return _loader();
    }

    if (_error) {
      return _errorText(message: 'Something went wrong!!!');
    }

    return _externalAttachments?.isNotEmpty ?? false
        ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _externalAttachments.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if(index == _externalAttachments.length){
                return _loader();
              }

              final ExternalDocumentList externalDocuments = _externalAttachments[index];
                // print("all data loaded successfully 7");
                return AnimationLimiter(
                    child: Column(children: [
                  AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 50),
                      child: FadeInAnimation(
                          child: SlideAnimation(
                              horizontalOffset:
                                  MediaQuery.of(context).size.width / 2,
                              child: InkWell(
                                onTap: () async {
                                  showLoadingDialog(context, _keyLoader);

                                  int externalAttachmentId = externalDocuments.externalAttachmentId;
                                  String displayFileName = externalDocuments.displayFileName;
                                //  print('externalDocuments item externalAttachmentId $externalAttachmentId $displayFileName');

                                  GetExternalDocumentDetails getExternalDocumentDetails =
                                  await apiService2.getExternalDocumentDetails(externalAttachmentId);

                                  if(getExternalDocumentDetails!=null){
                                    /*for (var i = 0; i < getExternalDocumentDetails.attachments.length; i++) {
                                    String attachmentName = getExternalDocumentDetails.attachments[i].name ?? '';
                                    this.attachmentName = attachmentName;
                                    String imageName = getExternalDocumentDetails.attachments[i].name ?? '';
                                    this.imageName = imageName;
                                    imageList.add({"image_path": imageName});
                                    print('getExternalDocumentDetails imageName $imageName attachmentName $attachmentName');
                                  }*/

////---------------------------external attachment photos api
//                                   GetExternalPhotos getExternalPhotos = await apiService3.getExternalPhotos(imageName);

                                    Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
                                    // RouteGenerator.navigatorKey.currentState
                                    //     .pushNamedAndRemoveUntil(ExternalAttachments.routeName,
                                    //       (Route<dynamic> route) => false,);

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                      builder: (context) =>
                                          ExternalAttachmentScreen(),
                                      settings: RouteSettings(
                                        arguments: {
                                          "getExternalDocumentDetails":getExternalDocumentDetails,
                                          "externalDocuments":externalDocuments,
                                        }
                                       // name: externalDocuments.toString(),
                                      ),
                                    ),
                                  );
                                }
                                },
                                child: Container(
                                margin: const EdgeInsets.all(3),
                                child: Card(
                                  child: ListTile(
                                    leading: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Padding(
                                            padding: new EdgeInsets.all(3.0)),
                                        Container(
                                          width: 320,
                                          child: Text(
                                            externalDocuments.displayFileName,
                                            style: TextStyle(
                                                fontFamily: AppFonts.regular,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.cloud_done,
                                        size: 34,
                                        color: CustomizedColors.primaryColor,
                                      ),
                                      onPressed: () {
                                        appToast.showToast("already uploaded");
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ))))
                ]));
            })
        : _errorText(message: 'No external documents found!!!');
  }

  _getApiExternalAttachments() async {
    if (!mounted) return;

    if(isInternetAvailable){
      if(!_hasMore){
       // print('_getApiExternalAttachments reached end pageNo $_pageNumber size ${_externalAttachments?.length}');
        appToast.showToast('No further documents found!!!');
        return;
      }

      setState(() {
        _loading = true;
        _error = false;
      });

      _pageNumber = _pageNumber+1;
      GetAllExternalAttachments allMyExternalAttachments = await apiServices.getMyAllExternalAttachemnts(_pageNumber);
      setState(() {
        _loading = false;
      });

      if (allMyExternalAttachments != null) {
        if(allMyExternalAttachments.externalDocumentList == null || allMyExternalAttachments.externalDocumentList.isEmpty){
          _hasMore = false;
          _error = true;
        } else {
          _externalAttachments.addAll(allMyExternalAttachments?.externalDocumentList);
          _error = false;
        }
      } else {
        _error = true;
      }
      setState(() {});
    } else {
      appToast.showToast('Please check internet connection!!!');
    }
  }

  Widget _loader() {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(8),
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(CustomizedColors.primaryColor),
      ),
    ));
  }

  Widget _errorText({String message}) {
    return Center(
        child: InkWell(
          onTap: () {
            _pageNumber = 0;
            _hasMore = true;
            _getApiExternalAttachments();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message ?? AppStrings.errorloadingphotos_text,style: TextStyle(fontFamily: AppFonts.regular,),),
          ),
        ));
  }

  //dispose methods//
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}