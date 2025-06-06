import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:syrius_mobile/btc/cross_platform_websocket/core.dart';

Future<WebSocketCore> connectSoc(String url, {List<String>? protocols}) async =>
    await WebsocketWeb.connect(url);

class WebsocketWeb implements WebSocketCore {
  final WebSocket _socket;
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>();
  final Completer<void> _connectedCompleter = Completer<void>();

  WebsocketWeb._(this._socket) {
    _socket.onOpen.listen((Event event) {
      _connectedCompleter.complete();
    });

    _socket.onMessage.listen((MessageEvent event) {
      _streamController.add(event.data);
    });

    _socket.onClose.listen((CloseEvent event) {
      _streamController.close();
    });
  }

  @override
  void close({int? code}) {
    _socket.close(code, '');
  }

  @override
  bool get isConnected => _socket.readyState == WebSocket.OPEN;

  @override
  Stream<dynamic> get stream => _streamController.stream;

  static Future<WebsocketWeb> connect(
    String url, {
    List<String>? protocols,
  }) {
    final completer = Completer<WebsocketWeb>();
    final socket = WebSocket(url, protocols);
    WebsocketWeb._(socket)._connectedCompleter.future.then((_) {
      completer.complete(WebsocketWeb._(socket));
    });
    return completer.future;
  }

  @override
  void sink(List<int> message) {
    _socket.send(message);
  }
}
