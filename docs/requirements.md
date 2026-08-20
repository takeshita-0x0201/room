# Room 要件定義書 v1.1

> **Room — See what's full. Make room.**
> macOS のメニューバー上で RAM と SSD の状態を一目で確認し、必要なときだけ安全に空きを作れる軽量 OSS アプリ。

本書は v1.0 Final を実装可能なレベルまで精査・具体化した改訂版である。
v1.0 からの変更点はすべて **[v1.1 決定]** マーカーで明示する。設計思想・UI 方針は v1.0 を踏襲する。

---

## 0. 精査サマリー（v1.0 → v1.1 の変更理由）

v1.0 は思想・UI とも明確だが、実装に進むには以下のカテゴリの未定義事項があった。

| # | 問題 | v1.1 での対応 |
|---|------|--------------|
| 1 | App Sandbox の扱いが未定義。プロセス列挙・他アプリ終了・キャッシュ削除は Sandbox 下では不可能 | **非 Sandbox** と決定。Mac App Store 配布不可 → GitHub Releases 配布（§4） |
| 2 | TCC（macOS プライバシー保護）の権限モデルが未定義。`~/.Trash` は Full Disk Access 必須、Safari キャッシュは TCC 保護 | 権限モデルの章を新設（§5）。Trash は FDA 前提のオプトイン、Safari はスコープ外 |
| 3 | 最低対応 macOS バージョン未定義 | **macOS 14.0 (Sonoma) 以降**に決定（§4） |
| 4 | 「RAM 使用率」の算出式が未定義（macOS は空き RAM をキャッシュに積極利用するため free/total は不適切） | Activity Monitor 準拠の式を定義（§6.1） |
| 5 | SSD 空き容量の算出方法が未定義（APFS の purgeable 領域の扱い） | Finder 一致の `volumeAvailableCapacityForImportantUsage` に決定（§6.2） |
| 6 | プロセス表示の集計単位が未定義。Chrome 等は多数の Helper プロセスに分かれ、素朴に列挙すると仕様の意図（"Chrome 3.2 GB"）と乖離 | .app バンドル単位で集約するルールを定義（§6.3） |
| 7 | Quit の実装経路が GUI アプリと非 GUI プロセス（node 等）で異なる点が未定義 | 2 経路（`NSRunningApplication` / シグナル）を定義（§14） |
| 8 | Quit は「要求」であり保証されない（未保存ダイアログでブロックされ得る）ことへの UI が未定義 | タイムアウト後のフォロー UI を定義（§14.3） |
| 9 | 保護プロセスの判定基準が抽象的 | 判定ルールを具体化（§15） |
| 10 | クリーンアップの二重計上リスク（Yarn/Homebrew/CocoaPods 等のキャッシュは `~/Library/Caches` 配下にあり、Caches と Developer の両カテゴリに該当） | カテゴリ間の排他ルールを定義（§17.4） |
| 11 | 実行中ブラウザのキャッシュ削除はデータ破損リスク | 実行中アプリのキャッシュはスキップするルールを定義（§17.5） |
| 12 | Docker キャッシュ削除は docker CLI への外部依存＋デーモン起動状態依存 | **v0.2 へ繰り延べ**（§20） |
| 13 | Review カテゴリ（Downloads 巨大ファイル・重複検出）は §35 MVP リストに含まれておらず、重複検出は高コスト | **v0.2 へ繰り延べ**（§20） |
| 14 | 削除方式が未定義（ゴミ箱移動では空き容量が増えない） | Review 確認を必須とした上で**完全削除**に決定（§17.6） |
| 15 | 「古い Logs」の閾値が未定義 | 最終更新 7 日超に決定（§17.3） |

軽微な決定（§21 決定事項一覧に集約）: UI 言語は英語 / 等幅数字 / Show Memory・Storage 両 OFF 時はアイコンのみ / RAM は 1024 基数・SSD は 1000 基数表示 / 自動アップデート機構なし 等。

**結論: v1.0 の思想・UI・スコープは実装可能。上記の具体化を行った本書 v1.1 を実装のベースラインとする。**

---

## 1. プロダクト概要

**Room** は、macOS のメニューバー上で **RAM と SSD の状態を一目で確認し、必要なときだけ安全に空きを作れる** 軽量なオープンソースアプリケーション。

Room は高機能なシステムモニターや総合クリーナーを目指さない。ユーザーが知りたいことを最小限の UI で提示する。

