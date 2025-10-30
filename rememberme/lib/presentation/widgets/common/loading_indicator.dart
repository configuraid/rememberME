import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (Platform.isIOS)
            CupertinoActivityIndicator(
              radius: 16,
              color: color,
            )
          else
            CircularProgressIndicator(
              valueColor:
                  color != null ? AlwaysStoppedAnimation<Color>(color!) : null,
            ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
