import 'dart:convert';
import 'package:YOURDRS_FlutterAPP/common/app_strings.dart';
import 'package:YOURDRS_FlutterAPP/network/models/login/login_model.dart';
import 'package:http/http.dart' as http;

class LoginApiServices {
  /// passing the controller valued in service
  Future<AuthenticateUser> LoginpostApiMethod(String name, String password) async {
    String apiUrl = ApiUrlConstants.getUser;
    // print('requestUrl $apiUrl');

    final json = {
      "userName": name,
      "password": password,
    };

    http.Response response = await http.post(
      apiUrl,
      body: jsonEncode(json),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    var jsonResponse = jsonDecode(response.body);
    return AuthenticateUser.fromJson(jsonResponse);
  }
}
