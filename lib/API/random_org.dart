import 'dart:convert';

import 'package:http/http.dart' as http;

class RandomOrgAPI {
  Future<http.Response> getRandom() async {
    var url = Uri.https("api.random.org", "/json-rpc/2/invoke");
    var body = json.encode({
      "jsonrpc": "2.0",
      "method": "generateSignedIntegers",
      "params": {
        "apiKey": "4eab55c8-cf24-4df4-ae6d-5ee69ad9adcf",
        "n": 8,
        "min": 1,
        "max": 16,
        "replacement": true
      },
      "id": 1
    });

    Map<String, String> headers = {'Content-type': 'application/json'};
    final response = await http.post(url, body: body, headers: headers);
    return response;
  }

  Future<http.Response> verifySignature(String body) async {
    var url = Uri.https("api.random.org", "/json-rpc/2/invoke");
    Map<String, String> headers = {'Content-type': 'application/json'};
    final response = await http.post(url, body: body, headers: headers);
    return response;
  }
}
