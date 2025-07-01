import 'dart:async';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';

class MonitorPayStatus {
  // 监控订单状态，轮询20分钟后停止
  Future<void> monitorOrderStatus(
    String tradeNo,
    String accessToken,
    Function(bool, {String? message}) onPaymentStatusChanged,
  ) async {
    bool isPaymentComplete = false;
    const int maxPollingDuration = 20 * 60; // 20 minutes in seconds
    int elapsedTime = 0;

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (isPaymentComplete || elapsedTime >= maxPollingDuration) {
        timer.cancel();
        if (!isPaymentComplete) {
          onPaymentStatusChanged(false, message: "支付超时");
        }
        return;
      }

      elapsedTime += 10;

      try {
        final orderDetails = await getOrderDetails(tradeNo, accessToken);

        if (orderDetails == null) {
          print("orderDetails 为空");
          onPaymentStatusChanged(false, message: "未能获取订单信息");
          return;
        }

        if (orderDetails['status'] == 'success') {
          final orderData = orderDetails['data'];
          final status = orderData?['status'];

          // 健壮性判断
          if (status == null) {
            print("订单状态为空: $orderData");
            onPaymentStatusChanged(false, message: "订单状态异常");
            return;
          }

          if (status == 2) {
            // 订单取消
            isPaymentComplete = true;
            timer.cancel();
            onPaymentStatusChanged(false, message: "订单已取消");
            return;
          } else if (status == 3) {
            // 已支付
            isPaymentComplete = true;
            timer.cancel();
            onPaymentStatusChanged(true, message: "支付成功");
            return;
          } else if (status == 0) {
            // 未支付
            onPaymentStatusChanged(false, message: "待支付");
          } else {
            print("未知订单状态: $status");
            onPaymentStatusChanged(false, message: "未知订单状态($status)");
          }
        } else {
          final msg = orderDetails['message'] ?? '未知错误';
          print("Failed to get valid order status: $msg");
          onPaymentStatusChanged(false, message: msg);
        }
      } catch (e) {
        print("Error while checking order status: $e");
        onPaymentStatusChanged(false, message: "查询订单异常: $e");
      }
    });
  }

  // 获取订单详情的函数
  Future getOrderDetails(String tradeNo, String accessToken) async {
    try {
      final orderDetails =
          await OrderService().getOrderDetails(tradeNo, accessToken);
      return orderDetails;
    } catch (e) {
      print("getOrderDetails error: $e");
      return null;
    }
  }
}
