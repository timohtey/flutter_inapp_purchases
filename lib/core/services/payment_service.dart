import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:inapp_purchases/core/repository/inapp_purchase_repository.dart';
import 'package:inapp_purchases/http_client.dart';

class PaymentService {
  /// We want singelton object of ``PaymentService`` so create private constructor
  ///
  /// Use PaymentService as ``PaymentService.instance``
  PaymentService._internal();

  static final PaymentService instance = PaymentService._internal();

  /// To listen the status of the purchase made inside or outside of the app (App Store / Play Store)
  ///
  /// If status is not error then app will be notified by this stream
  StreamSubscription<PurchasedItem> _purchaseUpdatedSubscription;

  /// To listen the errors of the purchase
  StreamSubscription<PurchaseResult> _purchaseErrorSubscription;

  /// List of product ids you want to fetch
  final List<String> _productIds = ['test_inapp_purchase'];

  /// All available products will be store in this list
  List<IAPItem> _products;

  /// All past purchases will be store in this list
  List<PurchasedItem> _pastPurchases;

  /// view of the app will subscribe to this to get notified
  /// when premium status of the user changes
  ObserverList<Function> _proStatusChangedListeners =
      new ObserverList<Function>();

  /// view of the app will subscribe to this to get errors of the purchase
  ObserverList<Function(String)> _errorListeners =
      new ObserverList<Function(String)>();

  /// logged in user's premium status
  bool _isProUser = false;

  bool get isProUser => _isProUser;

  /// Call this method at the startup of you app to initialize connection
  /// with billing server and get all the necessary data
  Future<void> initConnection() async {
    await FlutterInappPurchase.instance.initConnection;

    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen(_handlePurchaseUpdate);

    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen(_handlePurchaseError);

    await _getItems();
    _getPastPurchases();
  }

  void dispose() {
    _purchaseErrorSubscription.cancel();
    _purchaseUpdatedSubscription.cancel();
    FlutterInappPurchase.instance.endConnection;
  }

  Future<List<IAPItem>> get products async {
    if (_products == null) {
      await _getItems();
    }
    return _products;
  }

  Future<void> _getItems() async {
    List<IAPItem> items =
        await FlutterInappPurchase.instance.getSubscriptions(_productIds);

    _products = [];
    for (var item in items) {
      this._products.add(item);
    }
  }

  void _getPastPurchases() async {
    List<PurchasedItem> purchasedItems =
        await FlutterInappPurchase.instance.getAvailablePurchases();

    for (var purchasedItem in purchasedItems) {
      bool isValid = false;

      if (Platform.isAndroid) {
        // if your app missed finishTransaction due to network or crash issue
        // finish transactins
        if (purchasedItem.isAcknowledgedAndroid) {
          isValid = await _verifyPurchase(purchasedItem);
          if (isValid) {
            FlutterInappPurchase.instance.finishTransaction(purchasedItem);
            _isProUser = true;
            _callProStatusChangedListeners();
          }
        } else {
          _isProUser = true;
          _callProStatusChangedListeners();
        }
      }
    }

    _pastPurchases = [];
    _pastPurchases.addAll(purchasedItems);
  }

  void _handlePurchaseError(PurchaseResult purchaseError) {
    _callErrorListeners(purchaseError.message);
  }

  void _handlePurchaseUpdate(PurchasedItem productItem) async {
    if (Platform.isAndroid) {
      await _handlePurchaseUpdateAndroid(productItem);
    } else {
      await _handlePurchaseUpdateIOS(productItem);
    }
  }

  Future<void> _handlePurchaseUpdateIOS(PurchasedItem purchasedItem) async {
    switch (purchasedItem.transactionStateIOS) {
      case TransactionState.failed:
        _callErrorListeners("Transaction Failed");
        FlutterInappPurchase.instance.finishTransaction(purchasedItem);
        break;
      case TransactionState.purchased:
        await _verifyAndFinishTransaction(purchasedItem);
        break;
      case TransactionState.restored:
        FlutterInappPurchase.instance.finishTransaction(purchasedItem);
        break;
      default:
        break;
    }
  }

  Future<void> _handlePurchaseUpdateAndroid(PurchasedItem purchasedItem) async {
    switch (purchasedItem.purchaseStateAndroid) {
      case PurchaseState.purchased:
        if (!purchasedItem.isAcknowledgedAndroid)
          await _verifyAndFinishTransaction(purchasedItem);
        break;
      default:
        _callErrorListeners("Something went wrong");
    }
  }

  Future<void> buyProduct(IAPItem item) async {
    try {
      await FlutterInappPurchase.instance.requestSubscription(item.productId);
    } catch (error) {
      _callErrorListeners("Something went wrong: $error");
    }
  }

  /// Call this method when status of purchase is success
  /// Call API of your back end to verify the reciept
  /// back end has to call billing server's API to verify the purchase token
  _verifyAndFinishTransaction(PurchasedItem purchasedItem) async {
    bool isValid = false;

    isValid = await _verifyPurchase(purchasedItem);

    if (isValid) {
      FlutterInappPurchase.instance.finishTransaction(purchasedItem);
      _isProUser = true;
      // save in sharedPreference here
      _callProStatusChangedListeners();
    }
  }

  /// view can subscribe to _proStatusChangedListeners using this method
  addToProStatusChangedListeners(Function callback) {
    _proStatusChangedListeners.add(callback);
  }

  /// view can cancel to _proStatusChangedListeners using this method
  removeFromProStatusChangedListeners(Function callback) {
    _proStatusChangedListeners.remove(callback);
  }

  /// view can subscribe to _errorListeners using this method
  addToErrorListeners(Function callback) {
    _errorListeners.add(callback);
  }

  /// view can cancel to _errorListeners using this method
  removeFromErrorListeners(Function callback) {
    _errorListeners.remove(callback);
  }

  /// Call this method to notify all the subsctibers of _proStatusChangedListeners
  void _callProStatusChangedListeners() {
    _proStatusChangedListeners.forEach((Function callback) {
      callback();
    });
  }

  /// Call this method to notify all the subsctibers of _errorListeners
  void _callErrorListeners(String error) {
    _errorListeners.forEach((Function callback) {
      callback(error);
    });
  }

  Future<bool> _verifyPurchase(PurchasedItem purchasedItem) async {
    final httpClient = HttpClient();
    final inAppPurchaseRepository = InAppPurchaseRepository(
      dio: httpClient.getClient(),
    );
    final response = await inAppPurchaseRepository.verifyPurchase(
      purchasedItem,
    );

    if (response['error'] != null) _callErrorListeners(response['error']);

    return response['isVerified'];
  }
}
