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
  Function(List<String>)? onUnlockListener;

  // KEY FIX: only true after the user taps a buy button.
  // Prevents stale sandbox transactions replayed on startup from
  // triggering navigation before the user has done anything.
  bool _isUserInitiatedPurchase = false;

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
    await _subscription?.cancel();

    final response = await _iap.queryProductDetails({homeUnlockId, unlimitedYearlyId});
    _products = response.productDetails;

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
    _isUserInitiatedPurchase = true;
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
      _isUserInitiatedPurchase = false;
      _status = PurchaseFlowStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> buyUnlimitedYearly(List<String> allHomeIds) async {
    pendingHomeIds = allHomeIds;
    _isUserInitiatedPurchase = true;
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
      _isUserInitiatedPurchase = false;
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
      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (_isUserInitiatedPurchase) {
            _status = PurchaseFlowStatus.pending;
            notifyListeners();
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_isUserInitiatedPurchase) {
            // Real purchase the user just made — unlock and navigate
            await _handleSuccessfulPurchase(purchase, context);
          } else {
            // Stale transaction replayed from a previous session on startup.
            // Still complete it to clear Apple's queue, but do NOT
            // unlock homes or fire the navigation callback.
            debugPrint('PurchaseManager: completing stale transaction ${purchase.productID}');
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
          }
          break;

        case PurchaseStatus.error:
          _isUserInitiatedPurchase = false;
          _status = PurchaseFlowStatus.error;
          _errorMessage = purchase.error?.message ?? 'Purchase failed';
          pendingHomeIds.clear();
          onUnlockListener = null;
          notifyListeners();
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          _isUserInitiatedPurchase = false;
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

    if (purchase.productID == unlimitedYearlyId) {
      final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(purchase.transactionDate ?? '') ?? DateTime.now().millisecondsSinceEpoch,
      );
      final expiry = purchaseDate.add(const Duration(days: 365));
      await exportAccess.setSubscriptionExpiry(expiry);
    }

    final unlockedIds = List<String>.from(pendingHomeIds);
    for (final id in unlockedIds) {
      await exportAccess.unlockHome(id);
    }

    _isUserInitiatedPurchase = false;
    _status = PurchaseFlowStatus.success;
    pendingHomeIds.clear();
    notifyListeners();

    // Fire the callback — dismisses dialog and navigates to PDF
    final listener = onUnlockListener;
    onUnlockListener = null;
    if (listener != null) {
      listener(unlockedIds);
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }

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