import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syrius_mobile/utils/extensions/extensions.dart';

class FormattedAmountWithTooltip extends Tooltip {
  final String amount;
  final String tokenSymbol;
  final Widget Function(String, String) builder;

  FormattedAmountWithTooltip({
    super.key,
    required this.amount,
    required this.tokenSymbol,
    required this.builder,
  }) : super(
          message: '$amount $tokenSymbol',
          child: builder(
            amount.toNum() == 0
                ? '0'
                : amount.startsWith('0.')
                    ? amount
                    : NumberFormat.compact().format(amount.toNum()).length > 8
                        ? '…'
                        : NumberFormat.compact().format(amount.toNum()),
            tokenSymbol,
          ),
        );
}
