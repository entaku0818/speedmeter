# Speedmeter v1.2.0 QA レポート

作成日: 2026-03-25
対象: iOS Swift / SwiftUI / RevenueCat ベースの Speedmeter アプリ
ベースバージョン: v1.1.2 (commit `4400d65`)
テスト対象バージョン: v1.2.0（実装完了後に検証）

---

## 事前コード精読による現状確認

v1.2.0 新機能は **全て未実装**（v1.1.2 コードベース時点）。
実装後のテスト実施に備え、テスト仕様と既存コードの潜在バグを先行して記録する。

---

## ⚠️ 既存コードの潜在問題（実装前精読で検出）

### P-01: `PurchaseManager.swift` — タイポ（typo）

**場所**: `PurchaseManager.swift:158`

```swift
let wasPremiun = self.isPremium  // ← "wasPremiun" (typo: "Premium" → "Premiun")
```

`wasPremiun` → `wasPremium` が正しい。現時点では動作に影響しないが、コードレビューで要修正。

---

### P-02: `LocationHistoryStore.swift` — save 失敗時にユーザー通知なし（E-03 相当）

**場所**: `LocationHistoryStore.swift:46-52`

```swift
private func save() {
    do {
        let data = try JSONEncoder().encode(records)
        UserDefaults.standard.set(data, forKey: saveKey)
    } catch {
        print("Failed to save location history: \(error)")  // ← ユーザーへの通知なし
    }
}
```

JSONEncoder 失敗時（メモリ不足・データ破損）に `print` のみ。ユーザーは保存失敗を知る手段がない。
QuestBoard の E-03 と同等の問題。

**エンジニアへの確認事項**: エラー時に `@Published var saveError: Error?` などで UI 通知する設計が必要か？

---

### P-03: `LocationRecord.swift` — 2つ目の init で speedKmh の計算式が不一致

**場所**: `LocationRecord.swift:38`

```swift
// 1つ目のinit（CLLocationから）
self.speedKmh = max(0, location.speed * 3.6)  // ← max(0) で負数ガード

// 2つ目のinit（手動指定）
self.speedKmh = speed * 3.6                   // ← 負数ガードなし
```

2つ目の `init` で `speed` に負値を渡すと `speedKmh` が負値になる。
GPX/CSV エクスポートや統計計算で意図しない負値が混入する可能性がある。

---

## 📋 v1.2.0 機能テスト仕様

> **検証ステータス凡例**: 🔲 未テスト / ✅ 合格 / ❌ 不合格 / ⚠️ 要確認

---

### ① mph / km 切り替え

#### 実装要件の事前確認（精読による想定）

現在の問題点:
- `SpeedView.swift:44` → `locationManager.speedKmh` 固定
- `SpeedView.swift:48` → `Text("km/h")` ハードコード
- `LocationManager.swift` → `speedKmh` プロパティのみ公開（mph 換算なし）

実装時に期待される変更:
- ユニット設定（mph/km）を UserDefaults に永続化
- `speedMph = speedKmh / 1.609344` の換算
- SpeedView の表示数値とラベルのトグル切り替え

#### テストチェックリスト

**表示精度**
- 🔲 km/h モード: GPS 速度が km/h で表示される
- 🔲 mph モード: GPS 速度が mph で正確に表示される（換算式: `km/h ÷ 1.609344`）
- 🔲 60 km/h のシミュレーション速度が mph モードで `37.3 mph` 前後に表示される
- 🔲 0 km/h のとき mph モードでも `0 mph` が表示される（負値・NaN なし）

**切り替え動作**
- 🔲 設定画面でユニットを km → mph に切り替えると SpeedView の表示が即時更新される
- 🔲 mph → km に切り替えても即時更新される
- 🔲 追跡中（GPS Active 状態）に切り替えても表示が正しく更新される

**永続化**
- 🔲 mph を選択後にアプリを完全終了→再起動しても mph のまま
- 🔲 km を選択後に再起動しても km のまま
- 🔲 初回起動時のデフォルトは km/h

**エッジケース**
- 🔲 極高速（999 km/h 相当）を入力した場合、表示桁あふれが起きない
- 🔲 設定変更中に GPS 速度が更新されても競合しない

---

### ② 速度統計（平均・最高速）

#### 実装要件の事前確認（精読による想定）

`LocationHistoryStore.swift` の `records: [LocationRecord]` が素材。
各 `LocationRecord` に `speedKmh: Double` がある。
P-03 の負値混入に注意（最高速計算に影響する可能性）。

期待される実装:
```swift
var averageSpeed: Double {
    guard !records.isEmpty else { return 0 }
    return records.map(\.speedKmh).reduce(0, +) / Double(records.count)
}
var maxSpeed: Double {
    records.map(\.speedKmh).max() ?? 0
}
```

