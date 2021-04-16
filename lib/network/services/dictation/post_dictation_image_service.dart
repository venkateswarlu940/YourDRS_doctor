import 'dart:convert';
import 'dart:io';
import 'package:YOURDRS_FlutterAPP/common/app_constants.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/helper/db_helper.dart';
import 'package:YOURDRS_FlutterAPP/network/models/dictations/post_dictations_model.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class PostDictationsImageService {
  Future<PostDictationsModel> postApiMethod(int episodeId,int appointmentId,int memberId,String firstName,String lastName,String image,String imageName,String imageFormat,String pDob,int locationId,int practiceId,int providerId ) async {
    String apiUrl = ApiUrlConstants.saveDictations;
    DateTime defaultDate = DateTime.now();
    var todayDate = defaultDate.millisecond;
    print(apiUrl);

    final json = {
      "header": {
        "status": "string",
        "statusCode": "string",
        "statusMessage": "string"
      },
      "id": null,
      "dictationId": null,
      "episodeId": episodeId??null,
      "episodeAppointmentRequestId": appointmentId??null,
      "attachmentName": null,
      "attachmentContent": null,
      "attachmentSizeBytes": null,
      "attachmentType": null,
      "memberId": memberId??null,
      "statusId": 107,
      "fileName": null,
      // "createdBy": 10,
      "createdDate": AppConstants.parseDate(-1, AppConstants.MMDDYYYY,
              dateTime: defaultDate) ??
          null,
      "uploadedToServer": true,
      "rejectionComments": null,
      "memberRoleId": null,
      "providerId": null,
      "attachmentPhysicalFileName": null,
      "patientFirstName": firstName??null,
      "patientLastName": lastName??null,
      "patientDOB": pDob??null,
      "dos": null,
      "practiceId": practiceId??null,
      "locationId": locationId??null,
      "cptCodeIds": null,
      "appointmentTypeId": null,
      "displayFileName": null,
      "isW9Doc": true,
      "consolidatedDocExists": true,
      "memberPhotos": [
        {
          "header": {
            "status": "string",
            "statusCode": "string",
            "statusMessage": "string"
          },
          "content": image,
          "name": imageName,
          "attachmentType": imageFormat
        }
      ],
      "photoNameList": null,
      "dictationTypeId": null,
      "nbrMemberId": null,
      "nbrMemberName": null,
      "isStatFile": null,
      "externalDocumentUploadId": null,
      "isEmergencyAddOn": false,
      "externalDocumentTypeId": null,
      "description": null,
      "appointmentProvider": null
    };

    ///checking  response status of Api on success and failure
    try {
      http.Response response = await http.post(
        apiUrl,
        body: jsonEncode(json),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      var jsonResponse = jsonDecode(response.body);
      return PostDictationsModel.fromJson(jsonResponse);

    } catch (e) {
      print("This Is => $e");
    }
  }
}


