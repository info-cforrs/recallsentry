/// Network Status Widget
///
/// Displays network connectivity status to the user.
/// Shows a banner when offline and auto-hides when connection is restored.
library;

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Widget that displays network connectivity status
class NetworkStatusWidget extends StatefulWidget {
  /// Child widget to display
  final Widget child;

  /// Whether to show status banner
  final bool showBanner;

  /// Custom offline message
  final String? offlineMessage;

  const NetworkStatusWidget({
    super.key,
    required this.child,
    this.showBanner = true,
    this.offlineMessage,
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (mounted) {
        setState(() {
          _isOnline = _isConnectivityOnline(results);
          _showBanner = !_isOnline;
        });
      }
    } catch (e) {
      // If we can't check connectivity, assume online
      if (mounted) {
        setState(() {
          _isOnline = true;
          _showBanner = false;
        });
      }
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isOnline = _isConnectivityOnline(results);
        if (mounted && isOnline != _isOnline) {
          setState(() {
            _isOnline = isOnline;
            if (!isOnline) {
              _showBanner = true;
            } else {
              // Delay hiding the banner to show "Back online" message briefly
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _showBanner = false;
                  });
                }
              });
            }
          });
        }
      },
    );
  }

  /// Check if device is online (connectivity_plus v7.x returns List)
  bool _isConnectivityOnline(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showBanner && _showBanner)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            color: _isOnline ? Colors.green[700] : Colors.orange[700],
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      _isOnline ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isOnline
                            ? 'Back online'
                            : widget.offlineMessage ??
                                'You are offline. Some features may be limited.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Simple offline indicator badge
class OfflineIndicatorBadge extends StatefulWidget {
  const OfflineIndicatorBadge({super.key});

  @override
  State<OfflineIndicatorBadge> createState() => _OfflineIndicatorBadgeState();
}

class _OfflineIndicatorBadgeState extends State<OfflineIndicatorBadge> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (mounted) {
        setState(() {
          _isOnline = _isConnectivityOnline(results);
        });
      }
    } catch (e) {
      // Assume online if we can't check
      if (mounted) {
        setState(() {
          _isOnline = true;
        });
      }
    }
  }

  void _setupListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isOnline = _isConnectivityOnline(results);
        if (mounted && isOnline != _isOnline) {
          setState(() {
            _isOnline = isOnline;
          });
        }
      },
    );
  }

  /// Check if device is online (connectivity_plus v7.x returns List)
  bool _isConnectivityOnline(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider widget for network status
class NetworkStatusProvider extends InheritedWidget {
  final bool isOnline;
  final Stream<bool> connectivityStream;

  const NetworkStatusProvider({
    super.key,
    required this.isOnline,
    required this.connectivityStream,
    required super.child,
  });

  static NetworkStatusProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NetworkStatusProvider>();
  }

  @override
  bool updateShouldNotify(NetworkStatusProvider oldWidget) {
    return isOnline != oldWidget.isOnline;
  }
}