- RAM は今どの程度使われているか / 本当に不足しているか
- SSD はどの程度使われているか / 空きはいくらか
- 何が RAM を圧迫しているか
- 安全にどれくらい空きを作れるか

## 2. 設計原則

1. **Glanceable** — メニューバーを見るだけで RAM / SSD の状態を把握できる
2. **Simple** — 情報量・操作・設定・画面遷移を必要最小限にする
3. **Make Room** — Memory は「Pressure 診断 → 不要な高メモリプロセスの終了」、Storage は「再生成可能データの検出 → ユーザー確認の上で削除」
4. **Extensible** — 本体は小さく保ち、RAM / SSD 以外は将来の Module / Extension とする

Room は RAM クリーナーではない。「RAM をたくさん使っている」と「RAM が足りていない」を区別し、Memory Pressure を主要指標とする。

## 3. プロダクト境界

```text
Room Core                     Extensions（将来）
├── Memory Monitor            ├── CPU / GPU / Battery
├── Storage Monitor           ├── Network / Docker
├── Process Monitor           ├── Temperature
└── Make Room                 └── Community Modules
    ├── Memory
    └── Storage
```

v0.1 では Plugin Runtime は作らない。内部構造（Service プロトコル分離）だけモジュール追加しやすくする。

## 4. 対象環境・配布 **[v1.1 決定]**

| 項目 | 決定 | 理由 |
|------|------|------|
| 最低 OS | **macOS 14.0 (Sonoma)** | SwiftUI `MenuBarExtra` の popover 開閉検知・`@Observable`・`openSettings` 環境値が 14+。Intel Mac も Sonoma 対応機種（2018 年以降の大半）をカバー |
| アーキテクチャ | Universal Binary (arm64 + x86_64) | Apple Silicon 優先、Intel も同一コードで対応可能 |
| 言語 / UI | Swift 5.9+ / SwiftUI（必要箇所のみ AppKit） | 仕様通り |
| App Sandbox | **無効** | プロセス列挙（libproc）・他アプリの終了・`~/Library/Caches` 削除は Sandbox 下で不可能 |
| 配布 | GitHub Releases（.zip / .dmg）。Mac App Store は**不可**（非 Sandbox のため） | OSS 方針と整合 |
| 署名 | Developer ID + Notarization を推奨。**署名 ID の有無・取得はユーザー（人間）確認事項** | 未署名でも OSS としてビルド可能（Gatekeeper 警告は README に記載） |
| Dock | アイコンなし（`LSUIElement = true`）、メニューバー常駐 | 仕様通り |
| ネットワーク | 通信ゼロ。Analytics / Telemetry / 自動アップデートなし。更新は GitHub Releases 手動 | Privacy 原則（§19） |

## 5. 権限モデル（TCC） **[v1.1 新設]**

Room が扱う領域と macOS の許可要件：

| 領域 | 権限 | Room の対応 |
|------|------|------------|
| RAM / SSD 統計、プロセス列挙（自ユーザー分） | 不要 | 常時利用 |
| 他アプリの Quit / Force Quit（自ユーザー所有） | 不要（非 Sandbox） | 常時利用 |
| `~/Library/Caches`, `~/Library/Logs`, `$TMPDIR`, `~/.npm` 等 | 不要 | 常時利用 |
| `~/.Trash`（サイズ取得・削除） | **Full Disk Access 必須** | FDA 未付与時は Trash 行を「サイズ不明」とし、システム設定への誘導リンクを表示。付与時のみサイズ表示・削除可能 |
| Safari のキャッシュ / データ | TCC 保護（FDA でも一部不可） | **スコープ外**（対象ブラウザは Chrome / Firefox 等の非 TCC 保護領域のみ） |
| Desktop / Documents / Downloads | フォルダ単位の同意プロンプト | v0.1 ではスキャン対象にしない（Review カテゴリは v0.2） |

原則: **Room は権限を先回りして要求しない**。FDA は Trash 機能を使おうとしたときにのみ案内する。

## 6. 指標定義 **[v1.1 新設]**

### 6.1 Memory

