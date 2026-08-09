# Claude Code 設定(skills / agents)

[craftsamo/dotconfig](https://github.com/craftsamo/dotconfig) の OpenCode 向け
スキル・サブエージェントを Claude Code 形式に翻訳して取り込んだもの。
原著: CraftSamo (MIT License)。

## 取り込んだもの

### skills/ (`.claude/skills/*/SKILL.md`)

| スキル | 元 | 主な変更 |
|---|---|---|
| git-commit | opencode/skills/git/commit | カスタムツール(`git_history_digest`/`git_stage_hunks`/`git_secret_scan`/`git_commit_lint`)を素の git / gitleaks / commitlint コマンドに置換 |
| git-pullrequest | opencode/skills/git/pullrequest | `gh` CLI が無い環境(リモート実行)向けに GitHub MCP ツールへの読み替え注記を追加 |
| web-ui | opencode/skills/web-ui | `agent-browser` CLI を Playwright(同梱 Chromium)スクリプトに置換 |
| ux-persona-testing | opencode/skills/ux-persona-testing | `task` ツール表記を Agent(Task)ツールに変更 |
| approach-new-feature / -refactor / -performance / -rebuild-migration | opencode/skills/approach/* | 実行主体の表記(OpenCode の Build モード)を Claude Code の main/サブエージェントに変更。計画の永続化先を GitHub Projects 専用スキルから汎用の Issue トラッカーに変更 |

### agents/ (`.claude/agents/*.md`)

OpenCode の frontmatter(`mode`/`model`/`permission`)を Claude Code の
`name`/`description`/`tools`/`model` に変換。モデルは
fast 系 → sonnet、高推論系 → opus、最安系 → haiku で対応付け。
読み取り専用エージェントは tools を Read/Grep/Glob/Bash 等に絞って表現。

- reviewer / reviewer-deep — 広く浅いレビュー→高リスク箇所の深掘りの2段構え
- verifier — テスト・lint・ビルド等の検証実行と失敗ログ要約
- debugger — 読み取り専用の根本原因調査(因果チェーン報告、修正はしない)
- worker — 仕様が確定した機械的変更の実装
- searcher — 出典URL付きの高速Web調査(X検索セクションは削除)
- ui-review — Playwright でスクリーンショットを撮る視覚UIレビュー
- ux-persona — ペルソナになりきる UX シミュレーション

## 見送ったもの(理由)

- `manage-github-projects` / `approach-github-projects` — OpenCode のカスタム
  TypeScript ツール(`github_project_*`)前提のため。GitHub Projects 運用を
  したくなったら MCP ベースで作り直すのが良い。
- `explore-*` 系エージェント — Claude Code 組み込みの Explore エージェントと重複。
- `explain` / `review` / `debug`(primary モード)— Claude Code にはモード概念が
  ないため。必要な内容はサブエージェント版でカバー。
- `searcher-deep` / `deepsearch` — searcher で十分な範囲から開始。必要なら追加。
- `agents/curated/japanese-writing` ほか curated スキル — 大型のため今回は未導入。
  日本語文書を書く機会が多ければ導入候補。
