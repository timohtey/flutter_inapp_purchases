import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

Future showAlertDialog(
  BuildContext context, {
  @required String title,
  String body,
  Function onContinue,
  String continueText,
  String cancelText,
  Function onCancel,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return Platform.isIOS
          ? CupertinoAlertDialog(
              title: Text(title),
              content: body != null ? Text(body) : null,
              actions: [
                if (cancelText != null)
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: Text(cancelText),
                    onPressed: onCancel,
                  ),
                if (continueText != null)
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: Text(continueText),
                    onPressed: onContinue,
                  ),
              ],
            )
          : AlertDialog(
              title: Text(title),
              content: body != null ? Text(body) : null,
              actions: [
                if (cancelText != null)
                  FlatButton(
                    child: Text(cancelText),
                    onPressed: onCancel,
                  ),
                if (continueText != null)
                  FlatButton(
                    child: Text(continueText),
                    onPressed: onContinue,
                  ),
              ],
            );
    },
  );
}
