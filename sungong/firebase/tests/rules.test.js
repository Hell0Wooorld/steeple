import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, writeBatch, runTransaction,
  serverTimestamp, Timestamp, increment,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-sungong',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());

const db = (uid) => env.authenticatedContext(uid).firestore();

function kstDayId(date) {
  const k = new Date(date.getTime() + 9 * 3600 * 1000);
  return String(k.getUTCFullYear() * 10000 + (k.getUTCMonth() + 1) * 100 + k.getUTCDate());
}

async function createUser(d, uid) {
  await setDoc(doc(d, 'users', uid), {
    balance: 0, activeSessionId: null, createdAt: serverTimestamp(),
  });
}

async function start(d, uid, sid) {
  const b = writeBatch(d);
  b.set(doc(d, 'users', uid, 'sessions', sid), { status: 'active', startedAt: serverTimestamp() });
  b.update(doc(d, 'users', uid), { activeSessionId: sid });
  await b.commit();
}

/** 세션 시작 시각을 과거로 옮김 (오래 공부한 상황을 흉내) */
async function backdate(uid, sid, minutes) {
  const startedAt = Timestamp.fromMillis(Date.now() - minutes * 60_000);
  await env.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'users', uid, 'sessions', sid), { startedAt });
  });
  return startedAt;
}

/** 앱(lib/data/firestore_repository.dart)과 같은 방식으로 종료. override로 조작 시도 */
async function finish(d, uid, sid, focusedSec, override = {}) {
  return runTransaction(d, async (tx) => {
    const sRef = doc(d, 'users', uid, 'sessions', sid);
    const s = await tx.get(sRef);
    const dayId = override.dayId ?? kstDayId(s.data().startedAt.toDate());
    const dayRef = doc(d, 'users', uid, 'days', dayId);
    const day = await tx.get(dayRef);
    const prev = day.exists() ? day.data().basePoints : 0;
    const points = override.points ?? Math.min(Math.floor(focusedSec / 60), Math.max(0, 600 - prev));
    tx.update(sRef, {
      status: 'done', endedAt: serverTimestamp(), focusedSec, interruptions: 0,
      points, bonusPoints: 0, dayId,
    });
    tx.set(dayRef, { basePoints: prev + (override.dayPoints ?? points), lastSessionId: sid });
    tx.update(doc(d, 'users', uid), {
      balance: increment(override.balancePoints ?? points), activeSessionId: null,
    });
    return points;
  });
}

async function bonus(d, uid, sid, amount) {
  const b = writeBatch(d);
  b.update(doc(d, 'users', uid, 'sessions', sid), { bonusPoints: amount });
  b.update(doc(d, 'users', uid), { balance: increment(amount), lastBonusSessionId: sid });
  await b.commit();
}

async function balanceOf(uid) {
  let v;
  await env.withSecurityRulesDisabled(async (ctx) => {
    v = (await getDoc(doc(ctx.firestore(), 'users', uid))).data().balance;
  });
  return v;
}

test('정상 흐름: 시작 → 40분 경과 → 30분 순공 종료 → 30P', async () => {
  const d = db('alice');
  await assertSucceeds(createUser(d, 'alice'));
  await assertSucceeds(start(d, 'alice', 's1'));
  await backdate('alice', 's1', 40);
  await assertSucceeds(finish(d, 'alice', 's1', 30 * 60));
  assertEqual(await balanceOf('alice'), 30);
});

test('흐른 시간보다 긴 순공 시간은 거부', async () => {
  const d = db('alice');
  await createUser(d, 'alice');
  await start(d, 'alice', 's1');
  await backdate('alice', 's1', 10);
  await assertFails(finish(d, 'alice', 's1', 60 * 60));
});

test('포인트를 부풀리면 거부', async () => {
  const d = db('alice');
  await createUser(d, 'alice');
  await start(d, 'alice', 's1');
  await backdate('alice', 's1', 40);
  await assertFails(finish(d, 'alice', 's1', 30 * 60, { points: 300 }));
  await assertFails(finish(d, 'alice', 's1', 30 * 60, { balancePoints: 300 }));
  await assertFails(finish(d, 'alice', 's1', 30 * 60, { dayPoints: 0 }));
  await assertFails(finish(d, 'alice', 's1', 30 * 60, { dayId: '20000101' }));
});

test('잔액을 직접 고치거나 처음부터 포인트를 넣고 가입할 수 없음', async () => {
  const d = db('alice');
  await assertFails(setDoc(doc(d, 'users', 'alice'), {
    balance: 1000, activeSessionId: null, createdAt: serverTimestamp(),
  }));
  await createUser(d, 'alice');
  await assertFails(updateDoc(doc(d, 'users', 'alice'), { balance: 1000 }));
});

test('하루 한도(600P)를 넘지 않음', async () => {
  const d = db('alice');
  await createUser(d, 'alice');
  await start(d, 'alice', 's1');
  const startedAt = await backdate('alice', 's1', 40);
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users', 'alice', 'days', kstDayId(startedAt.toDate())),
      { basePoints: 590, lastSessionId: 'old' });
  });
  await assertFails(finish(d, 'alice', 's1', 30 * 60, { points: 30 }));
  await assertSucceeds(finish(d, 'alice', 's1', 30 * 60)); // 10P
  assertEqual(await balanceOf('alice'), 10);
});

test('광고 보너스는 세션당 한 번, 같은 양만', async () => {
  const d = db('alice');
  await createUser(d, 'alice');
  await start(d, 'alice', 's1');
  await backdate('alice', 's1', 40);
  await finish(d, 'alice', 's1', 30 * 60);
  await assertFails(bonus(d, 'alice', 's1', 100));
  await assertSucceeds(bonus(d, 'alice', 's1', 30));
  await assertFails(bonus(d, 'alice', 's1', 30));
  assertEqual(await balanceOf('alice'), 60);
});

test('새 세션을 시작하면 이전 세션은 종료할 수 없음 (동시 세션으로 부풀리기 방지)', async () => {
  const d = db('alice');
  await createUser(d, 'alice');
  await start(d, 'alice', 's1');
  await backdate('alice', 's1', 40);
  await start(d, 'alice', 's2');
  await assertFails(finish(d, 'alice', 's1', 30 * 60));
});

test('같은 세션을 두 번 종료할 수 없음', async () => {
  const d = db('alice');
  await createUser(d, 'alice');
  await start(d, 'alice', 's1');
  await backdate('alice', 's1', 40);
  await finish(d, 'alice', 's1', 30 * 60);
  await assertFails(finish(d, 'alice', 's1', 30 * 60));
});

test('다른 사람의 기록은 읽거나 쓸 수 없음', async () => {
  await createUser(db('alice'), 'alice');
  const bob = db('bob');
  await assertFails(getDoc(doc(bob, 'users', 'alice')));
  await assertFails(updateDoc(doc(bob, 'users', 'alice'), { activeSessionId: 'x' }));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users', 'alice')));
});

function assertEqual(a, b) {
  if (a !== b) throw new Error(`expected ${b}, got ${a}`);
}
