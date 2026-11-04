import 'package:flutter/material.dart';

import 'app_lock.dart';
import 'lock_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _lock = AppLock.instance;
  bool _ready = false;
  bool _locked = false;
  bool _authenticating = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    await _lock.load();
    if (!mounted) return;
    if (_lock.enabled.value) _showLock();
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showLock() {
    if (_locked) return;
    final nav = navigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLock();
      });
      return;
    }
    _locked = true;
    nav.push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => LockScreen(
          onBiometric: _tryBiometric,
          onUnlocked: _onUnlocked,
        ),
      ),
    );
    _tryBiometric();
  }

  void _onUnlocked() {
    _locked = false;
    _pausedAt = null;
  }

  Future<void> _tryBiometric() async {
    if (!_lock.biometric || _authenticating || !_locked) return;
    _authenticating = true;
    final ok = await _lock.authenticateBiometric();
    _authenticating = false;
    if (ok && _locked) {
      navigatorKey.currentState?.pop();
      _onUnlocked();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating || !_lock.enabled.value) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final at = _pausedAt;
      _pausedAt = null;
      if (at != null &&
          !_locked &&
          DateTime.now().difference(at).inSeconds >= _lock.delaySeconds) {
        _showLock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_ready)
          const Positioned.fill(
            child: Material(child: Center(child: CircularProgressIndicator())),
          ),
      ],
    );
  }
}