| 指標 | 定義 |
|------|------|
| RAM 総容量 | `ProcessInfo.processInfo.physicalMemory` |
| RAM 使用量 (used) | `(max(internal − purgeable, 0) + wired + compressor) × pageSize`（`host_statistics64(HOST_VM_INFO64)`。Activity Monitor の "Memory Used" 準拠。クランプは App Memory = internal − purgeable の段階で行い、wired / compressor を失わせない） |
| RAM 使用率 | `used / total` |
| RAM 空き | `total - used` |
| Memory Pressure | 初期値: sysctl `kern.memorystatus_vm_pressure_level`（1=Normal, 2=Warning, 4=Critical）。変化検知: `DispatchSource.makeMemoryPressureSource`（イベント駆動・ポーリング不要）。**取得失敗・未知値は Unavailable として Normal と区別する**（誤った "No action needed" を出さない） |
| Swap | sysctl `vm.swapusage`（`xsw_usage.xsu_used`） |
| 表示基数 | **1024 基数**（`ByteCountFormatter.CountStyle.memory`）。24 GB RAM が "24 GB" と表示されるため |

### 6.2 Storage

| 指標 | 定義 |
|------|------|
| 対象 | 起動ディスク（`/`）のみ。外付け・複数ボリュームは将来対応 |
| 総容量 | `volumeTotalCapacityKey` |
| 空き容量 | **`volumeAvailableCapacityForImportantUsageKey`**（APFS の purgeable を含む、Finder が使う値と同一。※Finder 側の表示はキャッシュにより一時的に数値がズレることがある） |
| 使用量 | `total - free` |
| 使用率 | `used / total` |
| 表示基数 | **1000 基数**（`ByteCountFormatter.CountStyle.file`。Finder と一致） |

### 6.3 プロセスの集計単位 **[v1.1 決定]**

- プロセスの実行パスに `.app` バンドルが含まれる場合、**同一バンドルのプロセス（Helper 含む）を 1 つのグループに集約**し、アプリ名で表示する（例: Chrome 本体 + 全 Helper = "Chrome 3.2 GB"）
- バンドルに属さないプロセス（`node`, `docker` 等）は単体で表示する
- RAM 使用量は `proc_pid_rusage` の `ri_phys_footprint`（Activity Monitor の "Memory" 列と同じ指標）のグループ合算値
- 列挙対象は**現在のユーザーが所有するプロセスのみ**（他ユーザー・root プロセスの footprint は取得不可であり、Quit 対象にもならないため）

## 7. UI 全体方針

- ダッシュボード化しない / カードを並べない / 円グラフ・不要なチャートを使わない
- 常時アニメーションなし / 色を多用しない / 深い階層を作らない（最大 2 階層）
- 設定を増やしすぎない / 普段は存在感を出さない
- UI 言語は**英語**（v0.1）。文字列一元管理レイヤは v0.1 では設けない（YAGNI。ローカライズ着手時に導入） **[v1.1 決定]**
- **UI 意匠（アイコンセット・カラー・コンポーネント様式・数値フォーマットの見せ方）の正は `docs/design-system.md`** とする（ユーザー提供デザインシートを構造化、2026-08-20）。使用率バー・Pressure 状態色（Normal=青）等の常時カラーはこれに従い、v1.1 の「通常状態は無彩色」原則を改訂する **[v1.2 決定]**

## 8. Room アイコン

「面のない立体空間」— 斜め上から立方体内部を見た形で、底面・奥左・奥右の 3 面のみをワイヤーフレームで表現する。前面・上面は存在しない。

要件: ワイヤーフレーム / 面を塗らない / 単色 / 幾何学的 / ベクターベース / macOS Template Image 対応（Light / Dark 自動対応）/ 16–18px でも判別可能 / 線幅は細すぎない。

**[v1.1 決定]** Memory / Storage アイコンは v0.1 では SF Symbols（`memorychip` / `internaldrive`）を使用。Room アイコンのみ独自制作。

## 9. メニューバー表示

デフォルト:

```text
[Memory Icon]72 [Storage Icon]68
```

Room アイコンはメニューバーに常時表示しない（v0.1 実機フィードバック）。**[v1.2 修正]**

- `RAM` `SSD` `%` `・` 等のテキストは表示しない。アイコン + 数値のみ
- 表示順は Memory → Storage 固定
- **[v1.1 決定]** 数値は等幅数字（monospaced digits）で描画し、更新時の幅の揺れを防ぐ
- **[v1.1 決定]** Show Memory / Show Storage が両方 OFF の場合は Room アイコンのみ表示する

### 表示モード（Settings で切替、メニューバーへ即時反映）

| モード | 表示例 | 内容 |
|--------|--------|------|
| Percentage（デフォルト） | `◇ ▦72 ▱68` | 使用率 |
| Free | `◇ ▦5.6G ▱171G` | 空き容量 |
| Used | `◇ ▦18.4G ▱341G` | 使用容量 |

