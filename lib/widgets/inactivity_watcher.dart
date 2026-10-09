import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration? warningBefore;
  final Duration? warningDuration;
  final VoidCallback? onTimeout;
  final Widget child;

  const InactivityWatcher({
    super.key,
    this.timeout = const Duration(minutes: 3),
    this.warningBefore = const Duration(seconds: 30),
    this.warningDuration,
    this.onTimeout,
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _idleTimer;
  Timer? _tickerTimer;
  Timer? _countdownTimer;

  bool _isDialogShowing = false;
  bool _wasAuthenticated = false;
  int _remainingSeconds = 30;

  Duration get _effectiveWarning =>
      widget.warningBefore ?? widget.warningDuration ?? const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthNotifier>();
    if (auth.isAuthenticated) {
      if (!_wasAuthenticated) {
        _wasAuthenticated = true;
        _resetTimer();
      }
    } else {
      _wasAuthenticated = false;
      _cancelAll();
    }
  }

  bool _onKey(KeyEvent event) {
    if (!_isDialogShowing && _wasAuthenticated) {
      _handleActivity();
    }
    return false;
  }

  void _handleActivity() {
    if (_isDialogShowing || !_wasAuthenticated) return;
    _resetTimer();
  }

  void _cancelAll() {
    _idleTimer?.cancel();
    _tickerTimer?.cancel();
    _countdownTimer?.cancel();
    _idleTimer = null;
    _tickerTimer = null;
    _countdownTimer = null;
    if (_isDialogShowing && mounted) {
      setState(() => _isDialogShowing = false);
    }
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _tickerTimer?.cancel();
    _countdownTimer?.cancel();

    if (!mounted || !_wasAuthenticated) return;

    final totalDelay = widget.timeout - _effectiveWarning;
    final idleSeconds = totalDelay > Duration.zero ? totalDelay.inSeconds : 10;

    if (kDebugMode) {
      debugPrint('[INACTIVITY] Таймер запущен: предупреждение через $idleSeconds сек.');
    }

    int elapsed = 0;
    _tickerTimer = Timer.periodic(const Duration(seconds: 30), (t) {
      elapsed += 30;
      final left = idleSeconds - elapsed;
      if (left > 0 && kDebugMode) {
        debugPrint('[INACTIVITY] До предупреждения осталось: $left сек...');
      }
    });

    _idleTimer = Timer(Duration(seconds: idleSeconds), _showWarning);
  }

  void _showWarning() {
    _tickerTimer?.cancel();
    if (!mounted || !_wasAuthenticated || _isDialogShowing) return;

    if (kDebugMode) {
      debugPrint('[INACTIVITY] Внимание: показываем окно предупреждения!');
    }

    setState(() {
      _isDialogShowing = true;
      _remainingSeconds = _effectiveWarning.inSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _logout();
        }
      });
    });
  }

  void _continueSession() {
    if (kDebugMode) debugPrint('[INACTIVITY] Пользователь нажал "Продолжить работу".');
    _cancelAll();
    _handleActivity();
  }

  void _logout() async {
    _cancelAll();
    if (kDebugMode) debugPrint('[INACTIVITY] Время истекло, автоматический выход из системы.');
    if (widget.onTimeout != null) {
      widget.onTimeout!();
    } else {
      await context.read<AuthNotifier>().logout();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleActivity(),
      onPointerSignal: (_) => _handleActivity(),
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          widget.child,
          if (_isDialogShowing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Card(
                      elevation: 20,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.amber,
                              size: 56,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Сессия скоро завершится',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Вы не проявляли активности в течение ${widget.timeout.inMinutes} минут.\nСессия будет автоматически завершена через $_remainingSeconds сек.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _continueSession,
                              child: const Text('Продолжить работу'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}