#### テストチェックリスト

**計算正確性**
- 🔲 履歴 1 件: 平均 = 最高速 = その1件の速度
- 🔲 履歴 3 件（10/20/30 km/h）: 平均 = 20.0, 最高速 = 30.0
- 🔲 全件が 0 km/h のとき: 平均 = 0, 最高速 = 0（クラッシュなし）
- 🔲 小数点の端数が正しく計算される（例: 1/3 → 約 0.33...）

**履歴 0 件エッジケース**
- 🔲 履歴が空のとき統計画面を開いてもクラッシュしない
- 🔲 0件時の表示が `--` `N/A` など空状態を示す（0.0 km/h と誤解させない）
- 🔲 履歴を「Clear All」した直後に統計が正しく 0 件状態に更新される

**ユニット連動（① と連携）**
- 🔲 mph モードに切り替えると統計表示も mph 換算される
- 🔲 km/h に戻すと統計も km/h 表示に戻る

**永続化**
- 🔲 統計値がアプリ再起動後も保持される（履歴データから再計算される）

---

### ③ 無料トライアル（Paywall UI）

#### 実装要件の事前確認（精読による想定）

現在の `PaywallView.swift` には:
- 月額・年額の2プランカードのみ
- トライアル期間の表示なし
- `PurchaseManager.fetchAllPlans()` が RevenueCat の offering からプラン情報を取得

RevenueCat 側でトライアル設定済みであれば `storeProduct.introductoryPrice` が取れるはず。

#### テストチェックリスト

**UI 表示確認（実機 / Sandbox テスト環境）**
- 🔲 Paywall を開いたときにトライアル期間（例: "7日間無料"）が表示される
- 🔲 トライアル期間がプランカードまたはヘッダーに明示されている
- 🔲 トライアル終了後の課金額が明記されている
- 🔲 「Upgrade to Pro」ボタン押下でトライアル開始の確認ダイアログが表示される

**App Store ガイドライン準拠**
- 🔲 自動更新サブスクリプションの注意書きが Paywall 下部に表示されている（現在 `PaywallView.swift:156-158` に記載済み → 確認）
- 🔲 「Subscription will be charged to your iTunes account.」文言あり ✅（コード確認済み）
- 🔲 「Auto-renews unless canceled...」文言あり ✅（コード確認済み）
- 🔲 Privacy Policy / Terms of Use リンクが機能する ✅（URL ハードコード確認済み: `speedmeter-f9de0.web.app`）

**トライアル中の状態**
- 🔲 トライアル開始後は `isPremium = true` になり Pro 機能が使える
- 🔲 トライアル期間中は広告が非表示になる
- 🔲 トライアル終了後に `checkPremiumStatus()` が false を返したとき設定がリセットされる（`resetSettingsToFree()` の動作確認）

**エラーハンドリング**
- 🔲 オフライン時に Paywall を開いても、`isLoading` のまま固まらない（タイムアウト処理あるか要確認）
- 🔲 プラン取得失敗（`productNotFound`）時にエラー表示ではなく適切なフォールバック UI がある
- 🔲 購入キャンセル時に `isPurchasing = false` に戻り、ボタンが再度タップ可能になる

---

### ④ GPX / CSV エクスポート

#### 実装要件の事前確認（精読による想定）

`LocationRecord.swift` のフィールド:
- `timestamp`, `latitude`, `longitude`, `speed`(m/s), `speedKmh`, `altitude`, `horizontalAccuracy`

**GPX 形式** (`.gpx`):
```xml
<trkpt lat="35.0" lon="135.0">
  <ele>100.0</ele>
  <time>2026-03-25T10:00:00Z</time>
  <extensions><speed>16.67</speed></extensions>
</trkpt>
```

**CSV 形式**:
```
timestamp,latitude,longitude,speed_ms,speed_kmh,altitude,accuracy
2026-03-25T10:00:00Z,35.0,135.0,16.67,60.0,100.0,5.0
```

#### テストチェックリスト

**ファイル形式の正確性**
- 🔲 GPX: XML として parse 可能（整形式）
- 🔲 GPX: `<gpx>`, `<trk>`, `<trkseg>`, `<trkpt>` の階層構造が正しい
- 🔲 GPX: `lat`/`lon` 属性が小数4桁以上の精度で出力される
- 🔲 GPX: `<time>` が ISO 8601 UTC フォーマット（`Z` サフィックス）で出力される
- 🔲 CSV: 1行目がヘッダー行
- 🔲 CSV: カンマ区切り・文字コード UTF-8
- 🔲 CSV: timestamp が ISO 8601 フォーマット
- 🔲 CSV: speed_kmh が正の値（P-03 の負値混入なし）

