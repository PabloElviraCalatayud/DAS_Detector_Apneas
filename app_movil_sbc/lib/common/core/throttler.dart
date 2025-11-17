import 'dart:async';
import 'package:flutter/foundation.dart';

class ThrottledValue<T> extends ValueNotifier<T?> {
  ThrottledValue() : super(null);

  Timer? _timer;

  void update(T newValue, {Duration interval = const Duration(seconds: 5)}) {
    if (_timer?.isActive ?? false) return;

    value = newValue;
    notifyListeners();

    _timer = Timer(interval, () {});
  }
}
