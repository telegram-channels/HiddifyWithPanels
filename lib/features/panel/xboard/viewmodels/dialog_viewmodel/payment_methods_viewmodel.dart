import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'package:hiddify/features/panel/xboard/services/monitor_pay_status.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

class PaymentMethodsViewModel extends ChangeNotifier {
  final String tradeNo;
  final double totalAmount;
  final VoidCallback onPaymentSuccess;
  final PurchaseService _purchaseService = PurchaseService();

  PaymentMethodsViewModel({
    required this.tradeNo,
    required this.totalAmount,
    required this.onPaymentSuccess,
  });

  Future<void> handlePayment(dynamic selectedMethod) async {
    if (selectedMethod == null || selectedMethod is! Map || !selectedMethod.containsKey('id')) {
      if (kDebugMode) {
        print('支付方式无效或未选择。');
      }
      return;
    }

    // 集成EPay：判断是否为epay方式
    if (selectedMethod['id'] == 'epay') {
      await payWithEPay(totalAmount, tradeNo);
      return;
    }

    // 其它支付方式逻辑，保持原有代码
    final accessToken = await getToken();
    if (accessToken == null) {
      if (kDebugMode) {
        print('未获取到有效的 accessToken，无法支付。');
      }
      return;
    }

    try {
      final response = await _purchaseService.submitOrder(
        tradeNo,
        selectedMethod['id'].toString(),
        accessToken,
      );

      if (kDebugMode) {
        print('支付响应: $response');
      }

      final type = response['type'];
      final data = response['data'];

      if (type is int) {
        if (type == -1 && data == true) {
          if (kDebugMode) {
            print('订单已通过钱包余额支付成功，无需跳转支付页面');
          }
          handlePaymentSuccess();
          return;
        }

        if (type == 1 && data is String) {
          if (_isValidUrl(data)) {
            openPaymentUrl(data);
            monitorOrderStatus();
          } else {
            if (kDebugMode) {
              print('支付链接无效: $data');
            }
          }
          return;
        }
      }

      if (kDebugMode) {
        print('支付处理失败: 意外的响应。');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('支付错误: $e');
        print('堆栈: $stack');
      }
    }
  }

  // 易支付专用方法
  Future<void> payWithEPay(double amount, String tradeNo) async {
    try {
      final resp = await http.post(
        Uri.parse('https://88cloud.dpdns.org/api/v1/guest/payment/create/epay'),
        body: {
          'total_amount': (amount * 100).toInt().toString(),
          'trade_no': tradeNo,
          // 不用传return_url
        },
      );

      if (resp.statusCode == 200) {
        final payUrl = jsonDecode(resp.body)['url'];
        if (await canLaunchUrl(Uri.parse(payUrl))) {
          await launchUrl(Uri.parse(payUrl), mode: LaunchMode.externalApplication);
          // 支付跳转后，开始轮询订单状态
          monitorOrderStatus();
        } else {
          if (kDebugMode) print('无法打开支付链接');
        }
      } else {
        if (kDebugMode) print('下单失败：${resp.body}');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('EPay下单异常: $e');
        print('堆栈: $stack');
      }
    }
  }

  void handlePaymentSuccess() {
    if (kDebugMode) {
      print('订单已标记为已支付。');
    }
    onPaymentSuccess();
  }

  Future<void> monitorOrderStatus() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      if (kDebugMode) {
        print('无法监听订单状态: accessToken 为空');
      }
      return;
    }

    MonitorPayStatus().monitorOrderStatus(
      tradeNo,
      accessToken,
      (bool isPaid, {String? message}) {
        if (isPaid) {
          if (kDebugMode) {
            print('订单支付成功');
          }
          handlePaymentSuccess();
        } else {
          if (kDebugMode) {
            print('订单未支付');
            if (message != null) print('支付消息: $message');
          }
        }
      },
    );
  }

  void openPaymentUrl(String paymentUrl) {
    final Uri? url = Uri.tryParse(paymentUrl);
    if (url != null) {
      launchUrl(url);
    } else if (kDebugMode) {
      print('无法解析支付链接: $paymentUrl');
    }
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }
}
