/// 한국 시간(UTC+9) 기준 날짜 id. 예: 2026-11-15 → "20261115"
///
/// 서버 보안 규칙(firebase/firestore.rules의 kstDayId)과 같은 계산이어야 합니다.
String kstDayId(DateTime t) {
  final k = t.toUtc().add(const Duration(hours: 9));
  return (k.year * 10000 + k.month * 100 + k.day).toString();
}
