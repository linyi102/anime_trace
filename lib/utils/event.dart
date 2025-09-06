import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

enum EventName {
  /// 设置底部导航栏
  /// `bool` true显示 false隐藏
  setNavigator,
}

class Event {
  final StreamController _controller;

  const Event._(this._controller);

  factory Event(EventName eventName) => _findEvent(eventName.name);

  factory Event.custom(String name) => _findEvent(name);

  static final _events = <String, StreamController>{};

  static Event _findEvent(String name) {
    return Event._(
        _events.putIfAbsent(name, () => StreamController.broadcast()));
  }

  void send(dynamic data) => _controller.add(data);

  VoidCallback listen<T>(void Function(T) handler) {
    return _controller.stream.listen((event) {
      if (event is T) handler(event);
    }).cancel;
  }
}

mixin MultiEventsStateMixin<T extends StatefulWidget> on State<T> {
  final List<VoidCallback> _listeners = [];

  List<VoidCallback> get initialListeners;

  @override
  void initState() {
    super.initState();
    addEventListeners(initialListeners);
  }

  @override
  void dispose() {
    removeAllEventListeners();
    super.dispose();
  }

  void addEventListeners(List<VoidCallback> listeners) {
    _listeners.addAll(listeners);
  }

  void removeAllEventListeners() {
    for (final cancel in _listeners) {
      cancel();
    }
    _listeners.clear();
  }
}
