enum SessionPhase {
  /// 시작 버튼을 눌렀고 폰이 뒤집히기를 기다리는 중
  waitingFlip,

  /// 폰이 뒤집혀 있어 순공 시간이 쌓이는 중
  studying,

  /// 폰을 들었거나 앱을 벗어나 일시정지된 상태
  paused,

  /// 종료됨
  finished,
}

enum PauseReason { liftedPhone, leftApp }

/// 한 번의 순공 세션. 폰이 뒤집혀 있는 시간만 순공 시간으로 셉니다.
class StudySession {
  StudySession({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    startedAt = _clock();
  }

  final DateTime Function() _clock;
  late final DateTime startedAt;

  SessionPhase phase = SessionPhase.waitingFlip;
  PauseReason? lastPauseReason;
  int interruptions = 0;

  Duration _accumulated = Duration.zero;
  DateTime? _runningSince;

  bool get isRunning => phase == SessionPhase.studying;

  Duration get focused {
    final since = _runningSince;
    if (since == null) return _accumulated;
    return _accumulated + _clock().difference(since);
  }

  void onFaceDown() {
    if (phase == SessionPhase.waitingFlip || phase == SessionPhase.paused) {
      phase = SessionPhase.studying;
      _runningSince = _clock();
      lastPauseReason = null;
    }
  }

  void onFaceUp() => _pause(PauseReason.liftedPhone);

  void onAppLeft() => _pause(PauseReason.leftApp);

  void _pause(PauseReason reason) {
    if (phase != SessionPhase.studying) return;
    _stopClock();
    phase = SessionPhase.paused;
    lastPauseReason = reason;
    interruptions++;
  }

  void finish() {
    if (phase == SessionPhase.finished) return;
    _stopClock();
    phase = SessionPhase.finished;
  }

  void _stopClock() {
    final since = _runningSince;
    if (since != null) {
      _accumulated += _clock().difference(since);
      _runningSince = null;
    }
  }
}
