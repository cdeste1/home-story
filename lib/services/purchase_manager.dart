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

  Timer? _pendingTimer; // tracks the timeout so we can cancel it on success

  PurchaseFlowStatus _status = PurchaseFlowStatus.idle;
  PurchaseFlowStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == PurchaseFlowStatus.pending;

  void setOnUnlockListener(Function(List<String>) listener) {
    onUnlockListener = listener;
  }

  void resetToIdle() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _isUserInitiatedPurchase = false;
    _status = PurchaseFlowStatus.idle;
    pendingHomeIds.clear();
    onUnlockListener = null;
    notifyListeners();
  }

  void _startPendingTimer() {
    _pendingTimer?.cancel();
    // If Apple hasn't responded in 30 seconds, assume canceled/dismissed
    _pendingTimer = Timer(const Duration(seconds: 30), () {
      if (_status == PurchaseFlowStatus.pending) {
        debugPrint('PurchaseManager: timeout — resetting to idle');
        resetToIdle();
      }
    });
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
      _startPendingTimer(); // start timeout after sheet is launched
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
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      _startPendingTimer(); // start timeout after sheet is launched
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
          if (_isUserInitiatedPurchase) {
            _pendingTimer?.cancel(); // real purchase came in — cancel the timeout
            await _handleSuccessfulPurchase(purchase, context);
          } else {
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
          }
          break;

        case PurchaseStatus.restored:
          if (_isRestoreInProgress) {
            await _handleRestoredPurchase(purchase, context);
          } else {
            debugPrint('PurchaseManager: ignoring startup restore of ${purchase.productID}');
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
          }
          break;

        case PurchaseStatus.error:
          _pendingTimer?.cancel();
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
          // Apple fired canceled cleanly — reset immediately
          _pendingTimer?.cancel();
          _isUserInitiatedPurchase = false;
          _status = PurchaseFlowStatus.idle;
          pendingHomeIds.clear();
          onUnlockListener = null;
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
      final expiry = DateTime.now().add(const Duration(days: 365));
      await exportAccess.activateSubscription(expiry);
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

  Future<void> _handleRestoredPurchase(
    PurchaseDetails purchase,
    BuildContext context,
  ) async {
    if (!context.mounted) return;

    final exportAccess = context.read<ExportAccessState>();

    if (purchase.productID == unlimitedYearlyId) {
      final expiry = DateTime.now().add(const Duration(days: 365));
      await exportAccess.activateSubscription(expiry);
    } else if (purchase.productID == homeUnlockId) {
      final homeState = context.read<HomeState>();
      for (final id in homeState.allHomeIds()) {
        await exportAccess.unlockHome(id);
      }
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}