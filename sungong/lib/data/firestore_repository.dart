import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../logic/day_key.dart';
import 'study_repository.dart';

/// 서버 저장 중 문제가 생겼을 때 화면에 보여 줄 메시지를 담은 예외
class SyncException implements Exception {
  SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Firebase(Firestore)에 기록과 포인트를 저장하는 저장소.
///
/// 데이터 구조
///   users/{uid}                 balance, activeSessionId, createdAt
///   users/{uid}/sessions/{sid}  status, startedAt, endedAt, focusedSec, points, bonusPoints, ...
///   users/{uid}/days/{dayId}    basePoints (하루 한도 계산용), lastSessionId
///
/// 쓰기는 firebase/firestore.rules가 검사합니다. 여기서 쓰는 방식을 바꾸면 규칙과
/// 규칙 테스트(firebase/tests)도 함께 바꿔야 합니다.
class FirestoreStudyRepository extends StudyRepository {
  FirestoreStudyRepository(
    super.policy, {
    required this.user,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const _timeout = Duration(seconds: 15);
  static const _recentLimit = 50;

  final User user;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;

  List<StudyRecord> _records = const [];
  int _balance = 0;
  bool _ready = false;

  bool get ready => _ready;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection('users').doc(user.uid);
  CollectionReference<Map<String, dynamic>> get _sessions =>
      _userRef.collection('sessions');

  @override
  List<StudyRecord> get records => _records;

  @override
  int get balance => _balance;

  @override
  String? get accountLabel => user.email ?? '로그인됨';

  /// 사용자 문서를 만들고(처음 한 번) 실시간 구독을 시작합니다.
  Future<void> init() async {
    final snap = await _userRef.get(const GetOptions(source: Source.server)).timeout(_timeout);
    if (!snap.exists) {
      await _userRef.set({
        'balance': 0,
        'activeSessionId': null,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
    }
    _userSub = _userRef.snapshots().listen((s) {
      _balance = (s.data()?['balance'] as int?) ?? 0;
      notifyListeners();
    });
    _sessionsSub = _sessions
        .orderBy('startedAt', descending: true)
        .limit(_recentLimit)
        .snapshots()
        .listen((q) {
      _records = [
        for (final d in q.docs)
          if (d.data()['status'] == 'done' && d.data()['startedAt'] is Timestamp)
            _fromDoc(d),
      ];
      _ready = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _sessionsSub?.cancel();
    super.dispose();
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<SessionTicket> begin() async {
    final ref = _sessions.doc();
    final batch = _db.batch()
      ..set(ref, {'status': 'active', 'startedAt': FieldValue.serverTimestamp()})
      ..update(_userRef, {'activeSessionId': ref.id});
    try {
      await batch.commit().timeout(_timeout);
      final snap = await ref.get(const GetOptions(source: Source.server)).timeout(_timeout);
      final startedAt = (snap.data()!['startedAt'] as Timestamp).toDate();
      return SessionTicket(id: ref.id, startedAt: startedAt);
    } on TimeoutException {
      throw SyncException('서버에 연결하지 못했어요. 인터넷 연결을 확인해 주세요.');
    } on FirebaseException catch (e) {
      throw SyncException('순공을 시작하지 못했어요. (${e.code})');
    }
  }

  @override
  Future<StudyRecord> finish(
    SessionTicket ticket, {
    required Duration focused,
    required int interruptions,
  }) async {
    final sessionRef = _sessions.doc(ticket.id);
    final dayId = kstDayId(ticket.startedAt);
    final dayRef = _userRef.collection('days').doc(dayId);
    try {
      final points = await _db.runTransaction((tx) async {
        final day = await tx.get(dayRef);
        final prev = (day.data()?['basePoints'] as int?) ?? 0;
        final points = policy.pointsFor(focused, alreadyEarnedToday: prev);
        tx.update(sessionRef, {
          'status': 'done',
          'endedAt': FieldValue.serverTimestamp(),
          'focusedSec': focused.inSeconds,
          'interruptions': interruptions,
          'points': points,
          'bonusPoints': 0,
          'dayId': dayId,
        });
        tx.set(dayRef, {'basePoints': prev + points, 'lastSessionId': ticket.id});
        tx.update(_userRef, {
          'balance': FieldValue.increment(points),
          'activeSessionId': null,
        });
        return points;
      }, timeout: _timeout);
      return StudyRecord(
        id: ticket.id,
        startedAt: ticket.startedAt,
        focused: focused,
        points: points,
        interruptions: interruptions,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw SyncException(
          '서버가 이 기록을 받아들이지 않았어요. 다른 기기에서 순공을 새로 시작했다면 이 세션은 저장할 수 없어요.',
        );
      }
      throw SyncException('저장하지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요. (${e.code})');
    } on TimeoutException {
      throw SyncException('저장하지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요.');
    }
  }

  @override
  Future<void> claimBonus(StudyRecord record) async {
    if (record.bonusPoints > 0 || record.points <= 0) return;
    final batch = _db.batch()
      ..update(_sessions.doc(record.id), {'bonusPoints': record.points})
      ..update(_userRef, {
        'balance': FieldValue.increment(record.points),
        'lastBonusSessionId': record.id,
      });
    try {
      await batch.commit().timeout(_timeout);
      record.bonusPoints = record.points;
      notifyListeners();
    } on TimeoutException {
      throw SyncException('보너스를 저장하지 못했어요. 인터넷 연결을 확인해 주세요.');
    } on FirebaseException catch (e) {
      throw SyncException('보너스를 저장하지 못했어요. (${e.code})');
    }
  }

  static StudyRecord _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return StudyRecord(
      id: d.id,
      startedAt: (m['startedAt'] as Timestamp).toDate(),
      focused: Duration(seconds: (m['focusedSec'] as int?) ?? 0),
      points: (m['points'] as int?) ?? 0,
      bonusPoints: (m['bonusPoints'] as int?) ?? 0,
      interruptions: (m['interruptions'] as int?) ?? 0,
    );
  }
}
