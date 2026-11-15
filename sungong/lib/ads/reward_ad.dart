import 'dart:async';

import 'package:flutter/material.dart';

/// 보상형 광고 자리.
///
/// 지금은 프로토타입용 가짜 광고(5초 카운트다운)입니다. 실제 출시 때는 이 함수를
/// google_mobile_ads 패키지의 RewardedAd로 바꾸면 됩니다. 광고는 사용자가
/// 화면을 보고 있을 때만 보여 줘야 합니다 (화면이 꺼진 상태의 광고 노출은 정책 위반).
///
/// 사용자가 광고를 끝까지 보면 true를 돌려줍니다.
Future<bool> showRewardedAd(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _MockAdDialog(),
  );
  return result ?? false;
}

class _MockAdDialog extends StatefulWidget {
  const _MockAdDialog();

  @override
  State<_MockAdDialog> createState() => _MockAdDialogState();
}

class _MockAdDialogState extends State<_MockAdDialog> {
  static const _length = 5;
  int _left = _length;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _left <= 0;
    return AlertDialog(
      title: const Text('광고'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '보상형 광고 자리\n(프로토타입)',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(done ? '보상을 받을 수 있어요' : '$_left초 후 보상 지급'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: done ? () => Navigator.pop(context, true) : null,
          child: const Text('보상 받기'),
        ),
      ],
    );
  }
}
