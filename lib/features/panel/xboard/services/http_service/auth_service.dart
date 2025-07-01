import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class AuthService {
  final HttpService _httpService = HttpService();

  /// 登录
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return {"error": "邮箱和密码不能为空"};
    }
    return await _httpService.postRequest(
      "/api/v1/passport/auth/login",
      {"email": email, "password": password},
    );
  }

  /// 注册
  Future<Map<String, dynamic>> register(
      String email, String password, String inviteCode, String emailCode) async {
    if (email.isEmpty || password.isEmpty || inviteCode.isEmpty || emailCode.isEmpty) {
      return {"error": "所有字段都不能为空"};
    }
    return await _httpService.postRequest(
      "/api/v1/passport/auth/register",
      {
        "email": email,
        "password": password,
        "invite_code": inviteCode,
        "email_code": emailCode,
      },
    );
  }

  /// 发送邮箱验证码
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    if (email.isEmpty) {
      return {"error": "邮箱不能为空"};
    }
    return await _httpService.postRequest(
      "/api/v1/passport/comm/sendEmailVerify",
      {'email': email},
    );
  }

  /// 重置密码
  Future<Map<String, dynamic>> resetPassword(
      String email, String password, String emailCode) async {
    if (email.isEmpty || password.isEmpty || emailCode.isEmpty) {
      return {"error": "所有字段都不能为空"};
    }
    return await _httpService.postRequest(
      "/api/v1/passport/auth/forget",
      {
        "email": email,
        "password": password,
        "email_code": emailCode,
      },
    );
  }
}
