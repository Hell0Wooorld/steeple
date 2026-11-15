import 'package:flutter/material.dart';

import '../data/study_repository.dart';
import '../format.dart';
import 'session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.repo});

  final StudyRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = repo;
    final policy = repo.policy;
    final account = repo.accountLabel;
    return Scaffold(
      appBar: AppBar(
        title: const Text('순공'),
        actions: [
          if (account == null)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Tooltip(
                message: 'Firebase 설정 전이라 기록이 이 기기에만 저장돼요',
                child: Chip(label: Text('기기 저장 모드')),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (v) {
                if (v == 'logout') repo.signOut();
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text(account)),
                const PopupMenuItem(value: 'logout', child: Text('로그아웃')),
              ],
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final today = DateTime.now();
          final focusedToday = store.focusedOn(today);
          final earnedToday = store.basePointsOn(today);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('오늘 순공 시간', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        formatClock(focusedToday),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(label: '보유 포인트', value: '${store.balance} P'),
                          ),
                          Expanded(
                            child: _Stat(
                              label: '오늘 적립 / 한도',
                              value: '$earnedToday / ${policy.dailyCap} P',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (earnedToday / policy.dailyCap).clamp(0, 1).toDouble(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 32),
                  label: const Text('순공 시작', style: TextStyle(fontSize: 20)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionScreen(repo: repo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '시작한 뒤 폰을 화면이 바닥을 향하게 뒤집어 두세요. '
                '뒤집혀 있는 시간만 순공 시간으로 쌓여요. 순공 1분 = ${policy.pointsPerMinute} P',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 28),
              Text('최근 기록', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (store.records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('아직 기록이 없어요')),
                ),
              for (final r in store.records.take(20))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(formatHm(r.focused)),
                  subtitle: Text(
                    '${r.startedAt.month}/${r.startedAt.day} '
                    '${r.startedAt.hour.toString().padLeft(2, '0')}:'
                    '${r.startedAt.minute.toString().padLeft(2, '0')}'
                    ' · 중단 ${r.interruptions}회',
                  ),
                  trailing: Text(
                    r.bonusPoints > 0
                        ? '+${r.points} P (+${r.bonusPoints} 광고)'
                        : '+${r.points} P',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleLarge),
      ],
    );
  }
}
