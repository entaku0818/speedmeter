# LP Deploy Skill

ランディングページ（Firebase Hosting）のデプロイ手順

## 使用方法

```
/lp-deploy
```

## ディレクトリ構成

```
/Users/entaku/repository/speedmeter/lp/
├── index.html          # トップページ
├── privacy.html        # プライバシーポリシー
├── terms.html          # 利用規約
├── support.html        # サポートページ
├── style.css           # スタイルシート
├── app-ads.txt         # AdMob app-ads.txt
├── firebase.json       # Firebase設定
└── localized/          # 多言語対応
```

## デプロイコマンド

```bash
cd /Users/entaku/repository/speedmeter/lp
firebase deploy --only hosting
```

## 確認URL

- トップページ: https://speedmeter-f9de0.web.app/
- プライバシーポリシー: https://speedmeter-f9de0.web.app/privacy.html
- 利用規約: https://speedmeter-f9de0.web.app/terms.html
- サポート: https://speedmeter-f9de0.web.app/support.html
- app-ads.txt: https://speedmeter-f9de0.web.app/app-ads.txt

## app-ads.txt

AdMob広告の認証用ファイル。内容:

```
google.com, pub-3484697221349891, DIRECT, f08c47fec0942fa0
```

## Firebase プロジェクト

- プロジェクトID: speedmeter-f9de0
- コンソール: https://console.firebase.google.com/project/speedmeter-f9de0/overview
