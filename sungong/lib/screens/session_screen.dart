import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/study_repository.dart';
import '../format.dart';
import '../logic/flip_detector.dart';
import '../logic/study_session.dart';
import 'result_screen.dart';

/// 순공 진행 화면.
///
/// 폰이 뒤집혀 있는 동안은 화면을 완전히 검게 만들고(OLED에서는 화면이 꺼진 것과
/// 비슷하게 전력을 거의 쓰지 않음), 앱이 앞에 떠 있는 상태를 유지합니다.
/// 실제로 화면을 꺼 버리면 앱이 멈춰 다른 앱 사용 여부를 확인할 수 없기 때문입니다.
/// 다른 앱으로 나가거나 전원 버튼으로 화면을 끄면 일시정지됩니다.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.repo});

  final StudyRepository repo;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with WidgetsBindingObserver {
  final _detector = FlipDetector();

  /// 서버에 시작이 기록된 뒤에 만들어짐. 그 전에는 뒤집어도 시간이 쌓이지 않음.
  StudySession? _sessionOrNull;
  SessionTicket? _ticket;
  String? _beginError;

  StudySession get _session => _sessionOrNull!;
  StreamSubscription<AccelerometerEvent>? _sensorSub;
  Timer? _ticker;
  bool _sensorAvailable = true;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 화면 꺼짐 방지. 지원하지 않는 환경(일부 브라우저 등)에서는 조용히 무시
    WakelockPlus.enable().catchError((_) {});
    _begin();
    _sensorSub = accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval).listen(
      (e) {
        if (_detector.update(e.x, e.y, e.z, DateTime.now()) || _justStarted) {
          _justStarted = false;
          _applyFlip(_detector.isFaceDown);
        }
      },
      onError: (_) => setState(() => _sensorAvailable = false),
      cancelOnError: true,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  /// 시작 기록 직후, 이미 뒤집혀 있으면 바로 반영하기 위한 표시
  bool _justStarted = false;

  Future<void> _begin() async {
    setState(() => _beginError = null);
    try {
      final ticket = await widget.repo.begin();
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _sessionOrNull = StudySession();
        _justStarted = _detector.isFaceDown;
      });
    } catch (e) {
      if (mounted) setState(() => _beginError = '$e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sensorSub?.cancel();
    _ticker?.cancel();
    WakelockPlus.disable().catchError((_) {});
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_sessionOrNull == null) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _session.onAppLeft();
      _setImmersive(false);
      if (mounted) setState(() {});
    }
  }

  void _applyFlip(bool faceDown) {
    if (_sessionOrNull == null) return;
    if (_session.phase == SessionPhase.finished) return;
    if (faceDown) {
      _session.onFaceDown();
      HapticFeedback.mediumImpact();
    } else {
      _session.onFaceUp();
    }
    _setImmersive(_session.isRunning);
    setState(() {});
  }

  void _setImmersive(bool on) {
    SystemChrome.setEnabledSystemUIMode(
      on ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  Future<void> _end() async {
    if (_ending) return;
    final ticket = _ticket;
    if (ticket == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => _ending = true);
    _session.finish();
    try {
      final record = await widget.repo.finish(
        ticket,
        focused: _session.focused,
        interruptions: _session.interruptions,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(repo: widget.repo, record: record)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _ending = false);
      final retry = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('저장하지 못했어요'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('저장하지 않고 나가기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (retry == true) {
        await _end();
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _confirmEnd() async {
    if (_sessionOrNull == null) {
      Navigator.pop(context);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('순공을 끝낼까요?'),
        content: Text('지금까지 순공 시간: ${formatHm(_session.focused)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('계속하기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('끝내기')),
        ],
      ),
    );
    if (ok == true) await _end();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd();
      },
      child: _sessionOrNull == null
          ? _buildConnecting(context)
          : _session.isRunning
              ? _buildDark()
              : _buildIdle(context),
    );
  }

  Widget _buildConnecting(BuildContext context) {
    final error = _beginError;
    return Scaffold(
      appBar: AppBar(title: const Text('순공 중')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('순공 시작을 기록하는 중…'),
              ] else ...[
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _begin, child: const Text('다시 시도')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 뒤집혀 있는 동안의 화면: 완전한 검정.
  Widget _buildDark() {
    return GestureDetector(
      // 테스트할 때 화면을 두 번 탭하면 뒤집기를 해제한 것으로 처리 (디버그 빌드만)
      onDoubleTap: kReleaseMode ? null : () => _simulate(false),
      child: const Scaffold(backgroundColor: Colors.black, body: SizedBox.expand()),
    );
  }

  Widget _buildIdle(BuildContext context) {
    final theme = Theme.of(context);
    final waiting = _session.phase == SessionPhase.waitingFlip;
    final String title;
    final String message;
    if (waiting) {
      title = '폰을 뒤집어 놓으세요';
      message = '화면이 바닥을 향하게 놓으면 순공 시간이 쌓이기 시작해요.';
    } else if (_session.lastPauseReason == PauseReason.leftApp) {
      title = '일시정지됨';
      message = '앱을 벗어나거나 화면을 꺼서 멈췄어요.\n다시 뒤집어 두면 이어서 기록돼요.';
    } else {
      title = '일시정지됨';
      message = '폰을 들어서 멈췄어요.\n다시 뒤집어 두면 이어서 기록돼요.';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('순공 중')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                waiting ? Icons.flip_rounded : Icons.pause_circle_outline,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Text(
                formatClock(_session.focused),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (_session.interruptions > 0)
                Text('중단 ${_session.interruptions}회', style: theme.textTheme.bodySmall),
              if (!_sensorAvailable) ...[
                const SizedBox(height: 16),
                Text(
                  '이 기기에서 가속도 센서를 찾을 수 없어요.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const Spacer(),
              if (!kReleaseMode)
                OutlinedButton.icon(
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('테스트: 뒤집기 시뮬레이션'),
                  onPressed: () => _simulate(true),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.tonal(
                  onPressed: _ending ? null : _confirmEnd,
                  child: _ending
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('순공 끝내기', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simulate(bool faceDown) {
    _detector.force(faceDown);
    _applyFlip(faceDown);
  }
}