容量の短縮表記: 100G 未満は小数 1 桁・`.0` は省略（`5.6G` `18.4G` `24G`）、100G 以上は整数（`171G` `341G`）＋単位 1 文字。v1.0 §8 の表示例（`▦18.4G ▱341G`）に準拠。**[v1.1 決定]**

## 10. メイン Popover

Room アイコンのクリックで表示。幅 280–320px、高さ可変、最大 2 階層。

```text
╭──────────────────────────────╮
│ ◇ Room                       │
│                              │
│ MEMORY                  72%  │
│ 18.4 / 24 GB                 │
│ Free      5.6 GB             │
│ Pressure  Normal             │
│ Swap      768 MB             │
│                              │
│ STORAGE                 68%  │
│ 341 / 512 GB                 │
│ Free      171 GB             │
│                              │
│ TOP PROCESSES                │
│ Chrome               3.2 GB  │
│ Cursor               2.4 GB  │
│ node                 1.1 GB  │
│                              │
│ ◇  Make Room                 │
│ ◎  Processes             ›   │
│ ⚙  Settings                  │
╰──────────────────────────────╯
```

- セクション見出し（MEMORY / STORAGE / TOP PROCESSES）はアイコン付き・太字強調とする（v0.1 実機フィードバック反映） **[v1.1 修正]**
- Make Room / Processes は Popover 内でのプッシュ遷移（1 階層）
- Settings は独立ウィンドウ（macOS 標準）
- Top Processes は RAM 使用量上位 3 グループ。表示はアプリ / プロセス名 + RAM 使用量のみ（CPU 等は出さない）

## 11. Memory Monitor

表示項目: RAM 使用率 / 使用量 / 総容量 / 空き容量 / Memory Pressure / Swap 使用量。

Room は **RAM 使用率だけで異常判定しない**。Memory Pressure（Normal / Warning / Critical）を主要指標とし、`RAM 90% / Pressure Normal` なら警告しない。

## 12. Storage Monitor

表示項目: SSD 使用率 / 使用容量 / 総容量 / 空き容量。算出は §6.2 に従い、ユーザーが実際に利用可能な容量（Finder 一致）を表示する。

## 13. Processes 画面

Popover の `Processes ›` から、RAM 使用量降順の一覧（§6.3 の集約単位）を表示。各行に Quit / Force Quit を提供する。

## 14. Quit / Force Quit **[v1.1 具体化]**

### 14.1 Quit（通常終了）

- .app グループ → `NSRunningApplication.terminate()`（macOS 標準の正常終了フロー。アプリ側の未保存確認ダイアログを尊重する）
- 非 GUI プロセス → `SIGTERM`
- 保存されていないユーザーデータを失わせる処理を優先しない

### 14.2 Force Quit（強制終了）

- .app グループ → `forceTerminate()`、非 GUI → `SIGKILL`
- 実行前に必ず確認ダイアログを挟む:

```text
Force Quit Chrome?
Unsaved changes may be lost.
[Cancel] [Force Quit]
```

### 14.3 Quit がブロックされた場合 **[v1.1 新設]**

`terminate()` は「終了要求」であり、アプリが未保存確認ダイアログ等で応答しない場合は終了しない。Quit 要求から約 5 秒後も生存している場合、該当行に `Still running` と `Force Quit` の選択肢を表示する。自動では Force Quit しない。

### 14.4 実行の安全確認 **[v1.1 新設]**

- QuitService はサービス層でも保護ポリシー（§15）を再判定する（UI の無効化だけに依存しない多層防御）
- PID 再利用対策として、操作直前に対象 PID の実行パス（.app グループは bundle パス）が記録時と一致することを確認する。一致しない・検証できない場合は何もしない
- 生存確認（Still running 判定）も同一性確認を通した上で行う

## 15. プロセス保護ルール **[v1.1 具体化]**

以下のいずれかに該当するグループは Quit / Force Quit 不可（UI 上も操作を無効化）:

1. Room 自身
2. PID 0 / 1（kernel_task / launchd）
3. 現在のユーザー以外が所有するプロセスを含むグループ
4. 拒否リスト該当: `WindowServer`, `loginwindow`, `Dock`, `SystemUIServer`, `ControlCenter`, `NotificationCenter`, `Spotlight`, `coreaudiod`, `mds`, `mds_stores`, `logd`, `launchservicesd`, `distnoted`, `cfprefsd`
5. 実行パスが `/System/Library/CoreServices` 配下（例外: Finder は Quit 可。終了しても macOS が自動再起動するため無害）

