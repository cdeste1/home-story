import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../state/export_access_state.dart';
import '../state/home_state.dart';


enum PurchaseFlowStatus { idle, pending, success, error }

class PurchaseManager extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;

  static const homeUnlockId = 'home_unlock_credit';
  static const unlimitedYearlyId = 'unlimited_annual';

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  List<String> pendingHomeIds = [];
  Function(List<String>)? onUnlockListener;

  bool _isUserInitiatedPurchase = false;
  bool _isRestoreInProgress = false;

  PurchaseFlowStatus _status = PurchaseFlowStatus.idle;
  PurchaseFlowStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == PurchaseFlowStatus.pending;

  void setOnUnlockListener(Function(List<String>) listener) {
    onUnlockListener = listener;
  }

  void resetToIdle() {
    _isUserInitiatedPurchase = false;
    _status = PurchaseFlowStatus.idle;
    pendingHomeIds.clear();
    onUnlockListener = null;
    notifyListeners();
  }

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
        orElse: () => throw Exception('Product $homeUnlockId not found.'),
      );
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      // Timeout fallback in case Apple never fires canceled
      Future.delayed(const Duration(seconds: 60), () {
        if (_status == PurchaseFlowStatus.pending) resetToIdle();
      });
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
        orElse: () => throw Exception('Product $unlimitedYearlyId not found.'),
      );
      // Use buyNonConsumable — the in_app_purchase plugin uses the same call
      // for auto-renewable subscriptions. Apple handles renewal automatically.
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      // Timeout fallback in case Apple never fires canceled
      Future.delayed(const Duration(seconds: 60), () {
        if (_status == PurchaseFlowStatus.pending) resetToIdle();
      });
    } catch (e) {
      _isUserInitiatedPurchase = false;
      _status = PurchaseFlowStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Call this from the Restore Purchases button in settings.
  Future<void> restorePurchases() async {
    _isRestoreInProgress = true;
    await _iap.restorePurchases();
    // Reset flag after stream has time to deliver restored transactions
    await Future.delayed(const Duration(seconds: 3));
    _isRestoreInProgress = false;
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
          // Only handle if the user actually tapped a buy button
          if (_isUserInitiatedPurchase) {
            await _handleSuccessfulPurchase(purchase, context);
          } else {
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
          }
          break;

        case PurchaseStatus.restored:
          // Only handle restores when user explicitly tapped Restore Purchases
          if (_isRestoreInProgress) {
            await _handleRestoredPurchase(purchase, context);
          } else {
            // Automatic startup replay — just complete it, don't unlock anything
            debugPrint('PurchaseManager: ignoring startup restore of ${purchase.productID}');
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
          onUnlockListener = null;
          notifyListeners();
          break;
      }
    }
  }

  /// Handles a brand new purchase the user just completed.
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchase,
    BuildContext context,
  ) async {
    if (!context.mounted) return;

    final exportAccess = context.read<ExportAccessState>();

    if (purchase.productID == unlimitedYearlyId) {
      // Activate subscription with 1 year expiry from now
      final expiry = DateTime.now().add(const Duration(days: 365));
      await exportAccess.activateSubscription(expiry);
      // For a subscription, unlock all homes
      for (final id in pendingHomeIds) {
        await exportAccess.unlockHome(id);
      }
    } else if (purchase.productID == homeUnlockId) {
      for (final id in pendingHomeIds) {
        await exportAccess.unlockHome(id);
      }
    }

    final unlockedIds = List<String>.from(pendingHomeIds);
    _isUserInitiatedPurchase = false;
    _status = PurchaseFlowStatus.success;
    pendingHomeIds.clear();
    notifyListeners();

    // Fire callback — dismisses dialog and navigates to PDF
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

  /// Handles a purchase restored via the Restore Purchases button.
  Future<void> _handleRestoredPurchase(
    PurchaseDetails purchase,
    BuildContext context,
  ) async {
    if (!context.mounted) return;

    final exportAccess = context.read<ExportAccessState>();

    if (purchase.productID == unlimitedYearlyId) {
      // For a restored subscription we don't know the exact expiry from
      // the plugin — set 1 year from now as a best estimate.
      // For production, use receipt validation to get the real expiry.
      final expiry = DateTime.now().add(const Duration(days: 365));
      await exportAccess.activateSubscription(expiry);
    } else if (purchase.productID == homeUnlockId) {
      // For a restored home unlock, we don't know which home it was for
      // (the purchase doesn't carry that info). We can't know which specific home was originally unlocked,
      // so unlock all current homes as a fair restoration.
        final homeState = context.read<HomeState>();
        for (final id in homeState.allHomeIds()) {
          await exportAccess.unlockHome(id);
        }
      //debugPrint('PurchaseManager: restored home unlock — cannot determine home ID');
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}