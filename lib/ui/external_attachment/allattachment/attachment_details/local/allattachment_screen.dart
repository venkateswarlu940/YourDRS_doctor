
import 'dart:convert';

import 'package:YOURDRS_FlutterAPP/common/app_colors.dart';
import 'package:YOURDRS_FlutterAPP/common/app_toast_message.dart';
import 'package:YOURDRS_FlutterAPP/helper/db_helper.dart';
import 'package:YOURDRS_FlutterAPP/network/models/external_dictations/external_databse_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/external_dictation_attacment_model.dart';
import 'package:YOURDRS_FlutterAPP/network/models/manual_dictations/photo_list.dart';
import 'package:YOURDRS_FlutterAPP/network/repo/local/preference/local_storage.dart';
import 'package:YOURDRS_FlutterAPP/network/services/dictation/extrenalattachmnent_postapi.dart';
import 'package:YOURDRS_FlutterAPP/network/services/external_attachment/external_localtoserver_postapi.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../common/app_text.dart';
import 'externalattachment_details.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class Allattachmentlocal extends StatefulWidget {
  @override
  _AllattachmentState createState() => _AllattachmentState();
}

class _AllattachmentState extends State<Allattachmentlocal> {

  //----------chekcing internet connection
  List<ExternalAttachmentList> attachments = [];
  int attachmentId;
  String displayName;
  int uploadedToServer;
//-----------------local data base variables fetching
  int practiceId;
  int LocationId;
  int providerId1;
  String firstname;
  String lastname;
  String _dateOfbirthController;
  var memberId;
  int documenttypeId;
  var emergencyAddOn;
  var Description;
  // dynamic photoListOfGallery;
  var statusCode;
  var attachmentname;
  var physicalfilename;
  var attachmenttype;
  String convertedImg;
  var imageName;
  List photoListOfGallery = [];
  AppToast _tost=AppToast();
  bool togglevalue=true;
  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      memberId = (prefs.getString(Keys.memberId) ?? '');
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    _loadData();
    super.initState();
  }
  // List<PhotoList>
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
        child:  FutureBuilder(
            future: DatabaseHelper.db.getAllExtrenalAttachmentList(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              print(snapshot.hasData);
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {

                attachments = snapshot.data as List<ExternalAttachmentList>;
                return
                  ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      itemCount: attachments.length,
                      itemBuilder: (BuildContext context, int index) {
                        attachmentId =attachments[index].id;
                        emergencyAddOn=attachments[index].isemergencyaddon;
                        if(emergencyAddOn==0){
                          togglevalue=false;
                        }else
                          {
                            togglevalue=true;
                          }
                          return
                          InkWell(
                            onTap: () async {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Externalattachment_data(
                                      attachmentId: attachments[index].id,
                                      displayfilename:
                                      attachments[index].displayfilename,
                                      practicename: attachments[index].practicename,
                                      locationname: attachments[index].locationname,
                                      externaldocumenttype:
                                      attachments[index].externaldocumenttype,
                                      providername: attachments[index].providername,
                                      patientfirstname:
                                      attachments[index].patientfirstname,
                                      patientdob: attachments[index].patientdob,
                                      isemergencyaddon:togglevalue,
                                      //isemergencyaddon:attachments[index].isemergencyaddon,
                                      description: attachments[index].description,
                                      uploadedtoserver: attachments[index].uploadedtoserver,
                                    )),
                              );
                            },
                            child:
                            Container(
                              child: Card(
                                child: ListTile(
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(padding: new EdgeInsets.all(3.0)),
                                    Container(
                                      width: 320,
                                      child: Text(
                                        "${attachments[index].displayfilename}",
                                        style: TextStyle( fontFamily: AppFonts.regular,
                                            fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.cloud_done, size: 34,color: Colors.black54,),
                                  onPressed: () async{
                                    _tost.showToast("error while uploading!!!");
                                  }

                              ),
                            ),
                          ),
                              ),
                              );
                        }
                    );
                }
            }
        )
    );
  }
}

