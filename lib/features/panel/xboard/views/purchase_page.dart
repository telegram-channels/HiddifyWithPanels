import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/utils/price_widget.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/purchase_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/views/components/dialog/purchase_details_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final purchaseViewModelProvider = ChangeNotifierProvider(
  (ref) => PurchaseViewModel(purchaseService: PurchaseService()),
);

class PurchasePage extends ConsumerStatefulWidget {
  const PurchasePage({super.key});

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends ConsumerState<PurchasePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseViewModelProvider).fetchPlans();
    });
  }

  // 支付处理：跳转到支付接口
  Future<void> _handlePayment(
      Plan plan, BuildContext context, Translations t, WidgetRef ref) async {
    final paymentResult = await PurchaseService().pay(plan, context);
    if (paymentResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(paymentResult.message ?? t.purchase.paymentSuccess)),
      );
      // 可选：支付成功后刷新订单等逻辑
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(paymentResult.message ?? t.purchase.paymentFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final viewModel = ref.watch(purchaseViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.purchase.pageTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.push('/order');
            },
            child: Text(
              t.order.title,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(purchaseViewModelProvider).fetchPlans();
        },
        child: Builder(
          builder: (context) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (viewModel.errorMessage != null) {
              return Center(
                child: Text(
                  '${t.purchase.fetchPlansError} ${viewModel.errorMessage}',
                ),
              );
            } else if (viewModel.plans.isEmpty) {
              return Center(child: Text(t.purchase.noPlans));
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: viewModel.plans.length,
                itemBuilder: (context, index) {
                  final plan = viewModel.plans[index];
                  return _buildPlanCard(plan, t, context, ref);
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    Plan plan,
    Translations t,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildUniformStyledContent(plan.content ?? t.purchase.noData),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PriceWidget(
                  plan: plan,
                  priceLabel: t.purchase.priceLabel,
                  currency: t.purchase.rmb,
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _handlePayment(plan, context, t, ref);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    t.purchase.subscribe,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniformStyledContent(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              // const Icon(
              //   FluentIcons.checkmark_circle_24_filled,
              //   color: Colors.blue,
              //   size: 20,
              // ),
              // const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.trim(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
