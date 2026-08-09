// Supabase → Firebase 移行スクリプト
// 使い方: migration/README.md を参照
//   必要ファイル(このスクリプトと同じフォルダに置く):
//     export.json        … Supabase からエクスポートしたデータ
//     serviceAccount.json … Firebase のサービスアカウント秘密鍵
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const data = JSON.parse(readFileSync(join(here, 'export.json'), 'utf8'));

// serviceAccount.json があればそれを使い、無ければ
// gcloud auth application-default login のログイン情報(ADC)を使う
const saPath = join(here, 'serviceAccount.json');
if (existsSync(saPath)) {
  initializeApp({ credential: cert(JSON.parse(readFileSync(saPath, 'utf8'))) });
} else {
  initializeApp({ credential: applicationDefault(), projectId: 'kinnikukomatu' });
}
const auth = getAuth();
const db = getFirestore();

// created_at を新サイトの保存形式(toISOString)に揃える
function normalizeCreatedAt(row) {
  if (row.created_at) {
    const d = new Date(row.created_at);
    if (!isNaN(d)) row.created_at = d.toISOString();
  }
  return row;
}

// ---------- 1. Firebase Auth へユーザーをインポート(UID・パスワード維持) ----------
async function importAuthUsers() {
  const users = (data.auth_users || [])
    .filter((u) => u.email)
    .map((u) => ({
      uid: u.id,
      email: u.email,
      emailVerified: true,
      ...(u.hash ? { passwordHash: Buffer.from(u.hash) } : {}),
    }));
  let ok = 0;
  for (let i = 0; i < users.length; i += 1000) {
    const chunk = users.slice(i, i + 1000);
    const res = await auth.importUsers(chunk, { hash: { algorithm: 'BCRYPT' } });
    ok += res.successCount;
    for (const e of res.errors) {
      console.error(`  ✗ Auth取込失敗: ${chunk[e.index].email} — ${e.error.message}`);
    }
  }
  console.log(`Auth: ${ok}/${users.length} 人をインポートしました`);
}

// ---------- 2. Firestore へデータをインポート(ドキュメントID維持) ----------
// [コレクション名, ドキュメントIDの決め方]
const PLANS = [
  ['profiles', (r) => String(r.id)],
  ['settings', (r) => String(r.id)],
  ['groups', (r) => String(r.id)],
  ['group_members', (r) => String(r.id)],
  ['reservations', (r) => String(r.id)],
  ['reservation_participants', (r) => String(r.id)],
  ['ticket_history', (r) => String(r.id)],
  ['intake_sheets', (r) => String(r.user_id)], // ドキュメントID = 会員のUID
];

async function importFirestore() {
  for (const [table, docId] of PLANS) {
    const rows = data[table] || [];
    let batch = db.batch();
    let n = 0;
    for (const raw of rows) {
      const row = normalizeCreatedAt({ ...raw });
      const id = docId(row);
      if (table !== 'intake_sheets') delete row.id; // IDはドキュメントID側に持たせる
      batch.set(db.collection(table).doc(id), row);
      n++;
      if (n % 400 === 0) { await batch.commit(); batch = db.batch(); }
    }
    if (n % 400 !== 0 || n === 0) await batch.commit();
    console.log(`Firestore: ${table} — ${n} 件`);
  }
}

// ---------- 3. 取込結果の確認 ----------
async function verify() {
  console.log('\n--- 確認 ---');
  const listed = await auth.listUsers(1000);
  console.log(`Firebase Auth ユーザー数: ${listed.users.length}`);
  for (const [table] of PLANS) {
    const snap = await db.collection(table).count().get();
    console.log(`${table}: ${snap.data().count} 件`);
  }
  const admins = await db.collection('profiles').where('role', '==', 'admin').get();
  console.log(`管理者(role=admin): ${admins.docs.map((d) => d.data().name).join(', ') || 'なし ← 要確認!'}`);
}

await importAuthUsers();
await importFirestore();
await verify();
console.log('\n移行が完了しました。旧パスワードのままログインできるか、サイトで確認してください。');
