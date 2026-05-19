import 'dart:async';
import 'package:flutter/foundation.dart';

enum TimerState { idle, running, paused, finished }

class TimerProvider extends ChangeNotifier {
  Timer? _timer;
  int _totalSeconds = 90;
  int _remainingSeconds = 90;
  TimerState _state = TimerState.idle;

  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  TimerState get state => _state;
  bool get isRunning => _state == TimerState.running;
  bool get isFinished => _state == TimerState.finished;
  double get progress => _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0;

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startTimer(int seconds) {
    _timer?.cancel();
    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    _state = TimerState.running;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _state = TimerState.finished;
        timer.cancel();
        notifyListeners();
        return;
      }
      _remainingSeconds--;
      notifyListeners();
    });
  }

  void pauseTimer() {
    if (_state == TimerState.running) {
      _timer?.cancel();
      _state = TimerState.paused;
      notifyListeners();
    }
  }

  void resumeTimer() {
    if (_state == TimerState.paused) {
      _state = TimerState.running;
      notifyListeners();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds <= 0) {
          _state = TimerState.finished;
          timer.cancel();
          notifyListeners();
          return;
        }
        _remainingSeconds--;
        notifyListeners();
      });
    }
  }

  void resetTimer() {
    _timer?.cancel();
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _state = TimerState.idle;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void addSeconds(int seconds) {
    _remainingSeconds += seconds;
    if (_remainingSeconds > _totalSeconds) _totalSeconds = _remainingSeconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}