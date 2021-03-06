import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_inapp_purchase/modules.dart';

class InAppPurchaseRepository {
  final Dio dio;
  InAppPurchaseRepository({this.dio});

  Future<Map<String, dynamic>> verifyPurchase(
    PurchasedItem purchasedItem,
    IAPItem product,
  ) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final Map<String, dynamic> response = Map<String, dynamic>();
    response['isVerified'] = false;

    await dio.post(
      '/purchases/${purchasedItem.productId}/platforms/$platform/verify',
      data: {
        "purchase": {
          "price": product.price,
          "frequency": product.subscriptionPeriodUnitIOS,
          "transactionId": purchasedItem.transactionId,
          "transactionReceipt": purchasedItem.transactionReceipt,
          "isSubscription": "true",
        }
      },
    ).then((Response result) {
      final purchasedProducts = result.data['data'];
      response['isProUser'] = purchasedProducts.isNotEmpty;
      response['isVerified'] = true;
    }).catchError((error) {
      print(error);
      response['error'] = error.response.data;
    });

    return response;
  }
}