保護判定は純粋関数として実装し、ユニットテストで担保する。

## 16. Make Room（ハブ）

```text
MAKE ROOM

Memory
Pressure Normal
No action needed          ›

Storage
15.1 GB cleanable         ›
```

Memory と Storage は別ロジック。

## 17. Make Room — Memory

### 17.1 思想

RAM クリーナーにしない。以下を**目的としない**: 使用率の強制低下 / inactive cache の無条件 purge / free RAM の数値を増やすだけの処理 / 実態のない「解放しました」表示。

Room は **Memory Pressure Manager** として動作する:

1. Memory Pressure を診断
2. Swap 量を確認
3. 高メモリプロセスを表示
4. ユーザーが対象を選択
5. 通常 Quit を実行
6. 必要な場合のみ Force Quit

**Room が勝手にアプリを終了することはない。**

### 17.2 Pressure Normal 時

```text
MEMORY          72%
Pressure        Normal
No action needed
```

高使用率でも Pressure が Normal なら `No action needed` を表示し、選択リストは出さない（手動の Quit は Processes 画面から常時可能）。

Pressure が取得できない場合（Unavailable）は `No action needed` を**表示しない**。`Pressure unavailable` と表示し、判断を保留する。**[v1.1 追加決定]**

### 17.3 Pressure Warning / Critical 時

高メモリプロセス上位を表示し、チェックボックスで選択 → `Quit Selected` で通常 Quit を実行する。

```text
Select apps to quit
□ Chrome    6.2 GB
□ Docker    4.1 GB
□ Cursor    3.8 GB

Potential recovery   14.1 GB
[Cancel] [Quit Selected]
```

### 17.4 Potential Recovery

選択プロセスの現在の footprint 合算値を目安として表示する。**その容量が完全に free になることを保証する表示にはしない**（文言は "Potential recovery"）。

## 18. Make Room — Storage（Cleanup）

### 18.1 原則

**重要なデータを確認なしに削除しない。** 削除前に必ず Review を挟み、項目ごとに ON/OFF できる。

### 18.2 カテゴリと対象（v0.1） **[v1.1 具体化]**

| レベル | 項目 | パス | 条件 |
|--------|------|------|------|
| Safe | Application Cache | `~/Library/Caches/*` | `com.apple.*` を除外。実行中アプリのキャッシュを除外。Developer / Browser カテゴリが claim したパスを除外 |
| Safe | Browser Cache | Chrome: `~/Library/Caches/Google/Chrome`、Firefox: `~/Library/Caches/Firefox`（実体は `Profiles/<profile>/cache2` 配下） | 対象ブラウザ実行中はスキップ（§18.4）。Safari はスコープ外（TCC） |
| Safe | Temporary Files | `$TMPDIR`（自ユーザー） | 最終更新 3 日超のみ |
| Safe | Logs | `~/Library/Logs` | 最終更新 **7 日超**のみ |
| Safe | Trash | `~/.Trash` | **FDA 付与時のみ**（§5）。未付与時は行を「Grant Full Disk Access to include Trash」と表示 |
| Developer | Xcode DerivedData | `~/Library/Developer/Xcode/DerivedData` | |
| Developer | Simulator Cache | `~/Library/Developer/CoreSimulator/Caches` | |
| Developer | npm / pnpm / yarn Cache | `~/.npm/_cacache` / pnpm store（環境依存: `~/Library/pnpm/store`・`~/.local/share/pnpm/store`・`~/.pnpm-store` のうち存在するもの）/ `~/Library/Caches/Yarn` | 存在するもののみ表示 |
| Developer | Homebrew Cache | `~/Library/Caches/Homebrew` | |
| Developer | CocoaPods Cache | `~/Library/Caches/CocoaPods` | |
| Developer | Gradle Cache | `~/.gradle/caches` | |

### 18.3 カテゴリ排他ルール **[v1.1 新設]**

Yarn / Homebrew / CocoaPods 等のキャッシュは `~/Library/Caches` 配下にある。**個別ルールが claim したパスは Application Cache（汎用スキャン）から除外**し、二重計上・二重削除を防ぐ。この排他はユニットテストで担保する。

また、汎用スキャンの対象は **reverse-DNS 形式（ドットを 2 つ以上含む名前）のディレクトリのみ**とする。`Google` `JetBrains` のようなベンダー名ディレクトリは実行中アプリ（bundle ID）との突き合わせができず §18.4 の保護を適用できないため、明示ルールがあるもの以外は対象外とする。**[v1.1 追加決定]**

