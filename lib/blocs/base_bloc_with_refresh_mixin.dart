import 'dart:async';

import 'package:syrius_mobile/blocs/blocs.dart';
import 'package:syrius_mobile/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

abstract class BaseBlocWithRefreshMixin<T> extends BaseBloc<T>
    with RefreshBlocMixin {
  Future<T> getDataAsync();

  BaseBlocWithRefreshMixin() {
    updateStream();
    listenToWsRestart(updateStream);
  }

  Future<void> updateStream() async {
    try {
      if (!zenon.wsClient.isClosed()) {
        addEvent(await getDataAsync());
      } else {
        throw noConnectionException;
      }
    } catch (e) {
      addError(e);
    }
  }

  @override
  void dispose() {
    cancelStreamSubscription();
    super.dispose();
  }
}
