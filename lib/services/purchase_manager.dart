import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../state/export_access_state.dart';

enum PurchaseFlowStatus { idle, pending, success, error }

/// PurchaseManager must be registered as a single ChangeNotifierProvider
/// at the app root and initialized once at startup via initialize().
class PurchaseManager extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;

  static const homeUnlockId = 'home_unlock_credit';
  static const unlimitedYearlyId = 'unlimited_yearly';

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  List<String> pendingHomeIds = [];

  // Callback fired after a successful purchase with the list of unlocked home IDs.
  // Set this before calling buy*, and clear it after use.
  Function(List<String>)? onUnlockListener;

  PurchaseFlowStatus _status = PurchaseFlowStatus.idle;
  PurchaseFlowStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == PurchaseFlowStatus.pending;

  void setOnUnlockListener(Function(List<String>) listener) {
    onUnlockListener = listener;
  }

  /// Call once at app startup from main() or your root widget's initState.
  Future<void> initialize(BuildContext context) async {
    // Cancel any existing subscription before re-initializing
    await _subscription?.cancel();

    final response = await _iap.queryProductDetails({homeUnlockId, unlimitedYearlyId});
    _products = response.productDetails;
    debugPrint('Products loaded: ${_products.map((p) => p.id).toList()}');
    debugPrint('Not found: ${response.notFoundIDs}');

    _subscription = _iap.purchaseStream.listen(
      (purchases) => _handlePurchaseUpdates(purchases, context),
      onError: (error) {
        _status = PurchaseFlowStatus.error;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> buyHomeUnlock(String homeId) async {
    pendingHomeIds = [homeId];
    _status = PurchaseFlowStatus.pending;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = _products.firstWhere(
        (p) => p.id == homeUnlockId,
        orElse: () => throw Exception('Product $homeUnlockId not found. Check App Store Connect product ID.'),
      );
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      _status = PurchaseFlowStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> buyUnlimitedYearly(List<String> allHomeIds) async {
    pendingHomeIds = allHomeIds;
    _status = PurchaseFlowStatus.pending;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = _products.firstWhere(
        (p) => p.id == unlimitedYearlyId,
        orElse: () => throw Exception('Product $unlimitedYearlyId not found. Check App Store Connect product ID.'),
      );
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      _status = PurchaseFlowStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
    BuildContext context,
  ) async {
    for (final purchase in purchases) {
      debugPrint('IAP event: ${purchase.productID} status: ${purchase.status}');
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // IAP sheet is open / Apple is processing — keep showing loading
          _status = PurchaseFlowStatus.pending;
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchase, context);
          break;

        case PurchaseStatus.error:
          _status = PurchaseFlowStatus.error;
          _errorMessage = purchase.error?.message ?? 'Purchase failed';
          pendingHomeIds.clear();
          onUnlockListener = null;
          notifyListeners();
          // Still must complete errored purchases
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          _status = PurchaseFlowStatus.idle;
          pendingHomeIds.clear();
          notifyListeners();
          break;
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchase,
    BuildContext context,
  ) async {
    if (!context.mounted) return;

    final exportAccess = context.read<ExportAccessState>();

    // Handle subscription expiry for the yearly plan
    if (purchase.productID == unlimitedYearlyId) {
      final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(purchase.transactionDate ?? '') ?? DateTime.now().millisecondsSinceEpoch,
      );
      final expiry = purchaseDate.add(const Duration(days: 365));
      await exportAccess.setSubscriptionExpiry(expiry);
    }

    // Unlock all pending homes in persistent state
    final unlockedIds = List<String>.from(pendingHomeIds);
    for (final id in unlockedIds) {
      await exportAccess.unlockHome(id);
    }

    _status = PurchaseFlowStatus.success;
    pendingHomeIds.clear();
    notifyListeners();

    // Fire the callback — this is what dismisses the dialog and navigates to PDF
    final listener = onUnlockListener;
    onUnlockListener = null; // clear before calling to avoid double-fire
    if (listener != null) {
      listener(unlockedIds);
    }

    // Complete the transaction with Apple
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }

    // Reset to idle after a short delay so consumers can react to success first
    await Future.delayed(const Duration(milliseconds: 300));
    _status = PurchaseFlowStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}