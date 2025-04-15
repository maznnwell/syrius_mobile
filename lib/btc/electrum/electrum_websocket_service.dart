import 'dart:async';
import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:syrius_mobile/btc/cross_platform_websocket/core.dart';
import 'package:syrius_mobile/btc/electrum/request_completer.dart';

class ElectrumWebSocketService with ElectrumServiceProvider {
  ElectrumWebSocketService._(
    this.url,
    WebSocketCore channel, {
    this.defaultRequestTimeOut = const Duration(seconds: 30),
  }) : _socket = channel {
    _subscription = channel.stream
        .cast<String>()
        .listen(_onMessage, onError: _onClose, onDone: _onDone);
  }

  WebSocketCore? _socket;
  StreamSubscription<String>? _subscription;
  final Duration defaultRequestTimeOut;

  Map<int, AsyncRequestCompleter> requests = {};
  bool _isDisconnect = false;

  bool get isConnected => _isDisconnect;

  @override
  final String url;

  void add(List<int> params) {
    if (_isDisconnect) {
      throw StateError("socket has been disconnected");
    }
    _socket?.sink(params);
  }

  void _onClose(Object? error) {
    _isDisconnect = true;

    _socket = null;
    _subscription?.cancel().catchError((e) {});
    _subscription = null;
  }

  void _onDone() {
    _onClose(null);
  }

  void disconnect() {
    _onClose(null);
  }

  static Future<ElectrumWebSocketService> connect(
    String url, {
    Iterable<String>? protocols,
    Duration defaultRequestTimeOut = const Duration(seconds: 30),
    Duration connectionTimeOut = const Duration(seconds: 30),
  }) async {
    final channel =
        await WebSocketCore.connect(url, protocols: protocols?.toList());

    return ElectrumWebSocketService._(
      url,
      channel,
      defaultRequestTimeOut: defaultRequestTimeOut,
    );
  }

  void _onMessage(String event) {
    final Map<String, dynamic> decode =
        json.decode(event) as Map<String, dynamic>;
    if (decode.containsKey("id")) {
      final int id = int.parse(decode["id"]!.toString());
      final request = requests.remove(id);
      request?.completer.complete(decode);
    }
  }

  @override
  Future<BaseServiceResponse<T>> doRequest<T>(
    ElectrumRequestDetails params, {
    Duration? timeout,
  }) async {
    final AsyncRequestCompleter compeleter =
        AsyncRequestCompleter(params.params);
    try {
      requests[params.requestID] = compeleter;
      add(params.toWebSocketParams());
      final result = await compeleter.completer.future
          .timeout(timeout ?? defaultRequestTimeOut);
      return params.toResponse(result);
    } finally {
      requests.remove(params.requestID);
    }
  }
}
