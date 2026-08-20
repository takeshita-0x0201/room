# Room v0.1 検証結果

- **日付:** 2026-08-20
- **検証者:** 自動検証パス（Task 22 / スクリプト実行・ログ取得。UI 目視・実削除は含まない）
- **Commit 範囲:** `162da41..7eb0999`（v0.1 実装一式。HEAD = `7eb0999` `fix: set v0.1.0 bundle version and voiceover display-mode wording`。本 HEAD は v0.1.0 bundle version / VoiceOver 表示文言の修正を包含する）
- **環境:** macOS (Apple Silicon) / Xcode 26.6 (Build 17F113) / XcodeGen 2.46.0

## 自動検証結果

| 項目 | 結果 | 詳細 / ターゲット（要件 §22） | 判定 |
|------|------|-------------------------------|------|
| テストスイート | 50 tests, 0 failures（0 unexpected） | `xcodegen generate` + `xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' test` → **TEST SUCCEEDED** | ✅ PASS |
| Idle CPU | 全 3 サンプル 0.0% / 平均 0.0% | 起動後 10s 放置 → 20 秒間 10s 毎に `ps -o %cpu=`（省略版再検証。ターゲット: 平均 < 1.0%） | ✅ PASS |
| RSS | 平均 68.0 MB（66.0–71.8 MB） | 3 サンプル: 73520 / 67728 / 67568 KB（省略版再検証。ターゲット: < 100 MB / 数十 MB 級） | ✅ PASS |
| ネットワーク | 接続・通信 0 | `lsof -a -p <pid> -i` → ソケット 0 件（エントリなし） | ✅ PASS |
| Universal Binary | `x86_64 arm64` | `ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY=-` ビルド後 `lipo -info` → `Architectures in the fat file: ... are: x86_64 arm64` | ✅ PASS |
| 起動 / 終了 | クリーン | `open` で起動・常駐、`pkill -x Room` で終了。残存プロセスなし | ✅ PASS |

### Idle CPU / RSS サンプル生データ

| # | 時刻 | CPU % | RSS (KB) |
|---|------|-------|----------|
| 1 | 16:30 台 | 0.0 | 73520 |
| 2 | +10s | 0.0 | 67728 |
| 3 | +20s | 0.0 | 67568 |
| 平均 | — | **0.0** | **69605.3 KB = 68.0 MB** |

## 受け入れ条件チェックリスト（要件 §23）

凡例: 自動検証済み ＝ 本検証パスまたはユニットテストが直接検証 / 人間確認待ち ＝ 目視・実操作による確認 / 対象外 ＝ v0.1 では適用なし

