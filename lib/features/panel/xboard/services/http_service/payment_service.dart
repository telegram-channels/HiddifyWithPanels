import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class PaymentService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> submitOrder(
      String tradeNo, String method, String accessToken,) async {
    return await _httpService.postRequest(
      "/api/v1/user/order/checkout",
      {"trade_no": tradeNo, "method": method},
      headers: {'Authorization': accessToken},
    );
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/order/getPaymentMethod",
        headers: {'Authorization': accessToken},
      );
      // 建议加日志输出
      print('getPaymentMethods response: $response');

      if (response == null || response['data'] == null) {
        print('支付方式接口返回为空');
        return [];
      }
      // 兼容 data 不是 List 的情况
      final data = response['data'];
      if (data is List) {
        return data;
      } else {
        print('支付方式 data 字段不是 List: $data');
        return [];
      }
    } catch (e) {
      print('获取支付方式异常: $e');
      return [];
    }
  }
}
