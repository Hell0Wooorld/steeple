import 'package:flutter_test/flutter_test.dart';
import 'package:sungong/logic/flip_detector.dart';
import 'package:sungong/logic/rewards.dart';
import 'package:sungong/logic/study_session.dart';

void main() {
  group('FlipDetector', () {
    final t0 = DateTime(2026, 1, 1, 9);

    test('뒤집힌 상태가 일정 시간 이어져야 뒤집힘으로 판정', () {
      final d = FlipDetector();
      expect(d.update(0, 0, -9.8, t0), isFalse);
      expect(d.update(0, 0, -9.8, t0.add(const Duration(milliseconds: 600))), isFalse);
      expect(d.update(0, 0, -9.8, t0.add(const Duration(milliseconds: 1300))), isTrue);
      expect(d.isFaceDown, isTrue);
    });

    test('잠깐 흔들린 값은 무시', () {
      final d = FlipDetector();
      d.update(0, 0, -9.8, t0);
      d.update(0, 0, 9.8, t0.add(const Duration(milliseconds: 500)));
      expect(d.update(0, 0, -9.8, t0.add(const Duration(milliseconds: 1300))), isFalse);
      expect(d.isFaceDown, isFalse);
    });

    test('비스듬히 세운 폰은 뒤집힘이 아님', () {
      final d = FlipDetector();
      expect(d.rawFaceDown(6, 0, -7.9), isFalse);
      expect(d.rawFaceDown(0.5, -0.3, -9.7), isTrue);
    });
  });

  group('StudySession', () {
    late DateTime now;
    StudySession make() => StudySession(clock: () => now);

    setUp(() => now = DateTime(2026, 1, 1, 9));

    test('뒤집혀 있던 시간만 순공으로 계산', () {
      final s = make();
      now = now.add(const Duration(minutes: 2)); // 뒤집기 전 대기
      s.onFaceDown();
      now = now.add(const Duration(minutes: 30));
      s.onFaceUp();
      now = now.add(const Duration(minutes: 5)); // 쉬는 시간
      s.onFaceDown();
      now = now.add(const Duration(minutes: 10));
      s.finish();
      expect(s.focused, const Duration(minutes: 40));
      expect(s.interruptions, 1);
      expect(s.phase, SessionPhase.finished);
    });

    test('앱을 벗어나면 일시정지', () {
      final s = make();
      s.onFaceDown();
      now = now.add(const Duration(minutes: 3));
      s.onAppLeft();
      now = now.add(const Duration(minutes: 60));
      expect(s.focused, const Duration(minutes: 3));
      expect(s.lastPauseReason, PauseReason.leftApp);
    });

    test('종료 뒤에는 더 쌓이지 않음', () {
      final s = make();
      s.onFaceDown();
      now = now.add(const Duration(minutes: 1));
      s.finish();
      s.onFaceDown();
      now = now.add(const Duration(minutes: 10));
      expect(s.focused, const Duration(minutes: 1));
    });
  });

  group('RewardPolicy', () {
    const p = RewardPolicy(pointsPerMinute: 1, dailyCap: 600, minimumMinutes: 1);

    test('분 단위로 적립', () {
      expect(p.pointsFor(const Duration(minutes: 45, seconds: 50), alreadyEarnedToday: 0), 45);
    });

    test('1분 미만은 0', () {
      expect(p.pointsFor(const Duration(seconds: 59), alreadyEarnedToday: 0), 0);
    });

    test('하루 한도까지만', () {
      expect(p.pointsFor(const Duration(minutes: 100), alreadyEarnedToday: 550), 50);
      expect(p.pointsFor(const Duration(minutes: 100), alreadyEarnedToday: 600), 0);
    });
  });
}
