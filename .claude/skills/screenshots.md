# /screenshots - App Storeスクリーンショット自動撮影

UIテストを使用してApp Store用スクリーンショットを自動撮影する。

## 実行方法

```bash
# 全言語（英語・日本語）
./scripts/take_screenshots.sh

# 英語のみ
./scripts/take_screenshots.sh en

# 日本語のみ
./scripts/take_screenshots.sh ja

# デバイス指定
./scripts/take_screenshots.sh en "iPhone 14 Pro Max"
```

## 仕組み

1. `ScreenshotTests.swift` UIテストを実行
2. アプリ起動 → Settings → Screenshot Mode → 言語選択
3. 各画面でスクリーンショット撮影:
   - Speed画面
   - Map画面
   - Settings画面
   - Paywall画面（価格表示なし）
4. `fastlane/screenshots/{lang}/` に保存

## 対応デバイス

- 6.7インチ: iPhone 14 Pro Max
- 6.5インチ: iPhone 14 Plus
- 5.5インチ: iPhone 8 Plus

## 出力先

```
fastlane/screenshots/
├── en/
│   ├── 01_speed_en.png
│   ├── 02_map_en.png
│   ├── 03_settings_en.png
│   └── 04_paywall_en.png
└── ja/
    ├── 01_speed_ja.png
    ├── 02_map_ja.png
    ├── 03_settings_ja.png
    └── 04_paywall_ja.png
```

## 注意事項

- DEBUGビルドでのみ動作（Screenshot Modeは#if DEBUGで囲まれている）
- Paywall画面は価格を表示しない（Guideline 2.3.7対応）
- MockPaywallViewを使用

## 手動で撮影する場合

1. Xcodeでアプリ起動
2. 設定アイコンをタップ
3. 下にスクロール → "Screenshot Mode" をタップ
4. 言語を選択（English / 日本語）
5. Simulator で Cmd+S でスクショ保存
