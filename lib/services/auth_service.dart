import '../core/api_client.dart';

class AuthService {
  final _client = ApiClient();

  Future<int> login(String username, String pin) async {
    final data = await _client.post('/scanner/login', {
      "userName": username,
      "pin": pin,
    });

    if (data["success"] == true) {
      return data["data"]["uid"] as int;
    }

    throw Exception(data["message"] ?? "Login failed");
  }
}
