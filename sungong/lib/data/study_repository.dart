import 'package:flutter/foundation.dart';

import '../logic/day_key.dart';
import '../logic/rewards.dart';

class StudyRecord {
  StudyRecord({
    required this.id,
    required this.startedAt,
    required this.focused,
    required this.points,
    this.bonusPoints = 0,
    this.interruptions = 0,
  }) : dayId = kstDayId(startedAt);

  final String id;
  final DateTime startedAt;
  final Duration focused;
  final int points;
  int bonusPoints;
  final int interruptions;

  /// 한국 시간 기준 날짜 ("20261115"). 하루 한도 계산에 씁니다.
  final String dayId;

  int get totalPoints => points + bonusPoints;
}

/// 서버(또는 기기)에 시작이 기록된 세션
class SessionTicket {
  const SessionTicket({required this.id, required this.startedAt});

  final String id;
  final DateTime startedAt;
}

/// 순공 기록과 포인트 저장소.
///
/// [LocalStudyRepository]는 기기 안에, [FirestoreStudyRepository]는 Firebase 서버에
/// 저장합니다. 화면 코드는 이 인터페이스만 사용합니다.
abstract class StudyRepository extends ChangeNotifier {
  StudyRepository(this.policy);

  final RewardPolicy policy;

  /// 끝난 세션, 최신순
  List<StudyRecord> get records;

  int get balance;

  /// 로그인한 계정 표시용 (없으면 기기 저장 모드)
  String? get accountLabel => null;

  Future<void> signOut() async {}

  /// 순공 시작을 기록합니다.
  Future<SessionTicket> begin();

  /// 순공 종료를 기록하고 포인트를 적립합니다.
  Future<StudyRecord> finish(
    SessionTicket ticket, {
    required Duration focused,
    required int interruptions,
  });

  /// 광고를 본 뒤 세션 포인트만큼 보너스를 적립합니다. 세션당 한 번.
  Future<void> claimBonus(StudyRecord record);

  Iterable<StudyRecord> _on(DateTime day) {
    final id = kstDayId(day);
    return records.where((r) => r.dayId == id);
  }

  Duration focusedOn(DateTime day) =>
      _on(day).fold(Duration.zero, (sum, r) => sum + r.focused);

  /// 하루 한도 계산용: 광고 보너스를 뺀 기본 적립 포인트
  int basePointsOn(DateTime day) => _on(day).fold(0, (sum, r) => sum + r.points);
}
