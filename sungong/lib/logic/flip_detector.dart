/// 가속도 센서 값으로 폰이 화면을 바닥으로 향하게 뒤집혀 있는지 판단합니다.
///
/// 화면이 위를 보고 평평하게 놓이면 z ≈ +9.8, 뒤집히면 z ≈ -9.8 (m/s²) 입니다.
/// 손에 들고 흔들리는 순간의 잘못된 판정을 막으려고, 같은 상태가 [holdDuration]
/// 동안 이어져야 상태를 바꿉니다.
class FlipDetector {
  FlipDetector({
    this.holdDuration = const Duration(milliseconds: 1200),
    this.zThreshold = -7.5,
    this.tiltTolerance = 3.5,
  });

  final Duration holdDuration;
  final double zThreshold;
  final double tiltTolerance;

  bool _faceDown = false;
  bool? _candidate;
  DateTime? _candidateSince;

  bool get isFaceDown => _faceDown;

  /// 순간 값 하나만 보고 뒤집힌 자세인지 판단합니다.
  bool rawFaceDown(double x, double y, double z) =>
      z < zThreshold && x.abs() < tiltTolerance && y.abs() < tiltTolerance;

  /// 센서 값을 넣고, 상태가 바뀌었으면 true를 돌려줍니다.
  bool update(double x, double y, double z, DateTime now) {
    final raw = rawFaceDown(x, y, z);
    if (raw == _faceDown) {
      _candidate = null;
      _candidateSince = null;
      return false;
    }
    if (_candidate != raw) {
      _candidate = raw;
      _candidateSince = now;
      return false;
    }
    if (now.difference(_candidateSince!) >= holdDuration) {
      _faceDown = raw;
      _candidate = null;
      _candidateSince = null;
      return true;
    }
    return false;
  }

  /// 센서 없이 상태를 직접 바꿉니다 (에뮬레이터 테스트용).
  void force(bool faceDown) {
    _faceDown = faceDown;
    _candidate = null;
    _candidateSince = null;
  }
}
