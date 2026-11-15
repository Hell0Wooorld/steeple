import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyRecord {
  StudyRecord({
    required this.startedAt,
    required this.focused,
    required this.points,
    this.bonusPoints = 0,
    this.interruptions = 0,
  });

  final DateTime startedAt;
  final Duration focused;
  final int points;
  int bonusPoints;
  final int interruptions;

  int get totalPoints => points + bonusPoints;

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'focusedSec': focused.inSeconds,
        'points': points,
        'bonus': bonusPoints,
        'interruptions': interruptions,
      };

  factory StudyRecord.fromJson(Map<String, dynamic> j) => StudyRecord(
        startedAt: DateTime.parse(j['startedAt'] as String),
        focused: Duration(seconds: j['focusedSec'] as int),
        points: j['points'] as int,
        bonusPoints: (j['bonus'] as int?) ?? 0,
        interruptions: (j['interruptions'] as int?) ?? 0,
      );
}

/// 순공 기록과 포인트를 기기 안에 저장합니다.
///
/// 프로토타입이라 기기 저장소를 씁니다. 실제로 돈을 지급하려면 기록과 포인트를
/// 반드시 서버에서 검증하고 관리해야 합니다 (기기 저장소는 조작할 수 있음).
class StudyStore extends ChangeNotifier {
  static const _recordsKey = 'records';

  final List<StudyRecord> _records = [];
  SharedPreferences? _prefs;

  List<StudyRecord> get records => List.unmodifiable(_records);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_recordsKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _records
        ..clear()
        ..addAll(list.map(StudyRecord.fromJson));
    }
    notifyListeners();
  }

  Iterable<StudyRecord> _onDay(DateTime day) => _records.where((r) =>
      r.startedAt.year == day.year &&
      r.startedAt.month == day.month &&
      r.startedAt.day == day.day);

  Duration focusedOn(DateTime day) =>
      _onDay(day).fold(Duration.zero, (sum, r) => sum + r.focused);

  /// 하루 한도 계산용: 광고 보너스를 뺀 기본 적립 포인트
  int basePointsOn(DateTime day) =>
      _onDay(day).fold(0, (sum, r) => sum + r.points);

  int get balance => _records.fold(0, (sum, r) => sum + r.totalPoints);

  Future<void> add(StudyRecord record) async {
    _records.insert(0, record);
    await _save();
  }

  Future<void> addBonus(StudyRecord record, int bonus) async {
    record.bonusPoints += bonus;
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs?.setString(
      _recordsKey,
      jsonEncode(_records.map((r) => r.toJson()).toList()),
    );
  }
}
