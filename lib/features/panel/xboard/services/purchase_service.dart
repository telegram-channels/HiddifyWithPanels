import 'package:flutter/material.dart';

import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/payment_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/plan_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

// 支付结果类型
class PaymentResult {
  final bool success;
  final String? message;
  PaymentResult({required this.success, this.message});
}

class PurchaseService {
  Future<List<Plan>> fetchPlanData() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("No access token found.");
      return [];
    }

    return await PlanService().fetchPlanData(accessToken);
  }

  Future<void> addSubscription(
    BuildContext context,
    String accessToken,
    WidgetRef ref,
    Function showSnackbar,
  ) async {
    Subscription.updateSubscription(context, ref);
  }

  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  Future<Map<String, dynamic>?> createOrder(
      int planId, String period, String accessToken) async {
    return await _orderService.createOrder(accessToken, planId, period);
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    return await _paymentService.getPaymentMethods(accessToken);
  }

  Future<Map<String, dynamic>> submitOrder(
      String tradeNo, String method, String accessToken) async {
    return await _paymentService.submitOrder(tradeNo, method, accessToken);
  }

  // 新增的 pay 方法
  Future<PaymentResult> pay(Plan plan) async {
    // 你可以在这里实现具体的支付流程
    // 这里只做示例，始终返回成功
    await Future.delayed(Duration(seconds: 1)); // 模拟耗时
    return PaymentResult(success: true, message: "Mock payment success");
  }
}
