import 'package:flutter/material.dart';

import '../ads/reward_ad.dart';
import '../data/study_store.dart';
import '../format.dart';
import '../logic/rewards.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.store,
    required this.policy,
    required this.record,
  });

  final StudyStore store;
  final RewardPolicy policy;
  final StudyRecord record;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _busy = false;

  Future<void> _watchAd() async {
    setState(() => _busy = true);
    final rewarded = await showRewardedAd(context);
    if (rewarded) {
      await widget.store.addBonus(widget.record, widget.record.points);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.record;
    final reachedCap =
        widget.store.basePointsOn(r.startedAt) >= widget.policy.dailyCap;
    final tooShort = r.focused.inMinutes < widget.policy.minimumMinutes;
    final canBoost = r.points > 0 && r.bonusPoints == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('순공 결과'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.emoji_events_rounded, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('수고했어요!', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              Text('순공 시간', style: theme.textTheme.titleMedium),
              Text(
                formatHm(r.focused),
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '+${r.totalPoints} P',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (r.bonusPoints > 0) Text('광고 보너스 +${r.bonusPoints} P 포함'),
              if (tooShort)
                Text('${widget.policy.minimumMinutes}분 이상 순공해야 포인트가 쌓여요.'),
              if (!tooShort && reachedCap) const Text('오늘 적립 한도에 도달했어요.'),
              const SizedBox(height: 8),
              Text('보유 포인트 ${widget.store.balance} P', style: theme.textTheme.bodySmall),
              const Spacer(),
              if (canBoost) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text('광고 보고 +${r.points} P 더 받기'),
                    onPressed: _busy ? null : _watchAd,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('홈으로'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
