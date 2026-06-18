import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class NetworkProvider extends ChangeNotifier with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool get isOnline => _isOnline;

  void setConnected(bool isConnected) {
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      notifyListeners();
    }
  }

  NetworkProvider() {
    // Get initial state
    WidgetsBinding.instance.addObserver(this);
    _init();

    // Listen for changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
    );
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final hasNetworkConnection = results.first != ConnectivityResult.none;

    if (hasNetworkConnection) {
      if (!kIsWeb) {
        final hasRealConnection = await _hasRealConnection();
        _isOnline = hasRealConnection;
      } else {
        _isOnline = true;
      }
    } else {
      _isOnline = false;
    }

    notifyListeners();
  }

  Future<bool> _hasRealConnection() async {
    try {
      final lookup = await InternetAddress.lookup('google.com');
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _init(); // Re-check connectivity when the app comes back to the foreground
    }
  }
}
