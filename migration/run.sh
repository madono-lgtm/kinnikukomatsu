#!/bin/bash
# Supabase → Firebase 移行の対話式スクリプト(macOS用)
# 使い方: ターミナルで
#   curl -fsSL https://raw.githubusercontent.com/madono-lgtm/kinnikukomatsu/claude/firebase-kinnikukomatu-setup-1fjwxw/migration/run.sh -o /tmp/run.sh && bash /tmp/run.sh
set -e

DIR="$HOME/Desktop/migration"
RAW="https://raw.githubusercontent.com/madono-lgtm/kinnikukomatsu/claude/firebase-kinnikukomatu-setup-1fjwxw/migration"
mkdir -p "$DIR"
cd "$DIR"

if ! command -v node >/dev/null; then
  echo "Node.js が見つかりません。https://nodejs.org/ja からLTS版を入れてから再実行してください。"
  exit 1
fi

curl -fsSO "$RAW/migrate.mjs"

echo ""
echo "================================================================"
echo " ステップ1/3: Supabase のデータをクリップボード経由で受け取ります"
echo "================================================================"
echo "1. Chrome で Supabase の SQL エディタのタブに切り替える"
echo "   (結果が消えていたら export.sql をもう一度 Run してください)"
echo "2. 実行結果の export_json セルをクリックして、中身を全文コピー(⌘C)"
echo "3. このターミナルに戻って Enter を押す"
echo ""
while true; do
  printf "コピーできたら Enter → "
  read -r _
  pbpaste > export.json
  if node -e 'const d=JSON.parse(require("fs").readFileSync("export.json","utf8")); if(!d.auth_users) process.exit(1);' 2>/dev/null; then
    echo "→ OK! export.json を保存しました。"
    break
  else
    echo "→ コピーされた内容がデータとして不完全です。"
    echo "   セルをクリックすると全文表示やコピー用のボタンが出るので、"
    echo "   そこから全文をコピーし直して、もう一度 Enter を押してください。"
  fi
done

echo ""
echo "================================================================"
echo " ステップ2/3: Firebase の秘密鍵を受け取ります"
echo "================================================================"
echo "今からブラウザで Firebase の設定ページを開きます。"
echo "「新しい秘密鍵の生成」→「キーを生成」を押してください。"
echo "ダウンロードされたら自動で検知します(このまま待っていてOK)。"
echo ""
MARKER="$DIR/.marker"
touch "$MARKER"
open "https://console.firebase.google.com/project/kinnikukomatu/settings/serviceaccounts/adminsdk"
while true; do
  KEY=$(find "$HOME/Downloads" -maxdepth 1 -name 'kinnikukomatu*.json' -newer "$MARKER" 2>/dev/null | head -1)
  [ -n "$KEY" ] && break
  sleep 2
done
mv "$KEY" serviceAccount.json
rm -f "$MARKER"
echo "→ OK! 秘密鍵を serviceAccount.json として配置しました。"

echo ""
echo "================================================================"
echo " ステップ3/3: 移行を実行します"
echo "================================================================"
npm install --silent firebase-admin
node migrate.mjs

echo ""
echo "================================================================"
echo "上の件数を確認してください。このあとサイトで旧パスワードのまま"
echo "ログインできることを確認したら、次のコマンドで秘密情報を削除:"
echo "  rm ~/Desktop/migration/serviceAccount.json ~/Desktop/migration/export.json"
echo "================================================================"