### 18.4 実行中アプリの保護 **[v1.1 新設]**

対象アプリ（ブラウザ・Xcode 等）が実行中の場合、そのキャッシュ項目は選択不可とし `Quit Chrome to clean` のように理由を表示する。実行中アプリのキャッシュ削除はデータ破損の原因になるため。

なお、この「ブロック表示」は明示ルール（Chrome / Firefox / Xcode 等）にのみ適用する。**汎用 Application Cache スキャン内の実行中アプリ分は、行として表示せずスキャン対象から除外する**（安全側。アプリ終了後の次回スキャンで対象になる）。per-app の行表示は v0.2 で検討。**[v1.1 追加決定]**

### 18.5 削除方式 **[v1.1 決定]**

Review で確認済みの項目は**完全削除**（`FileManager.removeItem`）。ゴミ箱への移動では SSD の実空き容量が増えず、Make Room の目的を果たさないため。対象はすべて再生成可能データに限定されており、Review 必須がセーフティネットとなる。ディレクトリ自体は残し、内容物のみ削除する。

**削除時の再検証（TOCTOU 対策）[v1.1 追加決定]**:

1. スキャン時に各対象の inode / device 番号を記録し、**削除直前に一致を再検証**する。不一致（差し替え・削除済み）はスキップする
2. シンボリックリンクは対象にしない（スキャン時に除外し、削除時にも再確認する）
3. 削除対象は必ず許可ルート（ルールの roots）配下であることを削除直前に再検証する
4. §18.4 の実行中アプリ判定は**削除直前にも再実行**する（スキャン後に対象アプリが起動された場合に備える）
5. 削除対象は symlink 解決後の実体パスでも許可ルート配下であることを検証する（中間 symlink による領域外脱出の防止） **[v1.1 追加決定]**

**既知の制約（v0.1）**: inode 再検証と実削除はパスベース操作であり、完全な原子性（fd ベースの `openat`/`unlinkat` 削除）は持たない。検証から削除までのミリ秒級の窓で同一ユーザーの悪意プロセスが差し替えを行うケースは防げないが、同一ユーザーの悪意コードは Room を介さず直接ファイルを削除できるため v0.1 の脅威モデル外とする（偶発的な変更・差し替えは inode 検証と実体パス検証でカバー）。fd ベース化は将来課題としてバックログに記録。

### 18.6 スキャンと UI

```text
STORAGE
341 / 512 GB
Free            171 GB

CLEANABLE
Caches           4.8 GB
Developer        8.2 GB
Logs           420 MB
Trash            1.7 GB
Total           15.1 GB

[Review]
```

※ v1.0 の `[Review] [Make Room]` 2 ボタンは両方 Review 画面へ遷移する重複だったため、**ブルーの `Review` 単一ボタン**に統合（design-system §8）。**[v1.2 修正]**

Review 画面（各項目 ON/OFF 可能）:

```text
✓ Application Cache   2.8 GB
✓ Browser Cache       2.0 GB
✓ Developer Cache     8.2 GB
✓ Logs               420 MB
✓ Trash               1.7 GB
Total                15.1 GB
[Cancel]  [Clean]
```

- スキャンは Make Room（Storage）を開いたときにのみ実行（バックグラウンド・キャンセル可能）
- CLEANABLE の Total には**今すぐ削除可能（ready）な項目のみ**を合算する。実行中アプリでブロック中の項目は「+X GB after quitting apps」、FDA 未付与の Trash は案内行として分離表示する（見かけの Total と実際に消せる量を一致させる） **[v1.1 追加決定]**
- 削除完了後は**実際に削除したファイルサイズ合計**を表示する（事実ベース。APFS の空き容量反映は遅延することがあるため、空き容量差分を成果として表示しない） **[v1.1 修正]**
- 削除エラー（使用中ファイル等）は項目単位でスキップし、結果に `Skipped (in use)` として表示する **[v1.1 新設]**

## 19. Settings

```text
GENERAL
  Launch at Login        ON        ← SMAppService.mainApp（macOS 13+ 標準 API）
MENU BAR
  Show Memory            ON
  Show Storage           ON
  Display                ● Percentage ○ Free ○ Used   ← 選択モードのプレビュー 1 行付き（実アイコン + 固定サンプル値。実測値は使わない） **[v1.1 修正]**
  Refresh Interval       ● 5 sec ○ 10 sec ○ 30 sec
```

