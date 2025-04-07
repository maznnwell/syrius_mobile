import 'package:flutter/material.dart';
import 'package:syrius_mobile/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AvailableBalance extends StatelessWidget {
  final Token token;
  final AccountInfo accountInfo;

  const AvailableBalance(
      this.token,
      this.accountInfo, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      '${accountInfo.getBalance(
        token.tokenStandard,
      ).addDecimals(token.decimals)} '
          '${token.symbol} available',
      style: Theme.of(context).inputDecorationTheme.hintStyle,
    );
  }
}
