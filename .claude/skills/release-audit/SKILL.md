---
name: release-audit
description: Use when preparing to stage, push, or release Room, after a batch of feedback-driven changes, or when the user asks for a release audit（リリース前監査・最終監査・Fable 監査）. Also use before tagging a version or opening the repo to the public.
---

# Room リリース前監査

## Overview

リリース（ステージング / push / 公開）前に、コードベース全体を **特定のみ・修正なし** で監査する。
成果物は重要度付きの指摘一覧。修正は PM が別タスクとしてディスパッチする。

## 実行方法

- **Fable 相当の最上位モデルの subagent（fork 推奨）**で実行する。fork でない場合は先に必読: `docs/requirements.md`（機能仕様の正）、`docs/design-system.md`（UI 意匠の正）、`AGENTS.md`、直近の `docs/verification-v0.1.md`。
- 対象: `Room/` と `RoomTests/` の全 Swift ファイル + `project.yml` + `docs/` + ルートの md。
- このセッションで既に決着済みの指摘（要件・設計文書に **[v1.x 決定/修正]** として記録済みの繰り延べ事項）は再指摘しない。

## 監査項目（A–I すべて必須。該当なしのセクションは「なし」と明記）

| # | 項目 | 見るもの |
|---|---|---|
| A | 実装漏れ | requirements + design-system の全節・全決定（D1〜）と実装の突合。サイレントな乖離を含む |
| B | ドキュメント整合 | requirements ↔ design-system ↔ README ↔ CONTRIBUTING ↔ extensions.md ↔ 実コードのドリフト。存在しない機能の記載・古い UI 記述 |
| C | 安全ゲート退行 | 不変条件の再検証: 削除は Review 経由の単一 `cleanup.delete` 呼び出しのみ / delete はルールを ID 再導出（item を信用しない）/ symlink 実体パス封じ込め / inode 再検証 / 実行中アプリ再判定 / Quit・Force Quit のポリシー再判定と確認ダイアログ / テストで実ユーザーデータ不使用 |
| D | 冗長・死にコード | 未参照のシンボル・ファイル（grep で実証）、重複ロジック、到達不能分岐、重複テスト |
| E | 過剰実装（YAGNI） | スコープ外機能の混入、不要な抽象化、使われない設定 |
| F | リファクタ候補 | Core/Services/UI の責務境界、状態管理の座り、拡張様式（extensions.md）との整合 |
| G | テスト健全性 | 全テスト green、弱められた assertion がないか、変更された純ロジックのカバー漏れ |
| H | リリース衛生 | バージョン値、検証記録が現 HEAD を指すか、クリーンツリー、CI 定義、TODO/プレースホルダ残存、仮値（Bundle ID 等）の明示 |
| I | a11y 退行 | ラベル・combine・色以外の状態表現が UI 変更を生き残っているか |

## 出力形式

1. 指摘一覧（重要度順・番号付き）: `[分類 / High|Medium|Low]` + file:line + 何が・なぜ（具体的な失敗シナリオ or 利益）+ 修正方向 1–2 文
   - High = リリース前に修正すべき / Medium = 推奨 / Low = 次版でよい
2. セクション別サマリ（A–I それぞれ、なしなら「なし」）
3. 総評 1 段落（リリース可否の所見。人間確認事項・未決 H 項目は別枠として列挙）

## ルール

- **特定のみ。いかなるファイルも変更・コミットしない。**
- 指摘は grep / 読解で実証してから書く（推測の指摘には「未確認」と明記）。
- 過去の監査・レビューで決着済みの事項の蒸し返しは D〜F でも禁止（決着の記録は docs 内の [v1.x] マーカー）。