| # | 受け入れ項目 | 状態 | 根拠 |
|----|--------------|------|------|
| 1 | メニューバー常駐・Dock アイコン非表示 | 人間確認待ち | 起動・常駐は自動検証済み（プロセス生存・メニューバー型 App）だが Dock 非表示の目視は人手。 |
| 2 | Room アイコン（独自）/ Memory・Storage アイコン（SF Symbols） | 人間確認待ち | 見た目（Light / Dark 含む）は目視確認。 |
| 3a | メニューバー表示フォーマット（Percentage / Free / Used の文字列生成） | 自動検証済み | `MenuBarTextTests`（percentage/free/used/nil）・`ByteTextTests` がカバー。 |
| 3b | 表示モード切替のメニューバー即時反映 | 人間確認待ち | 実操作での即時反映を目視確認。 |
| 4 | RAM 使用率・使用量・空き・総容量・Memory Pressure・Swap の算出 | 自動検証済み | `MemoryMathTests`（used 式・クランプ順序・Pressure マッピング）・`ModelsTests`（スナップショット算出・下回り防止・ラベル）。 |
| 5a | SSD 使用率・使用量・空き・総容量の算出（実ボリューム取得） | 自動検証済み | `StorageServiceTests.testRootVolumeSnapshot` が実ボリュームからスナップショット取得。 |
| 5b | SSD 値と Finder の一致（目視対比） | 人間確認待ち | スナップショットとの目視突き合わせは人手。 |
| 6a | Top Processes 3 件のアプリ単位集約・RAM 降順 | 自動検証済み | `ProcessAggregatorTests`（Outermost App Bundle 集約・降順ソート）。 |
| 6b | Top Processes 3 件の画面表示 | 人間確認待ち | 表示は目視確認。 |
| 7a | Processes 一覧の集約・降順・保護ルール | 自動検証済み | `ProcessAggregatorTests`・`ProcessProtectionPolicyTests`（Pid0/1、他ユーザー、自己、denylist、CoreServices 以外拒否）。 |
| 7b | Quit / Force Quit の実操作（捨てアプリで） | 人間確認待ち | 実操作は人手（本検証パスでは UI 操作禁止）。 |
| 8a | Memory Make Room の Pressure 判定（Normal / Warning / Critical マッピング） | 自動検証済み | `MemoryMathTests.testPressureLevelMapping`。 |
| 8b | Memory Make Room の UI フロー（`No action needed` 表示・選択 Quit・Potential recovery） | 人間確認待ち | フロー操作は目視確認。 |
| 9a | Storage の安全削除候補検出（カテゴリ別スキャン・排他・サイズ集計） | 自動検証済み | `CleanupRulesTests`・`CleanupPlannerTests`（Apple Caches 除外・reverse-DNS 制限・排他・経過期間・集計）。 |
| 9b | Storage の削除安全性（fixture での scan/delete、削除時再検証・symlink 拒否・実行中アプリ保護） | 自動検証済み | `CleanupServiceTests`・`CleanupFileOpsTests`（古いファイルのみ削除・root 維持・verifier 再検証・symlink 拒否・実行中ブロック）。 |
| 9c | Storage Make Room の実削除（捨てデータ `~/Library/Caches/com.example.room-test-fixture/`） | 人間確認待ち | 実データ削除は人手（本検証パスでは実データ非干渉のため）。fixture ディレクトリはジェネリックキャッシュスキャンに載るよう reverse-DNS 名を付けること。 |
| 10 | Settings（Launch at Login トグル / Show / Display モード・プレビュー / Refresh Interval）の実動作 | 人間確認待ち | Launch at Login トグル実動作ほかは目視・実操作確認。 |
| 11 | Light / Dark Mode・VoiceOver 一巡・キーボードナビゲーション | 人間確認待ち | 見た目と読み上げ・キーボード操作は目視確認。 |
| — | Memory Make Room 完成条件（Normal 時 `No action needed` / Warning・Critical 時 特定表示・選択 Quit） | 人間確認待ち | 表示・操作フローは目視確認（Pressure 判定ロジックのみ自動検証済み）。 |
| — | Storage Make Room 完成条件（検出 → Review → 選択削除） | 自動検証済み（検出・安全ロジック）/ 人間確認待ち（Review→削除の実操作） | 候補検出はフィクスチャで自動検証済み。Review 後の実削除は捨てデータで人手確認。 |

## 既知の制約・繰り延べ

- fd ベースの原子的削除は v0.1 スコープ外（同一ユーザー悪意プロセスは脅威モデル外、要件 §18.5 既知の制約）
- サービス層の異常系注入テスト（Codex ゲート #1 P3）は v0.2 バックログ
- CleanupService の実環境 scan/delete はフィクスチャテストのみ（実データ試験は人間確認項目）
- CI は GitHub 公開後に初回実行（H4）

## 人間確認事項（H1〜H5）の現状

| ID | 内容 | 状態 |
|----|------|------|
| H1 | Apple Developer Program / Developer ID 署名の有無・方針 | **未決**（要ユーザー判断） |
| H2 | Bundle ID 確定（仮: `dev.takeshita.Room`） | **未決**（要ユーザー判断） |
| H3 | ライセンス最終承認（MIT 提案） | **未決**（要ユーザー判断） |
| H4 | GitHub リポジトリ公開・初回 Release | **未決**（要ユーザー判断） |
| H5 | Xcode 16+ 導入・`xcode-select -s` | **解消済み** — Xcode 26.6（Build 17F113）/ Developer path = `/Applications/Xcode.app/Contents/Developer` を確認（本検証パスで `xcodebuild`・`xcodegen` 動作） |

> 追記: 本レコードは HEAD `77186dd` 時点の自動検証結果（ebc9555 で記録）を、HEAD `7eb0999`（v0.1.0 bundle version / VoiceOver 文言修正後）で再実行して更新したもの。