**空データ時の動作**
- 🔲 履歴 0 件で GPX エクスポートしても空の有効 GPX が出力される（クラッシュなし）
- 🔲 履歴 0 件で CSV エクスポートするとヘッダー行のみの CSV が出力される
- 🔲 0 件エクスポート後のファイルサイズが 0 bytes にならない（最低限のスケルトンあり）

**大量データ**
- 🔲 1000 件のレコードを GPX エクスポートしてもクラッシュ・タイムアウトしない
- 🔲 エクスポート中に UI がフリーズしない（非同期処理であること）

**ファイル共有**
- 🔲 iOS の共有シートが開く（`UIActivityViewController` または `ShareLink`）
- 🔲 Files アプリへの保存・AirDrop・メール添付が動作する
- 🔲 ファイル名に日時が含まれる（例: `speedmeter_20260325_100000.gpx`）

**ユニット連動（① と連携）**
- 🔲 GPX の `<speed>` 拡張はメートル毎秒（m/s）が標準仕様 → km/h モードでも `speed` フィールドは m/s で出力されるか確認
- 🔲 CSV は km/h と m/s 両方を出力する（または選択可能）

---

### ⑤ E-03 相当: データ保存エラーハンドリング（前回スプリント持ち越し）

> QuestBoard E-03 の speedmeter 版確認。

| 場所 | 保存処理 | try/catch | ユーザー通知 | 判定 |
|---|---|---|---|---|
| `LocationHistoryStore.swift:46-52` | `JSONEncoder().encode` | ✅ あり | ❌ `print` のみ | ⚠️ |
| `UserDefaults.standard.set(data, ...)` | 直接書き込み | ❌ なし | ❌ なし | ⚠️ |
| `PurchaseManager.swift:115` | `UserDefaults.set(true, ...)` | ❌ なし | ❌ なし | ⚠️ |
| `PremiumSettings.swift:50` | `UserDefaults.set(rawValue, ...)` | ❌ なし | ❌ なし | ⚠️ |
| `FontSettings.swift:59` | `UserDefaults.set(rawValue, ...)` | ❌ なし | ❌ なし | ⚠️ |

**テストチェックリスト**
- 🔲 ディスク容量を意図的に埋めた状態で履歴追加→エラーが画面に表示される（またはログに記録される）
- 🔲 `UserDefaults` 保存失敗時（シミュレーターで UserDefaults を無効化）に isPremium が正しく復元できるか
- 🔲 起動時の `load()` が失敗した場合に空配列を返し、クラッシュしない ✅（コード確認済み: catch 節で return）

---

## 🔍 実装完了前にエンジニアに確認すべき事項

| # | 確認内容 | 理由 |
|---|---|---|
| C-01 | mph/km 設定は `UserDefaults` or `PremiumSettings` どちらに持つか | テスト方法が変わる |
| C-02 | 速度統計は全履歴を対象とするか、セッション単位か | エッジケース定義が変わる |
| C-03 | 無料トライアル期間は RevenueCat 側で設定済みか（introductoryPrice が取れるか） | Paywall UI テストの前提 |
| C-04 | エクスポートは Pro 限定機能か無料でも使えるか | Paywall テストのスコープが変わる |
| C-05 | GPX の speed 拡張タグは `<speed>` (m/s) か `<speedKmh>` か（どの仕様に準拠するか） | フォーマット検証の基準 |
| C-06 | P-03 の 2つ目の `LocationRecord.init` で負値速度になりうるシナリオはあるか | 統計・エクスポートのデータ品質に影響 |

---

## 優先対応順（実装完了後テスト順）

| 優先度 | 機能 | 理由 |
|---|---|---|
| 🔴 最優先 | ① mph/km 切り替え（表示精度・換算） | 計算ミスは直接ユーザー体験に影響 |
| 🔴 最優先 | ② 速度統計（0件エッジケース） | クラッシュリスク |
| 🟠 高 | ④ GPX/CSV エクスポート（形式・空データ） | データ破損・クラッシュリスク |
| 🟠 高 | ③ 無料トライアル（App Store ガイドライン） | リジェクトリスク |
| 🟡 中 | ⑤ E-03 相当（保存エラー通知） | サイレント障害 |
| 🟢 低 | P-01 タイポ修正 | 動作影響なし |

---

## リリース判定（実装完了後に更新）

| 判定 | 状態 |
|---|---|
| ⏳ **判定保留** | v1.2.0 機能が全て未実装。エンジニアの実装完了後に再テストし、判定を更新する |
