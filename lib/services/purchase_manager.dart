import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../state/export_access_state.dart';

class PurchaseManager {
  final InAppPurchase _iap = InAppPurchase.instance;

  // Product IDs from App Store Connect
  static const homeUnlockId = 'home_unlock_credit';
  static const unlimitedYearlyId = 'unlimited_yearly';

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];

  // Track which homes to unlock after purchase
  List<String> pendingHomeIds = [];

  // Optional callback when unlock completes (e.g., close dialog or navigate)
  Function(List<String>)? onUnlockListener;

  void setOnUnlockListener(Function(List<String>) listener) {
    onUnlockListener = listener;
  }

  /// Initialize once at app startup
  Future<void> initialize(BuildContext context) async {
    // Query product details
    final response = await _iap.queryProductDetails(
      {homeUnlockId, unlimitedYearlyId},
    );

    _products = response.productDetails;

    // Subscribe to purchase updates
    _subscription = _iap.purchaseStream.listen(
      (purchases) => _handlePurchaseUpdates(purchases, context),
    );
  }

  /// Buy a single home unlock
  Future<void> buyHomeUnlock(String homeId) async {
    pendingHomeIds = [homeId];

    final product = _products.firstWhere((p) => p.id == homeUnlockId);

    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Buy annual unlimited homes
  Future<void> buyUnlimitedYearly(List<String> allHomeIds) async {
    pendingHomeIds = allHomeIds;

    final product = _products.firstWhere((p) => p.id == unlimitedYearlyId);

    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Internal handler for purchase updates
  void _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
    BuildContext context) async {

  for (final purchase in purchases) {
    if (purchase.status == PurchaseStatus.purchased) {

      final exportAccess = context.read<ExportAccessState>();

      // Unlock homes if any are pending
      if (pendingHomeIds.isNotEmpty &&
          (purchase.productID == homeUnlockId || purchase.productID == unlimitedYearlyId)) {

        for (final id in pendingHomeIds) {
          await exportAccess.unlockHome(id);
        }

        // Notify listener if set
        if (onUnlockListener != null) {
          onUnlockListener!(pendingHomeIds);
        }

        // Force UI rebuild
        exportAccess.notifyListeners();

        // Clear pending homes
        pendingHomeIds.clear();
      }

      // Handle subscription expiry for unlimited yearly
      if (purchase.productID == unlimitedYearlyId) {
        final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
          int.parse(purchase.transactionDate ?? '0'),
        );
        final expiry = purchaseDate.add(const Duration(days: 365));

        await exportAccess.setSubscriptionExpiry(expiry);

        // Force UI rebuild so all homes bypass unlock
        exportAccess.notifyListeners();
      }

      // Complete the purchase
      await _iap.completePurchase(purchase);
    }
  }
}

  void dispose() {
    _subscription.cancel();
  }
}