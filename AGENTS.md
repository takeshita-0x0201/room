# Room — Agent 向けガイド

このドキュメントは、Room の開発に関わるすべてのエージェント（Claude / Codex 等、ツール非依存）が
最初に読むべき共通ルールを定義する。

## 1. プロジェクト概要

**Room — See what's full. Make room.**

Room は、macOS のメニューバー常駐で **RAM / SSD の状態を一目で確認**し、必要なときだけ
**安全にクリーンアップ（Make Room）**できる軽量な OSS アプリである。

Room は RAM クリーナーではない。「RAM をたくさん使っている」と「RAM が本当に不足している」を
区別し、Memory Pressure を主要指標とする。

設計原則:

1. **Glanceable** — メニューバーを見るだけで RAM / SSD の状態を把握できる
2. **Simple** — 情報量・操作・設定・画面遷移を必要最小限にする
3. **Make Room** — Memory は「Pressure 診断 → 不要な高メモリプロセスの終了」、
   Storage は「再生成可能データの検出 → ユーザー確認の上で削除」
4. **Extensible** — 本体は小さく保ち、RAM / SSD 以外は将来の Module / Extension とする

## 2. 必読ドキュメント

実装に着手する前に、必ず以下を読むこと。

- `docs/requirements.md` — 要件定義書 v1.1。指標定義（§6）、権限モデル（§5）、
  プロセス保護ルール（§15）、クリーンアップ仕様（§17〜18）などを含む。
- `docs/superpowers/plans/2026-08-20-room-mvp.md` — 実装計画。タスク分解と担当モデルの割り当てを含む。

**仕様判断に迷った場合は `docs/requirements.md` を正とする。**

## 3. ビルド・テスト

前提:

- Xcode 16 以上
- `brew install xcodegen`

`.xcodeproj` は XcodeGen による生成物であり、**コミットしない**（`project.yml` が正）。

```bash
xcodegen generate
xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' build
xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' test
```

## 4. リポジトリ構成

| パス | 内容 |
|------|------|
| `project.yml` | XcodeGen 定義。プロジェクト構成の正。 |
| `Room/App` | エントリポイント（`RoomApp` / `MenuBarExtra`）・`AppState`。 |
| `Room/Core` | 純粋ロジック: フォーマッタ・集約・保護ポリシー・クリーンアップルール。Foundation のみに依存し、ユニットテスト必須。 |
| `Room/Models` | `MemorySnapshot` / `StorageSnapshot` / `ProcessGroup` / `CleanupItem` などのデータモデル。 |
| `Room/Services` | システム API 隔離層（mach, sysctl, libproc, FileManager）。protocol + 実装で分離する。 |
| `Room/UI` | `Components`（再利用ビュー）/ `Screens`（Popover・Processes・MakeRoom・Cleanup・Settings）/ `Icons`。 |
| `Room/Support` | Bridging Header（libproc 等）、定数。 |
| `RoomTests/` | ユニットテスト。 |

## 5. コーディング規約

- Swift 5.9+ / SwiftUI を優先する（AppKit は必要箇所のみ）。
- ランタイム外部依存はゼロ。SwiftPM 依存の追加を禁止する。
- View にシステム取得処理を直接書かない。必ず `Room/Services` 経由でアクセスする。
- `Room/Core` は TDD（テスト先行）で実装する。
- UI 文字列は英語で統一する。
- 数値表示は等幅数字（monospaced digits）を使う。
- RAM の表示は 1024 基数、ストレージの表示は 1000 基数とする（`docs/requirements.md` §6 参照）。

## 6. 絶対的な禁止事項

- ネットワーク通信コードの追加（Analytics / Telemetry / 自動アップデートを含む）は一切禁止。
- ユーザー確認なしのファイル削除ロジックは禁止（Review フロー必須）。
- プロセス保護ルール（`docs/requirements.md` §15）の緩和禁止。
- App Sandbox の有効化禁止（プロセス列挙が壊れる）。
- テストで実ユーザーデータ（`~/Library` 等）に書き込み・削除する行為は禁止。
  必ずテンポラリのフィクスチャディレクトリを使うこと。

## 7. Git 規約

- Conventional Commits（`feat:` / `fix:` / `test:` / `docs:` / `chore:`）に従う。
- タスク単位の小さいコミットにする。
- コミットメッセージ末尾に以下のトレーラを付ける。

  ```
  Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
  ```

- 初期開発中は main へ直接コミットする。
- push はユーザーの指示があるまで行わない。

## 8. Definition of Done

タスクは以下をすべて満たした場合にのみ完了とする。

- 該当タスクのテストが green（`xcodebuild test` が通過する）。
- ビルド警告を増やさない。
- プレースホルダ（TODO・仮実装）を残さない。
- `docs/requirements.md` の該当受け入れ条件を満たす。
