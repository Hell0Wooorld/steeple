import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sungong/data/local_repository.dart';
import 'package:sungong/logic/day_key.dart';
import 'package:sungong/logic/rewards.dart';

void main() {
  group('kstDayId', () {
    test('한국 시간 자정을 기준으로 날짜가 바뀜', () {
      expect(kstDayId(DateTime.utc(2026, 11, 15, 14, 59)), '20261115');
      expect(kstDayId(DateTime.utc(2026, 11, 15, 15, 0)), '20261116');
      expect(kstDayId(DateTime.utc(2026, 12, 31, 15, 30)), '20270101');
    });
  });

  group('LocalStudyRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('종료하면 포인트 적립, 보너스는 한 번만', () async {
      final repo = LocalStudyRepository(const RewardPolicy());
      await repo.load();
      final t = await repo.begin();
      final r = await repo.finish(t, focused: const Duration(minutes: 30), interruptions: 2);
      expect(r.points, 30);
      expect(repo.balance, 30);
      await repo.claimBonus(r);
      await repo.claimBonus(r);
      expect(repo.balance, 60);
      expect(repo.focusedOn(DateTime.now()), const Duration(minutes: 30));
    });

    test('하루 한도를 넘지 않음', () async {
      final repo = LocalStudyRepository(const RewardPolicy(dailyCap: 40));
      await repo.load();
      await repo.finish(await repo.begin(), focused: const Duration(minutes: 30), interruptions: 0);
      final r = await repo.finish(await repo.begin(),
          focused: const Duration(minutes: 30), interruptions: 0);
      expect(r.points, 10);
      expect(repo.basePointsOn(DateTime.now()), 40);
    });

    test('다시 불러와도 기록 유지', () async {
      final repo = LocalStudyRepository(const RewardPolicy());
      await repo.load();
      await repo.finish(await repo.begin(), focused: const Duration(minutes: 5), interruptions: 0);
      final again = LocalStudyRepository(const RewardPolicy());
      await again.load();
      expect(again.balance, 5);
      expect(again.records.single.focused, const Duration(minutes: 5));
    });
  });
}
