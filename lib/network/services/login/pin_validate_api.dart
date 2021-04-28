import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/network/models/login/pin_validate_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PinRepo {
  Future<PinResponse> postApiMethod(String memberId, String pin) async {
    var client = http.Client();
    try {
      
      var endpointUrl = ApiUrlConstants.getUserValidate;
      Map<String, dynamic> queryParams = {
        'MemberId': memberId,
        'Pin': pin,
        "FingerPrintValidation": "false",
      };
      String queryString = Uri(queryParameters: queryParams).query;
      var requestUrl = endpointUrl + '?' + queryString;
      print('requestUrl $requestUrl');

      final response = await client.get(Uri.encodeFull(requestUrl),
          headers: {"Accept": "application/json"});
     // print(response.body);

      if (response.statusCode == 200) {
        PinResponse pinResponse = parsePinResponse(response.body);
        //print(pinResponse);
        return pinResponse;
      }
    } catch (e) {
      print(e.toString());
      throw(e);
    }   finally {
      client.close();
    }
  }

  static PinResponse parsePinResponse(String responseBody) {
    final PinResponse pinResponse =
        PinResponse.fromJson(jsonDecode(responseBody));
    return pinResponse;
  }
}
