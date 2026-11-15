/// 포인트 정책. 실제 서비스에서는 서버에서 내려받아야 하는 값입니다.
class RewardPolicy {
  const RewardPolicy({
    this.pointsPerMinute = 1,
    this.dailyCap = 600,
    this.minimumMinutes = 1,
  });

  /// 순공 1분당 적립 포인트
  final int pointsPerMinute;

  /// 하루 최대 적립 포인트 (광고 보너스 제외)
  final int dailyCap;

  /// 이보다 짧은 세션은 적립하지 않음
  final int minimumMinutes;

  /// 이번 세션으로 받을 기본 포인트. 오늘 이미 받은 포인트를 빼고 한도까지만 줍니다.
  int pointsFor(Duration focused, {required int alreadyEarnedToday}) {
    final minutes = focused.inMinutes;
    if (minutes < minimumMinutes) return 0;
    final remaining = dailyCap - alreadyEarnedToday;
    if (remaining <= 0) return 0;
    final raw = minutes * pointsPerMinute;
    return raw < remaining ? raw : remaining;
  }
}
