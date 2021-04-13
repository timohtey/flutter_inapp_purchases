import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:inapp_purchases/alert_dialog.dart';
import 'package:inapp_purchases/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService paymentService = PaymentService.instance;
  bool _purchasing = false;
  IAPItem _product;

  @override
  void initState() {
    super.initState();
    _getProducts();
  }

  void _getProducts() async {
    await paymentService.initConnection();
    _product = (await paymentService.products).first;
    setState(() {});
    paymentService.addToProStatusChangedListeners(_successfulPurchase);
    paymentService.addToErrorListeners(_errorOnPurchase);
  }

  void _successfulPurchase() {
    print('Subscribed!');
    setState(() => _purchasing = false);
    showAlertDialog(
      context,
      title: 'Successfully Subscribed',
      body: 'You are all set! You may now access the additional features.',
      continueText: 'Ok',
      onContinue: () => Navigator.of(context).pop(),
    );
  }

  void _errorOnPurchase(String error) {
    print('Error encountered: $error');
    setState(() => _purchasing = false);
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
        child: _product == null
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
                      ),
                    ),
                  ),
                ],
              ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
