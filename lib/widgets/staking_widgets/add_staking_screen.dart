import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:syrius_mobile/blocs/blocs.dart';
import 'package:syrius_mobile/main.dart';
import 'package:syrius_mobile/utils/utils.dart';
import 'package:syrius_mobile/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AddStakingScreen extends StatefulWidget {
  final StakingListBloc? stakingListViewModel;

  const AddStakingScreen(
    this.stakingListViewModel, {
    super.key,
  });

  @override
  State<AddStakingScreen> createState() => _AddStakingScreenState();
}

class _AddStakingScreenState extends State<AddStakingScreen> {
  final ValueNotifier<Duration> _selectedDurationNotifier =
      ValueNotifier(Duration(seconds: stakeTimeUnitSec * 6));

  final List<Duration> _durations = List.generate(
    stakeTimeMaxSec ~/ stakeTimeUnitSec,
    (index) => Duration(
      seconds: (index + 1) * stakeTimeUnitSec,
    ),
  );

  BigInt _maxZnnAmount = BigInt.zero;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  Duration get _defaultDuration => _durations[5];

  final StakingOptionsBloc _stakingOptionsBloc = StakingOptionsBloc();

  @override
  void initState() {
    super.initState();
    _selectedDurationNotifier.value = _defaultDuration;
    refreshBalanceAndTx();
    _stakingOptionsBloc.stream.listen(
      (event) {
        if (event != null) {
          widget.stakingListViewModel!.refreshResults();
          if (!mounted) return;
          Navigator.pop(context);
        }
      },
      onError: (error) {
        if (!mounted) return;
        sendNotificationError(
          AppLocalizations.of(context)!.stakingGenerationError,
          error,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _addressController.text = kSelectedAddress!.hex;
    return CustomAppbarScreen(
      appbarTitle: AppLocalizations.of(context)!.staking,
      child: StreamBuilder<AccountInfo>(
        stream: sl.get<BalanceBloc>().stream,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return SyriusErrorWidget(snapshot.error!);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              Logger('StakingOptions').log(Level.INFO, snapshot.data);
              _maxZnnAmount =
                  snapshot.data!.getBalance(
                kZnnCoin.tokenStandard,
              );
              return _getWidgetBody(
                snapshot.data,
              );
            }
            return const SyriusLoadingWidget();
          }
          return const SyriusLoadingWidget();
        },
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    _selectedDurationNotifier.dispose();
    _stakingOptionsBloc.dispose();
    super.dispose();
  }

  Widget _getWidgetBody(AccountInfo? accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            children: [
              _buildTokenAndAmountInfo(context, accountInfo!),
              ValueListenableBuilder(
                valueListenable: _selectedDurationNotifier,
                builder: (_, duration, __) => StakeDuration(
                  currentValue: duration,
                  onChange: (a) {
                    setState(() {
                      _selectedDurationNotifier.value = a;
                    });
                  },
                ),
              ),
              GenericPagePlasmaInfo(
                accountInfo: accountInfo,
              ),
            ].addSeparator(kVerticalSpacer),
          ),
        ),
        kVerticalSpacer,
        _getStakeForQsrButton(_stakingOptionsBloc),
      ],
    );
  }

  Widget _getStakeForQsrButton(StakingOptionsBloc model) {
    return ListenableBuilder(
      listenable: _amountController,
      builder: (_, __) => SyriusFilledButton(
        onPressed: _isInputValid() ? () => _onStakePressed(model) : null,
        text: AppLocalizations.of(context)!.stake,
      ),
    );
  }

  void _onStakePressed(StakingOptionsBloc model) {
    if (_amountController.text.extractDecimals(coinDecimals) >=
        stakeMinZnnAmount) {
      model.stakeForQsr(
        _selectedDurationNotifier.value,
        _amountController.text.extractDecimals(coinDecimals),
      );
      _amountController.clear();
      _selectedDurationNotifier.value = _defaultDuration;
    }
  }

  bool _isInputValid() =>
      correctValueSyrius(
        _amountController.text,
        _maxZnnAmount,
        coinDecimals,
        stakeMinZnnAmount,
        canBeEqualToMin: true,
      ) ==
      null;

  Widget _buildTokenAndAmountInfo(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    return AmountInfoCard(
      accountInfo: accountInfo,
      amountValidator: (amount) => correctValueSyrius(
        amount,
        _maxZnnAmount,
        coinDecimals,
        stakeMinZnnAmount,
        canBeEqualToMin: true,
      ),
      coins: [kZnnCoin],
      controller: _amountController,
      focusNode: _amountFocusNode,
      selectedToken: kZnnCoin,
      textInputAction: TextInputAction.done,
      requiredInteger: false,
    );
  }
}