- Display / Show 設定はメニューバーへ即時反映
- 設定は `UserDefaults`（`@AppStorage`）に保存

### Refresh Policy

- **軽量取得**（RAM 統計・SSD 容量）: Refresh Interval に従い定期更新
- **Memory Pressure**: イベント駆動（DispatchSource）でポーリングなし
- **プロセス一覧**: Popover を**開いたとき**と **Quit 操作後**に更新する。表示中の定期再更新は行わない（行の再構築が進行中のクリック操作を奪うため。v0.1 実機フィードバックによる UX 修正） **[v1.1 修正]**
- **Storage Cleanup Scan**: Make Room（Storage)を開いたときのみ
- Popover が閉じている間の処理はメニューバー表示に必要な軽量取得のみとする

## 20. スコープ外（v0.1） **[v1.1 明確化]**

| 項目 | 理由 | 予定 |
|------|------|------|
| Docker cache 削除 | docker CLI 外部依存・デーモン状態依存 | v0.2 |
| Review カテゴリ（Downloads 巨大ファイル / DMG / ZIP / 古いインストーラー / 重複検出） | v1.0 §35 MVP リスト外。重複検出は高コスト。Downloads は TCC 同意が必要 | v0.2（発見・提示のみの原則は維持） |
| Safari キャッシュ | TCC 保護によりアクセス不可 | 対応予定なし |
| 外付け SSD・複数ボリューム | 仕様通り将来対応 | v0.x |
| CPU / GPU / Battery / Network / Temperature | Extensions | 将来 |
| Plugin Runtime | 仕様通り不要 | 将来 |
| 自動アップデート | ネットワーク通信ゼロ原則 | 検討外（Homebrew cask 等で代替） |

## 21. 決定事項一覧（PM 決定） **[v1.1]**

| # | 決定 | 根拠 |
|---|------|------|
| D1 | 最低 OS: macOS 14.0 | §4 |
| D2 | 非 Sandbox / GitHub Releases 配布 | §4 |
| D3 | RAM used = Activity Monitor 準拠式 | §6.1 |
| D4 | SSD free = importantUsage キー（Finder 一致） | §6.2 |
| D5 | プロセスは .app バンドル単位で集約 | §6.3 |
| D6 | RAM 表示 1024 基数 / SSD 表示 1000 基数 | §6.1, §6.2 |
| D7 | Quit は 2 経路（NSRunningApplication / SIGTERM） | §14 |
| D8 | Quit ブロック時は 5 秒後に Force Quit 提案 | §14.3 |
| D9 | 保護ルール（denylist + 所有者 + /System/Library/CoreServices） | §15 |
| D10 | Trash は FDA オプトイン | §5, §18.2 |
| D11 | クリーンアップは完全削除（Review 必須） | §18.5 |
| D12 | 実行中アプリのキャッシュはスキップ | §18.4 |
| D13 | カテゴリ間パス排他 | §18.3 |
| D14 | Logs 7 日超 / Temp 3 日超 | §18.2 |
| D15 | Docker cache・Review カテゴリは v0.2 | §20 |
| D16 | UI 英語、等幅数字、SF Symbols（Memory/Storage） | §7–9 |
| D17 | ビルドは XcodeGen（`project.yml` を正、`.xcodeproj` は生成物） | 実装計画参照。diff レビュー可能性のため |
| D18 | ライセンス: MIT を提案 | OSS 標準。**最終承認は人間** |
| D19 | クリーンアップ削除直前の再検証（inode/device 一致・symlink 拒否・許可ルート配下・実行中アプリ再判定） | §18.5 |
| D20 | 汎用 Caches スキャンは reverse-DNS 名のディレクトリのみ | §18.3 |
| D21 | Memory Pressure 取得不可は Unavailable として Normal と区別 | §6.1, §17.2 |
| D22 | Cleanable Total は ready 項目のみ合算・削除実績は削除サイズ合計を表示 | §18.6 |
| D23 | Quit / Force Quit はサービス層でも保護判定＋プロセス同一性確認 | §14.4 |

### 人間（ユーザー）確認事項

| 項目 | 内容 |
|------|------|
| H1 | Apple Developer Program / Developer ID 署名の有無・方針 |
| H2 | Bundle ID の確定（仮: `dev.takeshita.Room`。`project.yml` で変更可能） |
| H3 | ライセンス最終承認（MIT 提案） |
| H4 | GitHub リポジトリ公開・初回 Release の実施判断 |
| H5 | 開発環境の準備: **Xcode 16 以上のインストール**と `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` の実行（現環境は Command Line Tools のみで `xcodebuild` 不可 — 実装開始のブロッカー） |

