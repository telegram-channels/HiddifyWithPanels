import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/payment_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/plan_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// 支付结果类型
class PaymentResult {
  final bool success;
  final String? message;
  PaymentResult({required this.success, this.message});
}

class PurchaseService {
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

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

  /// 新版 pay 方法
  /// 创建订单，获取支付URL，然后调起支付页面
  Future<PaymentResult> pay(Plan plan, BuildContext context) async {
    final accessToken = await getToken();
    if (accessToken == null) {
      return PaymentResult(success: false, message: "未获取到Token");
    }

    try {
      // 以第一个 period 作为示例，可根据实际业务调整
      final period = plan.periods?.isNotEmpty == true ? plan.periods!.first : null;
      if (period == null) {
        return PaymentResult(success: false, message: "套餐周期未知");
      }

      // 1. 创建订单
      final orderResp = await createOrder(plan.id, period, accessToken);
      if (orderResp == null || orderResp['data'] == null) {
        return PaymentResult(success: false, message: "下单失败");
      }
      final tradeNo = orderResp['data'].toString();

      // 2. 查询支付方式（假设第一个为 EPay，可根据你的业务选择对应支付方式）
      final payMethods = await getPaymentMethods(accessToken);
      if (payMethods.isEmpty) {
        return PaymentResult(success: false, message: "无可用支付方式");
      }
      final epayMethod = payMethods.firstWhere(
        (m) => m['id'].toString().toLowerCase() == 'epay',
        orElse: () => payMethods.first,
      );

      // 3. 提交支付，获取支付跳转URL
      final resp = await submitOrder(tradeNo, epayMethod['id'].toString(), accessToken);
      if (resp['type'] == 1 && resp['data'] != null) {
        final payUrl = resp['data'].toString();
        final uri = Uri.tryParse(payUrl);

        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return PaymentResult(success: true, message: "已跳转到支付页面");
        } else {
          return PaymentResult(success: false, message: "无法打开支付链接");
        }
      } else {
        return PaymentResult(success: false, message: resp['message'] ?? "支付接口异常");
      }
    } catch (e) {
      return PaymentResult(success: false, message: "支付异常: $e");
    }
  }
}
