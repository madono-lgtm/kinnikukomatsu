# Supabase → Firebase データ移行手順

旧サイト(Supabase)の会員・予約・チケットなどのデータを、
新サイト(Firebase)へ **UIDとパスワードを維持したまま** 移行します。
会員は今までのメールアドレス・パスワードのまま新サイトにログインできます。

所要 15〜20 分。ターミナル操作が1回だけあります。

## 事前準備

- Supabase のプロジェクトが Restore(復元)済みで「健康」状態になっていること
- **新サイトでテスト登録したアカウントがあれば先に消す**:
  Firebase コンソール → Authentication → ユーザー → 削除。
  あわせて Firestore → データ → `profiles` の該当ドキュメントも削除。
  (同じメールアドレスが残っていると取り込みが重複・失敗するため)
- Mac に Node.js が入っていること。未インストールなら https://nodejs.org/ja から
  LTS 版を入れる(ターミナルで `node -v` と打って番号が出ればOK)

## 手順1: Supabase からデータを出す

1. https://supabase.com/dashboard → プロジェクト「キン肉小松」→ SQL Editor
2. このフォルダの `export.sql` の中身を貼り付けて Run
3. 結果は1行1列の JSON。セルをクリックして中身を **全部コピー** し、
   このフォルダに `export.json` という名前で保存する
   (VS Code などで新規ファイル → 貼り付け → `migration/export.json` として保存)

## 手順2: Firebase のサービスアカウント鍵を取る

1. https://console.firebase.google.com → プロジェクト kinnikukomatu
2. 左上の歯車 →「プロジェクトの設定」→「サービス アカウント」タブ
3. 「新しい秘密鍵の生成」→ ダウンロードされた JSON ファイルを
   このフォルダに `serviceAccount.json` という名前で保存する

> この鍵はプロジェクトの全権限を持つ秘密ファイルです。
> **Git にコミットしない・移行が終わったら削除する** こと。

## 手順3: 移行スクリプトを実行する

ターミナルを開いて:

```bash
cd <このリポジトリの場所>/migration
npm install firebase-admin
node migrate.mjs
```

実行すると Auth ユーザー数・各コレクションの件数・管理者名が表示されます。
`管理者(role=admin): なし` と出た場合だけ、Firestore の `profiles` で
トレーナーのドキュメントの `role` を `admin` に手で直してください。

## 手順4: 動作確認と後片付け

1. https://madono-lgtm.github.io/kinnikukomatsu/ を開き、
   **旧サイトで使っていたメール・パスワードのまま** ログインできるか確認
2. チケット残数・予約・会員一覧が旧サイトと一致しているか確認
3. 確認できたら `serviceAccount.json` と `export.json` を削除
   (export.json には会員の個人情報とパスワードハッシュが入っています)
4. Supabase 側はしばらく残しておき、新サイトで数週間問題がなければ
   プロジェクトを削除してOK

## 補足

- スクリプトは Admin SDK で書き込むため、Firestore のセキュリティルールは
  変更不要です(公開済みのルールのままでOK)
- 同じデータで `node migrate.mjs` を再実行しても上書きされるだけなので、
  途中で失敗した場合はそのままもう一度実行して大丈夫です
  (Auth 側は既存ユーザーがエラー表示になりますが無視してOK)
