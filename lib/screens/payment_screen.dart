import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:inapp_purchases/shared/alert_dialog.dart';
import 'package:inapp_purchases/core/services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService paymentService = PaymentService.instance;
  bool _purchasing = false;
  bool _loading = true;
  IAPItem _product;

  @override
  void initState() {
    super.initState();
    _getProducts();
  }

  void _getProducts() async {
    await paymentService.initConnection();
    paymentService.addToProStatusChangedListeners(_successfulPurchase);
    paymentService.addToErrorListeners(_errorOnPurchase);
    _product = (await paymentService.products).first;
    setState(() {});
  }

  void _successfulPurchase() {
    setState(() {
      _loading = false;
      _purchasing = false;
    });
  }

  void _errorOnPurchase(String error) {
    setState(() {
      _loading = false;
      _purchasing = false;
    });
    if (error.toLowerCase() != 'cancelled.') {
      showAlertDialog(
        context,
        title: 'Error Encountered',
        body: error,
        continueText: 'Ok',
        onContinue: () => Navigator.of(context).pop(),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    paymentService.removeFromProStatusChangedListeners(_successfulPurchase);
    paymentService.removeFromErrorListeners(_errorOnPurchase);
    paymentService.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demo In-App Purchase'),
      ),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: MediaQuery.of(context).size.height / 4,
                    width: MediaQuery.of(context).size.height / 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.black,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 15.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            _product.title,
                            style: TextStyle(
                              fontSize: 28.0,
                            ),
                          ),
                          if (!paymentService.isProUser) ...[
                            Text(
                              _product.description,
                              style: TextStyle(
                                fontSize: 18.0,
                              ),
                            ),
                            Text(
                              'Start with a ${_product.introductoryPriceNumberOfPeriodsIOS} ${_product.introductoryPriceSubscriptionPeriodIOS.toLowerCase()} free trial.',
                              style: TextStyle(
                                fontSize: 18.0,
                              ),
                            ),
                            _purchasing
                                ? Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton(
                                    child: Text(
                                      'Subscribe for ${_product.localizedPrice} / ${_product.subscriptionPeriodUnitIOS.toLowerCase()}',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    onPressed: () async {
                                      setState(() => _purchasing = true);
                                      await paymentService.buyProduct(_product);
                                    },
                                  ),
                          ],
                          if (paymentService.isProUser) ...[
                            Text(
                              'Already Subscribed',
                              style: TextStyle(
                                fontSize: 18.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Cancel anytime by visiting Settings > Apple ID > Subscriptions on your phone.',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
