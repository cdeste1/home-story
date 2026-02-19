import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../state/export_access_state.dart';

class PurchaseManager {
  final InAppPurchase _iap = InAppPurchase.instance;

  static const homeUnlockId = 'home_unlock_credit';
  static const unlimitedYearlyId = 'unlimited_yearly';

  late StreamSubscription<List<PurchaseDetails>> _subscription;

  List<ProductDetails> _products = [];

  String? _pendingHomeId;

  Future<void> initialize(BuildContext context) async {
    final response = await _iap.queryProductDetails(
      {homeUnlockId, unlimitedYearlyId},
    );

    _products = response.productDetails;

    _subscription = _iap.purchaseStream.listen(
      (purchases) => _handlePurchaseUpdates(purchases, context),
    );
  }

  Future<void> buyHomeUnlock(String homeId) async {
    _pendingHomeId = homeId;

    final product =
        _products.firstWhere((p) => p.id == homeUnlockId);

    _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> buyUnlimitedYearly() async {
    final product =
        _products.firstWhere((p) => p.id == unlimitedYearlyId);

    _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  void _handlePurchaseUpdates(
      List<PurchaseDetails> purchases,
      BuildContext context) async {

    for (final purchase in purchases) {

      if (purchase.status == PurchaseStatus.purchased) {

        if (purchase.productID == homeUnlockId &&
            _pendingHomeId != null) {

          await context
              .read<ExportAccessState>()
              .unlockHome(_pendingHomeId!);

          _pendingHomeId = null;
        }

        if (purchase.productID == unlimitedYearlyId) {

          // 1 year from purchase date
          final purchaseDate =
              DateTime.fromMillisecondsSinceEpoch(
                  int.parse(purchase.transactionDate ?? '0'));

          final expiry = purchaseDate.add(
            const Duration(days: 365),
          );

          await context
              .read<ExportAccessState>()
              .setSubscriptionExpiry(expiry);
        }


        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
