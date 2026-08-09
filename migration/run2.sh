#!/bin/bash
# Supabase → Firebase 移行(鍵ファイル不要版・macOS用)
# 組織ポリシーでサービスアカウント鍵が作れない場合はこちらを使う。
# 事前条件: run.sh のステップ1が完了していて ~/Desktop/migration/export.json がある
# 使い方:
#   curl -fsSL https://raw.githubusercontent.com/madono-lgtm/kinnikukomatsu/claude/firebase-kinnikukomatu-setup-1fjwxw/migration/run2.sh -o /tmp/run2.sh && bash /tmp/run2.sh
set -e

DIR="$HOME/Desktop/migration"
RAW="https://raw.githubusercontent.com/madono-lgtm/kinnikukomatsu/claude/firebase-kinnikukomatu-setup-1fjwxw/migration"
mkdir -p "$DIR"
cd "$DIR"

if [ ! -s export.json ]; then
  echo "export.json がありません。先に run.sh のステップ1(Supabaseのデータコピー)を行ってください。"
  exit 1
fi

echo "================================================================"
echo " ステップ1/3: Google Cloud CLI を準備します(初回は数分かかります)"
echo "================================================================"
if [ ! -x "$DIR/google-cloud-sdk/bin/gcloud" ]; then
  ARCH=$(uname -m)
  if [ "$ARCH" = "arm64" ]; then PKG=darwin-arm; else PKG=darwin-x86_64; fi
  echo "ダウンロード中..."
  curl -# -O "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${PKG}.tar.gz"
  tar xzf "google-cloud-cli-${PKG}.tar.gz"
  rm -f "google-cloud-cli-${PKG}.tar.gz"
fi
GCLOUD="$DIR/google-cloud-sdk/bin/gcloud"

# Macに入っているPythonが古くても動くよう、gcloud同梱のPythonを使う
BUNDLED_PY="$DIR/google-cloud-sdk/platform/bundledpythonunix/bin/python3"
if [ ! -x "$BUNDLED_PY" ]; then
  echo "同梱Pythonをセットアップ中(数分かかります)..."
  "$DIR/google-cloud-sdk/install.sh" --quiet --usage-reporting false \
    --path-update false --command-completion false --install-python true
fi
if [ -x "$BUNDLED_PY" ]; then
  export CLOUDSDK_PYTHON="$BUNDLED_PY"
fi
if ! "$GCLOUD" --version >/dev/null 2>&1; then
  echo "gcloud の準備に失敗しました。以下のエラーを報告してください:"
  "$GCLOUD" --version || true
  exit 1
fi
echo "→ OK"

echo ""
echo "================================================================"
echo " ステップ2/3: Googleアカウントでログインします"
echo "================================================================"
echo "今からブラウザが開きます。madono@kyoei-sakai.com でログインし、"
echo "「許可」を押してください。"
echo ""
"$GCLOUD" auth application-default login
"$GCLOUD" auth application-default set-quota-project kinnikukomatu
echo "→ OK"

echo ""
echo "================================================================"
echo " ステップ3/3: 移行を実行します"
echo "================================================================"
curl -fsSO "$RAW/migrate.mjs"
npm install --silent firebase-admin
node migrate.mjs

echo ""
echo "================================================================"
echo "上の件数を確認してください。このあとサイトで旧パスワードのまま"
echo "ログインできることを確認したら、次のコマンドで後片付け:"
echo "  rm ~/Desktop/migration/export.json"
echo "  $GCLOUD auth application-default revoke"
echo "================================================================"
