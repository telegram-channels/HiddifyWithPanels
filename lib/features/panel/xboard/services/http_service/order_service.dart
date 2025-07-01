// services/order_service.dart
import 'package:hiddify/features/panel/xboard/models/order_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class OrderService {
  final HttpService _httpService = HttpService();

  Future<List<Order>> fetchUserOrders(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/order/fetch",
      headers: {'Authorization': accessToken},
    );

    if (result["status"] == "success") {
      final ordersJson = result["data"];
      if (ordersJson is List) {
        return ordersJson
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print("ordersJson 不是 List: $ordersJson");
        return [];
      }
    } else {
      final msg = result['message'] ?? "未知错误";
      print("Failed to fetch user orders: $msg");
      throw Exception("Failed to fetch user orders: $msg");
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(
      String tradeNo, String accessToken) async {
    try {
      return await _httpService.getRequest(
        "/api/v1/user/order/detail?trade_no=$tradeNo",
        headers: {'Authorization': accessToken},
      );
    } catch (e) {
      print("getOrderDetails error: $e");
      throw Exception("获取订单详情失败: $e");
    }
  }

  Future<Map<String, dynamic>> cancelOrder(
      String tradeNo, String accessToken) async {
    try {
      return await _httpService.postRequest(
        "/api/v1/user/order/cancel",
        {"trade_no": tradeNo},
        headers: {'Authorization': accessToken},
      );
    } catch (e) {
      print("cancelOrder error: $e");
      throw Exception("取消订单失败: $e");
    }
  }

  Future<Map<String, dynamic>> createOrder(
      String accessToken, int planId, String period) async {
    try {
      return await _httpService.postRequest(
        "/api/v1/user/order/save",
        {"plan_id": planId, "period": period},
        headers: {'Authorization': accessToken},
      );
    } catch (e) {
      print("createOrder error: $e");
      throw Exception("创建订单失败: $e");
    }
  }
}