## 22. 非機能要件

### パフォーマンス

```text
Idle CPU   ≈ 0%（Popover 非表示時はタイマー 1 本 + イベント駆動のみ）
RAM        数十 MB 以内を目標
Network    0
```

### Privacy

Analytics / Telemetry / Usage Tracking / アカウント / 不要なネットワーク通信 / ユーザーデータ送信 — すべて禁止。完全ローカル動作。

### Accessibility

- 全 UI 要素に VoiceOver ラベル
- キーボードナビゲーション
- Light / Dark Mode 対応
- 十分なコントラスト
- 色以外の状態表現（Pressure はテキスト "Normal/Warning/Critical" を必ず併記。状態色は Normal=青 / Warning=黄 / Critical=赤。使用率バー等の常時カラーは `design-system.md` §3 に従う） **[v1.2 修正]**

### OSS 方針

小さなコードベース / 外部依存最小限（ランタイム依存ゼロ、開発ツールは XcodeGen のみ）/ Swift 標準 API 優先 / CONTRIBUTING.md / Extension 追加方法の文書化 / Telemetry なし。

README 冒頭:

```markdown
# Room

**See what's full. Make room.**

A tiny macOS menu bar app for memory and storage.
```

## 23. MVP v0.1 受け入れ条件

### 機能チェックリスト（v1.0 §35 準拠 + v1.1 調整）

- [ ] メニューバー常駐・Dock アイコン非表示
- [ ] Room アイコン（独自）/ Memory・Storage アイコン（SF Symbols)
- [ ] `◇ ▦72 ▱68` 相当の表示（Percentage / Free / Used、即時切替）
- [ ] RAM 使用率・使用量・空き・総容量・Memory Pressure・Swap
- [ ] SSD 使用率・使用量・空き・総容量（Finder 一致）
- [ ] Top Processes 3 件（アプリ単位集約）
- [ ] Processes 一覧（RAM 降順）+ Quit / Force Quit + 保護ルール
- [ ] Memory Make Room（Normal 時 `No action needed` / Warning・Critical 時 選択 Quit + Potential recovery）
- [ ] Storage Make Room（スキャン → Cleanable 表示 → Review → 選択削除 → 実測結果表示）
- [ ] Settings（Launch at Login / Show 切替 / Display モード + プレビュー / Refresh Interval）
- [ ] Light / Dark Mode、VoiceOver ラベル、キーボード操作

### Memory Make Room 完成条件（v1.0 §36）

- Normal 時: `Pressure Normal` + `No action needed` を表示できる
- Warning / Critical 時: 高メモリプロセスを特定表示し、選択 Quit できる。必要時のみ Force Quit 可能

### Storage Make Room 完成条件（v1.0 §37）

- 安全に削除可能な候補をカテゴリ別サイズ付きで検出できる
- 削除前に Review でき、選択した項目だけ削除できる

## 24. アーキテクチャ

```text
Room/
├── App/            RoomApp（MenuBarExtra）, AppState, RefreshScheduler
├── Models/         MemorySnapshot, StorageSnapshot, ProcessGroup, CleanupItem, 各種 enum
├── Services/       MemoryService, StorageService, ProcessService, QuitService, CleanupService
│                   （すべて protocol + 実装。システム API はここに隔離）
├── Core/           純粋ロジック: 集約・保護ポリシー・クリーンアップルール・フォーマッタ
├── UI/
│   ├── Components/ 再利用ビュー（SectionHeader, StatRow, …）
│   ├── Screens/    PopoverRoot, Processes, MakeRoom, Cleanup, Settings
│   └── Icons/      RoomIcon（テンプレート画像）
└── Support/        Bridging Header（libproc）, 定数
```

- **View 内へ直接システム取得処理を書かない**（Services 経由のみ）
- Core は Foundation のみに依存する純粋ロジックとし、ユニットテストの主対象とする
- Extension 追加は「Service protocol + Screen」の追加で完結する構造を保つ

---

## 25. 最終定義

Room は RAM クリーナーではない。総合システムモニターでもない。

> **Mac にあとどれくらい Room があるかを一目で知り、本当に必要なときだけ、安全に Room を作るための小さな道具**である。

- Memory: **Diagnose pressure. Quit what you don't need.**
- Storage: **Find what can safely go. Make room.**
- プロダクト全体: **Room — See what's full. Make room.**
