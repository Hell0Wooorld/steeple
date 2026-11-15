import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'study_repository.dart';

/// 기기 안에만 저장하는 저장소. Firebase 설정 전에 쓰입니다.
///
/// 기기 저장소는 조작할 수 있으므로 실제 보상 지급에는 쓰면 안 됩니다.
class LocalStudyRepository extends StudyRepository {
  LocalStudyRepository(super.policy);

  static const _recordsKey = 'records';

  final List<StudyRecord> _records = [];
  SharedPreferences? _prefs;

  @override
  List<StudyRecord> get records => List.unmodifiable(_records);

  @override
  int get balance => _records.fold(0, (sum, r) => sum + r.totalPoints);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_recordsKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _records
        ..clear()
        ..addAll(list.map(_fromJson));
    }
    notifyListeners();
  }

  @override
  Future<SessionTicket> begin() async {
    final now = DateTime.now();
    return SessionTicket(id: now.microsecondsSinceEpoch.toString(), startedAt: now);
  }

  @override
  Future<StudyRecord> finish(
    SessionTicket ticket, {
    required Duration focused,
    required int interruptions,
  }) async {
    final points = policy.pointsFor(
      focused,
      alreadyEarnedToday: basePointsOn(ticket.startedAt),
    );
    final record = StudyRecord(
      id: ticket.id,
      startedAt: ticket.startedAt,
      focused: focused,
      points: points,
      interruptions: interruptions,
    );
    if (focused.inSeconds > 0) {
      _records.insert(0, record);
      await _save();
    }
    return record;
  }

  @override
  Future<void> claimBonus(StudyRecord record) async {
    if (record.bonusPoints > 0 || record.points <= 0) return;
    record.bonusPoints = record.points;
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs?.setString(
      _recordsKey,
      jsonEncode(_records.map(_toJson).toList()),
    );
  }

  static Map<String, dynamic> _toJson(StudyRecord r) => {
        'id': r.id,
        'startedAt': r.startedAt.toIso8601String(),
        'focusedSec': r.focused.inSeconds,
        'points': r.points,
        'bonus': r.bonusPoints,
        'interruptions': r.interruptions,
      };

  static StudyRecord _fromJson(Map<String, dynamic> j) {
    final startedAt = DateTime.parse(j['startedAt'] as String);
    return StudyRecord(
      id: (j['id'] as String?) ?? startedAt.microsecondsSinceEpoch.toString(),
      startedAt: startedAt,
      focused: Duration(seconds: j['focusedSec'] as int),
      points: j['points'] as int,
      bonusPoints: (j['bonus'] as int?) ?? 0,
      interruptions: (j['interruptions'] as int?) ?? 0,
    );
  }
}
